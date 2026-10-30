import {db,handle} from '../_shared/http.ts';
Deno.serve(req=>handle(req,'review',5,async body=>{const {data,error}=await db.rpc('submit_review_secure',{payload:body});if(error)throw error;return {review:data}}));
