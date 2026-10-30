import {db,handle} from '../_shared/http.ts';
import {ready,gatewayEnv,verifyPaymentToken,safeGatewayUrl} from '../_shared/gateway.ts';
Deno.serve(req=>handle(req,'payment-init',15,async body=>{
 if(!await ready())throw Error('Gateway unavailable');const id=String(body.order_id||'');if(!/^[0-9a-f-]{36}$/i.test(id)||!await verifyPaymentToken(id,String(body.payment_token||'')))throw Error('Invalid/expired payment authorization');
 const env=gatewayEnv();const {data:attempt,error}=await db.rpc('reserve_payment_attempt',{p_order:id,p_mode:env.mode});if(error)throw error;
 if(!attempt.is_new){if(attempt.checkout_url&&safeGatewayUrl(attempt.checkout_url))return {url:attempt.checkout_url,mode:env.mode};throw Error('Payment session is being prepared. Retry shortly.');}
 try{
 const {data:o,error:oe}=await db.from('orders').select('*,items:order_items(qty)').eq('id',id).single();if(oe||!o)throw Error('Order missing');
 const callback=Deno.env.get('SUPABASE_URL')+'/functions/v1/payment-notify';
 const form=new URLSearchParams({store_id:env.storeId,store_passwd:env.password,total_amount:Number(o.total).toFixed(2),currency:'BDT',tran_id:attempt.tran_id,
 success_url:callback+'?return=1',fail_url:callback+'?return=1',cancel_url:callback+'?return=1',ipn_url:callback,
 cus_name:o.customer_name,cus_email:o.customer_email,cus_add1:o.address,cus_city:o.district,cus_state:o.area,cus_postcode:o.postcode,cus_country:'Bangladesh',cus_phone:o.phone,
 shipping_method:'Courier',ship_name:o.customer_name,ship_add1:o.address,ship_city:o.district,ship_state:o.area,ship_postcode:o.postcode,ship_country:'Bangladesh',
 num_of_item:String((o.items||[]).reduce((sum:number,i:{qty:number})=>sum+i.qty,0)),product_name:'AH SHOP order '+o.id,product_category:'General',product_profile:'general',value_a:o.id});
 const response=await fetch(env.base+'/gwprocess/v4/api.php',{method:'POST',body:form,signal:AbortSignal.timeout(25000)});if(!response.ok)throw Error('Gateway session failed');const result=await response.json();if(result.status!=='SUCCESS'||!safeGatewayUrl(result.GatewayPageURL))throw Error('Gateway rejected session');
 const {error:updateError}=await db.from('payment_attempts').update({status:'Ready',checkout_url:result.GatewayPageURL}).eq('id',attempt.id).eq('status','Initiating');if(updateError)throw updateError;return {url:result.GatewayPageURL,mode:env.mode};
 }catch(e){await db.from('payment_attempts').update({status:'Failed'}).eq('id',attempt.id).eq('status','Initiating');throw e}
}));
