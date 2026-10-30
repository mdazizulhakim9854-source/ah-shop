-- AH SHOP: run once on a fresh Supabase project. No business data seeded.
begin;
-- PostgreSQL gen_random_uuid() and sha256() are built in; no extra extension required.
create table public.admin_roles(user_id uuid primary key references auth.users(id) on delete cascade);
create function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.admin_roles where user_id=auth.uid())$$;
create table public.categories(id text primary key default gen_random_uuid()::text,name text not null check(length(name) between 1 and 80),name_en text not null check(length(name_en) between 1 and 80),icon text not null default 'Package');
create table public.products(
 id text primary key default gen_random_uuid()::text,name text not null check(length(name) between 1 and 150),name_en text not null check(length(name_en) between 1 and 150),
 description text not null default '' check(length(description)<=5000),category_id text not null references public.categories(id),price numeric(12,2) not null check(price>0 and price<=10000000),
 compare_at numeric(12,2) check(compare_at>price),stock integer not null default 0 check(stock between 0 and 1000000),sku text not null unique check(sku ~ '^[A-Za-z0-9_-]{1,60}$'),
 active boolean not null default false,sample boolean not null default false,art text not null default 'bag',image_url text check(image_url is null or image_url ~ '^https://'),created_at timestamptz not null default now());
create table public.inventory(product_id text primary key references public.products(id),quantity integer not null check(quantity>=0),updated_at timestamptz not null default now());
create table public.customers(id uuid primary key default gen_random_uuid(),name text not null,phone text not null,created_at timestamptz not null default now());
create table public.orders(
 id uuid primary key default gen_random_uuid(),idempotency_key uuid not null unique,request_hash text not null,customer_id uuid not null references public.customers(id),
 customer_name text not null,phone text not null check(phone ~ '^01[3-9][0-9]{8}$'),address text not null,district text not null,area text not null,notes text not null default '',
 payment_method text not null check(payment_method in ('COD','bKash','Nagad')),transaction_id text not null default '',payment_status text not null default 'Unpaid' check(payment_status in ('Unpaid','Verification pending','Paid','Refunded')),
 status text not null default 'Pending' check(status in ('Pending','Confirmed','Processing','Shipped','Delivered','Cancelled','Returned')),
 subtotal numeric(12,2) not null check(subtotal>=0),delivery_charge numeric(12,2) not null check(delivery_charge>=0),discount numeric(12,2) not null default 0 check(discount>=0),total numeric(12,2) not null check(total>=0),
 consent_at timestamptz not null,created_at timestamptz not null default now(),check(total=subtotal+delivery_charge-discount));
