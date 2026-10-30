import {createClient} from '@supabase/supabase-js';
const env=(import.meta as unknown as {env:Record<string,string>}).env;
export const showcaseOnly=env.VITE_SHOWCASE_ONLY==='true';
export const supabase=!showcaseOnly&&env.VITE_SUPABASE_URL&&env.VITE_SUPABASE_ANON_KEY?createClient(env.VITE_SUPABASE_URL,env.VITE_SUPABASE_ANON_KEY):null;
export const live=!!supabase;
export async function invoke(name:string,body:Record<string,unknown>){if(!supabase)throw Error('Backend সংযুক্ত নয়');const {data,error}=await supabase.functions.invoke(name,{body});if(error)throw Error('অনুরোধ সম্পন্ন হয়নি। তথ্য যাচাই করে আবার চেষ্টা করুন।');if(data.error)throw Error(data.error);return data;}
