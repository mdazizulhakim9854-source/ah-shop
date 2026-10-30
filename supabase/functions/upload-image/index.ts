import {db} from '../_shared/http.ts';
Deno.serve(async req=>{
 const origin=req.headers.get('origin')||'';const allowed=(Deno.env.get('SITE_ORIGINS')||'').split(',').map(s=>s.trim());
 if(!origin||!allowed.includes(origin))return new Response('Forbidden',{status:403});
 const headers={'Access-Control-Allow-Origin':origin,'Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Content-Type':'application/json','Cache-Control':'no-store','Vary':'Origin'};
 const reply=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers});
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});if(req.method!=='POST')return reply({error:'Method not allowed'},405);
 try{
 const token=(req.headers.get('authorization')||'').replace(/^Bearer /i,'');const {data:{user},error}=await db.auth.getUser(token);if(error||!user)return reply({error:'Authentication required'},401);
 const role=await db.from('admin_roles').select('user_id').eq('user_id',user.id).maybeSingle();if(!role.data)return reply({error:'Admin role required'},403);
 const mime=req.headers.get('content-type')?.split(';')[0]||'';if(!['image/jpeg','image/png','image/webp'].includes(mime))return reply({error:'JPEG, PNG or WebP only'},400);
 const reader=req.body?.getReader();if(!reader)return reply({error:'Image required'},400);const chunks:Uint8Array[]=[];let total=0;
 while(true){const {done,value}=await reader.read();if(done)break;total+=value.byteLength;if(total>3145728){await reader.cancel();return reply({error:'Maximum image size: 3 MB'},413)}chunks.push(value)}
 const bytes=new Uint8Array(total);let offset=0;for(const c of chunks){bytes.set(c,offset);offset+=c.length}
 const isPng=[137,80,78,71,13,10,26,10].every((v,i)=>bytes[i]===v);
 const isJpeg=bytes.length>4&&bytes[0]===255&&bytes[1]===216&&bytes[2]===255&&bytes[bytes.length-2]===255&&bytes[bytes.length-1]===217;
 const isWebp=new TextDecoder().decode(bytes.slice(0,4))==='RIFF'&&new TextDecoder().decode(bytes.slice(8,12))==='WEBP';
 if(!((mime==='image/png'&&isPng)||(mime==='image/jpeg'&&isJpeg)||(mime==='image/webp'&&isWebp)))return reply({error:'File content does not match format'},400);
 const name=crypto.randomUUID()+'.'+({'image/png':'png','image/jpeg':'jpg','image/webp':'webp'}[mime]);const result=await db.storage.from('product-images').upload(name,bytes,{contentType:mime,upsert:false});if(result.error)throw Error('Storage upload failed');return reply({url:db.storage.from('product-images').getPublicUrl(name).data.publicUrl});
 }catch{return reply({error:'Image upload failed. Check authentication and storage.'},400)}
});
