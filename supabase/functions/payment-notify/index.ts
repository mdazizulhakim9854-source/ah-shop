import {db,readTextBounded} from '../_shared/http.ts';
import {gatewayEnv} from '../_shared/gateway.ts';
// Public provider callback. NEVER trust callback status/amount or browser return query.
// Authenticate success by querying the provider's official Order Validation API with server credentials.
Deno.serve(async req=>{
 if(!['POST','GET'].includes(req.method))return new Response('Method not allowed',{status:405});
 const url=new URL(req.url);const isReturn=url.searchParams.get('return')==='1';const env=gatewayEnv();let orderId='';let state='unverified';
 try{
 if(!env.storeId||!env.password||!env.validMode)throw Error('Merchant not configured');
 const salt=Deno.env.get('RATE_LIMIT_SALT');if(!salt)throw Error('Server configuration incomplete');const ip=(req.headers.get('x-forwarded-for')||'unknown').split(',')[0];const digest=await crypto.subtle.digest('SHA-256',new TextEncoder().encode(salt+'gateway-callback'+ip));const key=Array.from(new Uint8Array(digest),b=>b.toString(16).padStart(2,'0')).join('');const rate=await db.rpc('consume_rate_limit',{p_key:key,p_limit:3000,p_seconds:600});if(rate.error||!rate.data)throw Error('Callback rate limit reached');
 const data=req.method==='POST'?new URLSearchParams(await readTextBounded(req)):url.searchParams;
 const val=data.get('val_id')||'';if(val.length>160)throw Error('Invalid validation ID');
 if(val){const validation=new URL(env.base+'/validator/api/validationserverAPI.php');validation.search=new URLSearchParams({val_id:val,store_id:env.storeId,store_passwd:env.password,format:'json',v:'1'}).toString();const response=await fetch(validation,{signal:AbortSignal.timeout(20000)});if(!response.ok)throw Error('Provider validation unavailable');const verified=await response.json();
 if(!['VALID','VALIDATED'].includes(verified.status)||typeof verified.tran_id!=='string'||verified.currency!=='BDT'||(verified.val_id&&verified.val_id!==val)||(verified.store_id&&verified.store_id!==env.storeId))throw Error('Provider did not verify payment');
 const amount=Number(verified.amount);if(!Number.isFinite(amount)||amount<=0)throw Error('Invalid amount');const {data:result,error}=await db.rpc('finalize_gateway_payment',{p_tran:verified.tran_id,p_val:val,p_amount:amount,p_currency:verified.currency,p_risk:/^[01]$/.test(String(verified.risk_level))?Number(verified.risk_level):1,p_mode:env.mode});if(error)throw error;orderId=result.order_id;state=result.state;
 }
 // On cancelled/failed/browser returns do not mutate payment state from untrusted fields.
 if(!isReturn)return new Response(JSON.stringify({received:true,state}),{headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
 }catch{if(!isReturn)return new Response('Payment verification not completed',{status:400,headers:{'Cache-Control':'no-store'}})}
 if(!/^https:\/\//.test(env.site))return new Response('Return to AH SHOP tracking to check payment status.',{headers:{'Cache-Control':'no-store'}});
 const destination=new URL(env.site);destination.hash='/payment-result'+(orderId?'?order='+encodeURIComponent(orderId):'');return new Response(null,{status:303,headers:{Location:destination.toString(),'Cache-Control':'no-store'}});
});
