import {createClient} from 'npm:@supabase/supabase-js@2';
export const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false}});
export async function handle(req:Request,action:string,limit:number,fn:(body:any)=>Promise<unknown>){
 const allowed=(Deno.env.get('SITE_ORIGINS')||'').split(',').map(x=>x.trim()).filter(Boolean);const origin=req.headers.get('origin')||'';
 const headers={'Access-Control-Allow-Origin':origin,'Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Vary':'Origin','Content-Type':'application/json','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'};
 const reply=(v:unknown,status=200)=>new Response(JSON.stringify(v),{status,headers});
 if(!allowed.includes(origin))return new Response('Origin not allowed',{status:403});
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
 if(req.method!=='POST')return reply({error:'Method not allowed'},405);
 try{
 const salt=Deno.env.get('RATE_LIMIT_SALT');if(!salt)return reply({error:'Server configuration incomplete'},503);
 // In deployment, confirm your gateway overwrites this header. Do not put a user-controlled proxy in front.
 const ip=(req.headers.get('x-forwarded-for')||req.headers.get('cf-connecting-ip')||'unknown').split(',')[0].trim();
 const digest=await crypto.subtle.digest('SHA-256',new TextEncoder().encode(salt+action+ip));const key=Array.from(new Uint8Array(digest),b=>b.toString(16).padStart(2,'0')).join('');
 const {data,error}=await db.rpc('consume_rate_limit',{p_key:key,p_limit:limit,p_seconds:600});if(error)return reply({error:'Service temporarily unavailable'},503);if(!data)return reply({error:'অনুরোধের সীমা হয়েছে। ১০ মিনিট পরে চেষ্টা করুন।'},429);
 const raw=await readTextBounded(req);if(raw.length>16000)return reply({error:'Request too large'},413);const body=JSON.parse(raw);if(!body||Array.isArray(body)||typeof body!=='object')return reply({error:'Invalid request'},400);
 return reply(await fn(body));
 }catch(e){console.error(action,e instanceof Error?e.message:'request failure');return reply({error:action==='track'?'অর্ডার খুঁজে পাওয়া যায়নি অথবা যাচাই মেলেনি।':'অনুরোধ সম্পন্ন হয়নি। তথ্য, বর্তমান মূল্য ও স্টক যাচাই করুন।'},400)}
}

export async function readTextBounded(req:Request,max=16000){const reader=req.body?.getReader();if(!reader)return '';const chunks:Uint8Array[]=[];let total=0;while(true){const {done,value}=await reader.read();if(done)break;total+=value.length;if(total>max){await reader.cancel();throw Error('Request too large')}chunks.push(value)}const bytes=new Uint8Array(total);let offset=0;for(const c of chunks){bytes.set(c,offset);offset+=c.length}return new TextDecoder().decode(bytes)}
