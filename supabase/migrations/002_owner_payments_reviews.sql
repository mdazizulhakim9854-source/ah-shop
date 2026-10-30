-- AH SHOP v2: run after 001, once. Existing data is preserved.
begin;
-- Single shop owner: stop rather than silently replacing existing multiple admins.
create unique index one_shop_owner on public.admin_roles ((true));
alter table public.products add column featured boolean not null default false;
alter table public.products add column sort_order integer not null default 100 check(sort_order between -1000000 and 1000000);
alter table public.orders add column customer_email text not null default '';
alter table public.orders add column postcode text not null default '';
alter table public.orders add column gateway_mode text check(gateway_mode in ('sandbox','live'));
alter table public.orders drop constraint orders_payment_method_check;
alter table public.orders add constraint orders_payment_method_check check(payment_method in ('COD','bKash','Nagad','ONLINE'));
alter table public.orders drop constraint orders_payment_status_check;
alter table public.orders add constraint orders_payment_status_check check(payment_status in ('Unpaid','Verification pending','Paid','Refunded','Sandbox verified'));
update public.site_settings set value='{"online_payment_enabled":false,"online_discount_percent":0,"theme_accent":"#7760ce","hero_title_bn":"","hero_title_en":"","hero_subtitle_bn":"","hero_subtitle_en":""}'::jsonb||value where id='public';
drop policy admin_payment_update on public.orders;
create policy admin_payment_update on public.orders for update to authenticated using(public.is_admin() and payment_method<>'ONLINE') with check(public.is_admin() and payment_method<>'ONLINE');
create or replace function public.create_order_secure(payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare k uuid;h text;old_order public.orders;cid uuid;oid uuid;item jsonb;p public.products;total_price numeric(12,2):=0;delivery numeric(12,2);discount_value numeric(12,2):=0;online_percent numeric(5,2):=0;cfg jsonb;phone text;qty integer;result jsonb;
begin
 if payload->>'consent' is distinct from 'true' then raise exception 'Explicit consent required';end if;
 k:=(payload->>'idempotency_key')::uuid;h:=encode(pg_catalog.sha256(convert_to(payload::text,'UTF8')),'hex');
 perform pg_advisory_xact_lock(hashtextextended(k::text,0));
 select * into old_order from public.orders where idempotency_key=k;
 if found then if old_order.request_hash<>h then raise exception 'Idempotency key reused with different data';end if;oid:=old_order.id;
 else
 phone:=regexp_replace(payload#>>'{customer,phone}','[^0-9]','','g');if phone like '8801%' then phone:=substring(phone from 3);end if;
 if phone is null or phone !~ '^01[3-9][0-9]{8}$' then raise exception 'Invalid Bangladesh phone';end if;
 if coalesce(length(trim(payload#>>'{customer,name}')),0) not between 2 and 100 or coalesce(length(trim(payload#>>'{customer,address}')),0) not between 8 and 500 or coalesce(length(trim(payload#>>'{customer,district}')),0) not between 1 and 80 or coalesce(length(trim(payload#>>'{customer,area}')),0) not between 1 and 120 or coalesce(length(payload->>'notes'),0)>1000 or coalesce(length(payload->>'transaction_id'),0)>80 then raise exception 'Invalid customer fields';end if;
 if jsonb_typeof(payload->'items') is distinct from 'array' or jsonb_array_length(payload->'items') not between 1 and 40 then raise exception 'Invalid cart';end if;
 if (select count(*) from jsonb_array_elements(payload->'items'))<>(select count(distinct x->>'product_id') from jsonb_array_elements(payload->'items') x) then raise exception 'Duplicate line items';end if;
 select value into cfg from public.site_settings where id='public';delivery:=(cfg->>'delivery_charge')::numeric;
 if delivery is null or delivery<0 or delivery>100000 then raise exception 'Delivery charge not approved';end if;
 if coalesce(payload->>'payment_method','') not in ('COD','bKash','Nagad','ONLINE') then raise exception 'Invalid payment method';end if;
 if payload->>'payment_method' in ('bKash','Nagad') and (length(coalesce(payload->>'transaction_id',''))<4 or coalesce(cfg->>(case when payload->>'payment_method'='bKash' then 'payment_bkash' else 'payment_nagad' end),'')='') then raise exception 'Approved payment instructions and transaction ID required';end if;
 -- Lock products in consistent order. Stock is reserved atomically with order creation.
 for item in select value from jsonb_array_elements(payload->'items') order by value->>'product_id' loop
 if coalesce(item->>'qty','') !~ '^[0-9]{1,2}$' then raise exception 'Invalid quantity';end if;qty:=(item->>'qty')::integer;
 if qty not between 1 and 99 then raise exception 'Invalid quantity';end if;
 select * into p from public.products where id=item->>'product_id' for update;
 if not found or not p.active or p.sample or p.stock<qty then raise exception 'Product unavailable or sample-only';end if;
 total_price:=total_price+p.price*qty;
 end loop;
 if payload->>'payment_method'='ONLINE' then
 if cfg->>'online_payment_enabled' is distinct from 'true' then raise exception 'Online payment is disabled';end if;
 online_percent:=coalesce((cfg->>'online_discount_percent')::numeric,0);if online_percent not between 0 and 50 then raise exception 'Invalid discount settings';end if;discount_value:=round(total_price*online_percent/100,2);
 if coalesce(payload#>>'{customer,email}','') !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' or coalesce(length(payload#>>'{customer,email}'),0)>254 or coalesce(payload#>>'{customer,postcode}','') !~ '^[0-9]{4}$' then raise exception 'Valid email and actual postcode required by gateway';end if;
 end if;
 if coalesce((payload->>'expected_discount')::numeric,0) is distinct from discount_value then raise exception 'Discount changed; review again';end if;
 if (payload->>'expected_subtotal')::numeric is distinct from total_price or (payload->>'expected_delivery')::numeric is distinct from delivery then raise exception 'Price or delivery changed; review your cart again';end if;
 insert into public.customers(name,phone) values(trim(payload#>>'{customer,name}'),phone) returning id into cid;
 insert into public.orders(idempotency_key,request_hash,customer_id,customer_name,phone,address,district,area,notes,payment_method,transaction_id,payment_status,subtotal,delivery_charge,discount,total,consent_at,customer_email,postcode)
 values(k,h,cid,trim(payload#>>'{customer,name}'),phone,trim(payload#>>'{customer,address}'),trim(payload#>>'{customer,district}'),trim(payload#>>'{customer,area}'),coalesce(payload->>'notes',''),payload->>'payment_method',coalesce(payload->>'transaction_id',''),case when payload->>'payment_method'='COD' then 'Unpaid' else 'Verification pending' end,total_price,delivery,discount_value,total_price+delivery-discount_value,now(),coalesce(payload#>>'{customer,email}',''),coalesce(payload#>>'{customer,postcode}','')) returning id into oid;
 for item in select value from jsonb_array_elements(payload->'items') loop
 select * into p from public.products where id=item->>'product_id';qty:=(item->>'qty')::integer;
 insert into public.order_items(order_id,product_id,name,qty,price) values(oid,p.id,p.name,qty,p.price);
 update public.products set stock=stock-qty where id=p.id;
 end loop;
 end if;
 select (to_jsonb(o)-'request_hash'-'idempotency_key'-'customer_id')||jsonb_build_object('items',(select jsonb_agg(to_jsonb(i)-'order_id'-'id') from public.order_items i where i.order_id=oid)) into result from public.orders o where o.id=oid;return result;
end$$;
create table public.reviews(id uuid primary key default gen_random_uuid(),product_id text not null references public.products(id),order_id uuid references public.orders(id),author_name text not null check(length(author_name) between 2 and 80),rating integer not null check(rating between 1 and 5),body text not null check(length(body) between 20 and 1500),status text not null default 'Pending' check(status in ('Pending','Approved','Rejected')),sample boolean not null default false,verified_purchase boolean not null default false,created_at timestamptz not null default now(),unique(order_id,product_id),check(not(sample and verified_purchase)));
alter table public.reviews enable row level security;
create policy admin_review_read on public.reviews for select to authenticated using(public.is_admin());
create policy admin_review_moderate on public.reviews for update to authenticated using(public.is_admin()) with check(public.is_admin());
revoke all on public.reviews from anon,authenticated;
grant select on public.reviews to authenticated;
grant update(status) on public.reviews to authenticated;
grant all on public.reviews to service_role;
-- Intentionally owner-run safe projection. Never expose order_id to public visitors.
create view public.public_reviews as select r.id,r.product_id,r.author_name,r.rating,r.body,r.sample,r.verified_purchase,r.created_at from public.reviews r join public.products p on p.id=r.product_id where r.status='Approved' and p.active;
grant select on public.public_reviews to anon,authenticated,service_role;
create trigger audit_review after insert or update or delete on public.reviews for each row execute function public.audit_change();
create function public.submit_review_secure(payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$declare o public.orders;v_phone text;rid uuid;begin
 v_phone:=regexp_replace(coalesce(payload->>'phone',''),'[^0-9]','','g');if v_phone like '8801%' then v_phone:=substring(v_phone from 3);end if;
 select * into o from public.orders where id=(payload->>'order_id')::uuid and public.orders.phone=v_phone and status='Delivered';
 if not found or not exists(select 1 from public.order_items where order_id=o.id and product_id=payload->>'product_id') then raise exception 'Delivered order verification failed';end if;
 if coalesce(payload->>'rating','') !~ '^[1-5]$' or coalesce(length(trim(payload->>'author_name')),0) not between 2 and 80 or coalesce(length(trim(payload->>'body')),0) not between 20 and 1500 then raise exception 'Invalid review fields';end if;
 insert into public.reviews(product_id,order_id,author_name,rating,body,verified_purchase,sample) values(payload->>'product_id',o.id,trim(payload->>'author_name'),(payload->>'rating')::integer,trim(payload->>'body'),o.gateway_mode is distinct from 'sandbox',o.gateway_mode is not distinct from 'sandbox') returning id into rid;
 return jsonb_build_object('id',rid,'status','Pending');end$$;
create table public.payment_attempts(id uuid primary key default gen_random_uuid(),order_id uuid not null references public.orders(id),tran_id text not null unique,amount numeric(12,2) not null check(amount>0),mode text not null check(mode in ('sandbox','live')),status text not null default 'Initiating' check(status in ('Initiating','Ready','Paid','Failed','Expired','Review','Sandbox verified')),checkout_url text,val_id text unique,expires_at timestamptz not null default(now()+interval '30 minutes'),created_at timestamptz not null default now());
create unique index one_active_payment_attempt on public.payment_attempts(order_id) where status in ('Initiating','Ready','Review');
alter table public.payment_attempts enable row level security;
create policy admin_payment_attempts on public.payment_attempts for select to authenticated using(public.is_admin());
revoke all on public.payment_attempts from anon,authenticated;grant select on public.payment_attempts to authenticated;grant all on public.payment_attempts to service_role;
create function public.reserve_payment_attempt(p_order uuid,p_mode text) returns jsonb language plpgsql security definer set search_path='' as $$declare o public.orders;a public.payment_attempts;begin
 select * into o from public.orders where id=p_order for update;
 if not found or o.payment_method<>'ONLINE' or o.payment_status in ('Paid','Refunded','Sandbox verified') or o.status not in ('Pending','Confirmed','Processing') or o.total<=0 then raise exception 'Order is not payable';end if;
 if p_mode not in ('sandbox','live') then raise exception 'Invalid gateway environment';end if;
 select * into a from public.payment_attempts where order_id=p_order and status in ('Initiating','Ready','Review') for update;
 if found then
 if a.status='Review' then raise exception 'Payment needs manual review';end if;
 if a.expires_at>now() and not(a.status='Initiating' and a.created_at<now()-interval '2 minutes') then return to_jsonb(a)||jsonb_build_object('is_new',false);end if;
 update public.payment_attempts set status='Expired' where id=a.id;
 end if;
 insert into public.payment_attempts(order_id,tran_id,amount,mode) values(o.id,left(replace(gen_random_uuid()::text,'-',''),30),o.total,p_mode) returning * into a;
 update public.orders set gateway_mode=p_mode where id=o.id;
 return to_jsonb(a)||jsonb_build_object('is_new',true);end$$;
create function public.finalize_gateway_payment(p_tran text,p_val text,p_amount numeric,p_currency text,p_risk integer,p_mode text) returns jsonb language plpgsql security definer set search_path='' as $$declare a public.payment_attempts;o public.orders;begin
 select * into a from public.payment_attempts where tran_id=p_tran;if not found then raise exception 'Unknown transaction';end if;
 select * into o from public.orders where id=a.order_id for update;
 select * into a from public.payment_attempts where id=a.id for update;
 if p_currency is distinct from 'BDT' or p_amount is distinct from a.amount or p_amount is distinct from o.total or p_mode is distinct from a.mode or coalesce(length(p_val),0) not between 1 and 160 then raise exception 'Payment amount/currency/environment mismatch';end if;
 if a.status in ('Paid','Sandbox verified') and a.val_id=p_val then return jsonb_build_object('order_id',o.id,'state',a.status);end if;
 if o.status in ('Cancelled','Returned') or o.payment_status in ('Paid','Sandbox verified','Refunded') or coalesce(p_risk,1)<>0 then update public.payment_attempts set status='Review',val_id=p_val where id=a.id;return jsonb_build_object('order_id',o.id,'state','Review');end if;
 update public.payment_attempts set status=case when p_mode='live' then 'Paid' else 'Sandbox verified' end,val_id=p_val where id=a.id;
 update public.orders set payment_status=case when p_mode='live' then 'Paid' else 'Sandbox verified' end,transaction_id=p_tran,gateway_mode=p_mode where id=o.id;
 return jsonb_build_object('order_id',o.id,'state',case when p_mode='live' then 'Paid' else 'Sandbox verified' end);end$$;
create trigger audit_gateway after insert or update on public.payment_attempts for each row execute function public.audit_change();
revoke all on function public.submit_review_secure(jsonb),public.reserve_payment_attempt(uuid,text),public.finalize_gateway_payment(text,text,numeric,text,integer,text) from public,anon,authenticated;
grant execute on function public.submit_review_secure(jsonb),public.reserve_payment_attempt(uuid,text),public.finalize_gateway_payment(text,text,numeric,text,integer,text) to service_role;
commit;