create table public.order_items(id uuid primary key default gen_random_uuid(),order_id uuid not null references public.orders(id),product_id text not null references public.products(id),name text not null,qty integer not null check(qty between 1 and 99),price numeric(12,2) not null check(price>0),unique(order_id,product_id));
create index on public.order_items(order_id);create index on public.orders(created_at);create index on public.orders(status);create index on public.products(category_id);
create table public.site_settings(id text primary key check(id='public'),value jsonb not null default '{}'::jsonb);
insert into public.site_settings(id,value) values ('public','{"whatsapp":"","support_email":"","delivery_charge":null,"delivery_time":"","payment_bkash":"","payment_nagad":"","about":"","delivery_policy":"","return_policy":"","privacy_policy":"","terms":""}');
create table public.ai_agent_settings(id text primary key check(id='main'),enabled boolean not null default false,model text not null default '' check(length(model)<=100),system_note text not null default '' check(length(system_note)<=2000));
insert into public.ai_agent_settings(id) values('main');
create table public.audit_logs(id bigint generated always as identity primary key,actor uuid,event text not null,table_name text not null,record_id text not null,created_at timestamptz not null default now());
create table public.rate_limits(key text primary key,hits integer not null default 1,window_start timestamptz not null default now());
-- RLS: public catalog/settings are deliberately public; all customer/admin data is private.
do $$declare t text;begin foreach t in array array['admin_roles','categories','products','inventory','customers','orders','order_items','site_settings','ai_agent_settings','audit_logs','rate_limits'] loop execute format('alter table public.%I enable row level security',t);end loop;end$$;
create policy own_admin_role on public.admin_roles for select to authenticated using(user_id=auth.uid());
create policy public_categories on public.categories for select to anon,authenticated using(true);
create policy public_products on public.products for select to anon,authenticated using(active or public.is_admin());
create policy public_settings on public.site_settings for select to anon,authenticated using(id='public');
-- Never allow public writes or public order/customer selects.
do $$declare t text;begin foreach t in array array['categories','products','site_settings','ai_agent_settings'] loop execute format('create policy admin_write on public.%I for all to authenticated using(public.is_admin()) with check(public.is_admin())',t);end loop;
foreach t in array array['inventory','customers','orders','order_items','audit_logs'] loop execute format('create policy admin_read on public.%I for select to authenticated using(public.is_admin())',t);end loop;end$$;
-- Only payment_status may be directly updated. Order status changes use a locked RPC.
grant usage on schema public to anon,authenticated,service_role;
revoke all on all tables in schema public from anon,authenticated;
grant select on public.products,public.categories,public.site_settings to anon,authenticated;
grant select on public.admin_roles,public.inventory,public.customers,public.orders,public.order_items,public.audit_logs,public.ai_agent_settings to authenticated;
grant insert,update,delete on public.products,public.categories to authenticated;
grant insert,update on public.site_settings to authenticated;
grant update on public.ai_agent_settings to authenticated;
grant update(payment_status) on public.orders to authenticated;
create policy admin_payment_update on public.orders for update to authenticated using(public.is_admin()) with check(public.is_admin());
grant all on all tables in schema public to service_role;grant all on all sequences in schema public to service_role;
create function public.sync_inventory() returns trigger language plpgsql security definer set search_path='' as $$begin insert into public.inventory(product_id,quantity) values(new.id,new.stock) on conflict(product_id) do update set quantity=excluded.quantity,updated_at=now();return new;end$$;
create trigger sync_inventory after insert or update of stock on public.products for each row execute function public.sync_inventory();
create function public.audit_change() returns trigger language plpgsql security definer set search_path='' as $$begin insert into public.audit_logs(actor,event,table_name,record_id) values(auth.uid(),tg_op,tg_table_name,coalesce(to_jsonb(new)->>'id',to_jsonb(old)->>'id','unknown'));return coalesce(new,old);end$$;
do $$declare t text;begin foreach t in array array['products','categories','orders','site_settings','ai_agent_settings'] loop execute format('create trigger audit_change after insert or update or delete on public.%I for each row execute function public.audit_change()',t);end loop;end$$;
create function public.consume_rate_limit(p_key text,p_limit integer,p_seconds integer) returns boolean language plpgsql security definer set search_path='' as $$declare n integer;begin
 insert into public.rate_limits(key) values(p_key) on conflict(key) do update set hits=case when public.rate_limits.window_start<now()-make_interval(secs=>p_seconds) then 1 else public.rate_limits.hits+1 end,window_start=case when public.rate_limits.window_start<now()-make_interval(secs=>p_seconds) then now() else public.rate_limits.window_start end returning hits into n;return n<=p_limit;end$$;
