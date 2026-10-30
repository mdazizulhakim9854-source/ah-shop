import {db,handle} from '../_shared/http.ts';
import {ready,makePaymentToken} from '../_shared/gateway.ts';
Deno.serve(req=>handle(req,'checkout',12,async body=>{if(body.payment_method==='ONLINE'&&!await ready())throw Error('Merchant gateway is not configured');const {data,error}=await db.rpc('create_order_secure',{payload:body});if(error)throw error;if(data.payment_method==='ONLINE')data.payment_token=await makePaymentToken(data.id);return {order:data}}));