create function public.create_order_secure(payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare k uuid;h text;old_order public.orders;cid uuid;oid uuid;item jsonb;p public.products;total_price numeric(12,2):=0;delivery numeric(12,2);cfg jsonb;phone text;qty integer;result jsonb;
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
 if coalesce(payload->>'payment_method','') not in ('COD','bKash','Nagad') then raise exception 'Invalid payment method';end if;
 if payload->>'payment_method'<>'COD' and (length(coalesce(payload->>'transaction_id',''))<4 or coalesce(cfg->>(case when payload->>'payment_method'='bKash' then 'payment_bkash' else 'payment_nagad' end),'')='') then raise exception 'Approved payment instructions and transaction ID required';end if;
 -- Lock products in consistent order. Stock is reserved atomically with order creation.
 for item in select value from jsonb_array_elements(payload->'items') order by value->>'product_id' loop
 if coalesce(item->>'qty','') !~ '^[0-9]{1,2}$' then raise exception 'Invalid quantity';end if;qty:=(item->>'qty')::integer;
 if qty not between 1 and 99 then raise exception 'Invalid quantity';end if;
 select * into p from public.products where id=item->>'product_id' for update;
 if not found or not p.active or p.sample or p.stock<qty then raise exception 'Product unavailable or sample-only';end if;
 total_price:=total_price+p.price*qty;
 end loop;
 if (payload->>'expected_subtotal')::numeric is distinct from total_price or (payload->>'expected_delivery')::numeric is distinct from delivery then raise exception 'Price or delivery changed; review your cart again';end if;
 insert into public.customers(name,phone) values(trim(payload#>>'{customer,name}'),phone) returning id into cid;
 insert into public.orders(idempotency_key,request_hash,customer_id,customer_name,phone,address,district,area,notes,payment_method,transaction_id,payment_status,subtotal,delivery_charge,total,consent_at)
 values(k,h,cid,trim(payload#>>'{customer,name}'),phone,trim(payload#>>'{customer,address}'),trim(payload#>>'{customer,district}'),trim(payload#>>'{customer,area}'),coalesce(payload->>'notes',''),payload->>'payment_method',coalesce(payload->>'transaction_id',''),case when payload->>'payment_method'='COD' then 'Unpaid' else 'Verification pending' end,total_price,delivery,total_price+delivery,now()) returning id into oid;
 for item in select value from jsonb_array_elements(payload->'items') loop
 select * into p from public.products where id=item->>'product_id';qty:=(item->>'qty')::integer;
 insert into public.order_items(order_id,product_id,name,qty,price) values(oid,p.id,p.name,qty,p.price);
 update public.products set stock=stock-qty where id=p.id;
 end loop;
 end if;
 select (to_jsonb(o)-'request_hash'-'idempotency_key'-'customer_id')||jsonb_build_object('items',(select jsonb_agg(to_jsonb(i)-'order_id'-'id') from public.order_items i where i.order_id=oid)) into result from public.orders o where o.id=oid;return result;
end$$;
create function public.track_order_secure(p_id uuid,p_phone text) returns jsonb language sql security definer set search_path='' as $$select jsonb_build_object('id',id,'status',status,'payment_status',payment_status,'created_at',created_at,'total',total) from public.orders where id=p_id and phone=p_phone$$;
create function public.admin_order_status(p_id uuid,p_status text) returns void language plpgsql security definer set search_path='' as $$declare o public.orders;item record;begin
 if not public.is_admin() then raise exception 'Forbidden';end if;
 select * into o from public.orders where id=p_id for update;if not found then raise exception 'Not found';end if;
 if o.status=p_status then return;end if;
 if not ((o.status='Pending' and p_status in ('Confirmed','Cancelled')) or (o.status='Confirmed' and p_status in ('Processing','Cancelled')) or (o.status='Processing' and p_status in ('Shipped','Cancelled')) or (o.status='Shipped' and p_status in ('Delivered','Returned')) or (o.status='Delivered' and p_status='Returned')) then raise exception 'Invalid status transition';end if;
 if p_status in ('Cancelled','Returned') then for item in select product_id,qty from public.order_items where order_id=p_id order by product_id loop update public.products set stock=stock+item.qty where id=item.product_id;end loop;end if;
 update public.orders set status=p_status where id=p_id;
end$$;
-- Crucial: security definer functions are NOT executable by the public by default.
revoke all on function public.create_order_secure(jsonb),public.track_order_secure(uuid,text),public.consume_rate_limit(text,integer,integer),public.sync_inventory(),public.audit_change() from public,anon,authenticated;
grant execute on function public.create_order_secure(jsonb),public.track_order_secure(uuid,text),public.consume_rate_limit(text,integer,integer) to service_role;
revoke all on function public.admin_order_status(uuid,text) from public,anon;grant execute on function public.admin_order_status(uuid,text) to authenticated;
revoke all on function public.is_admin() from public;grant execute on function public.is_admin() to anon,authenticated,service_role;
-- Secure public product-image bucket. Only verified admins can upload/change/delete.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('product-images','product-images',true,3145728,array['image/jpeg','image/png','image/webp']);
create policy public_product_images on storage.objects for select to anon,authenticated using(bucket_id='product-images');
-- Uploads go through the authenticated upload-image function (size + binary signature validation).
create policy admin_delete_product_images on storage.objects for delete to authenticated using(bucket_id='product-images' and public.is_admin());
commit;
