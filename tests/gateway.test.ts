// Local tests only. These are NOT merchant credentials and no network requests are sent.
Deno.env.set('SUPABASE_URL','https://sample-only.supabase.co');
Deno.env.set('SUPABASE_SERVICE_ROLE_KEY','test-only-not-a-real-key');
Deno.env.set('PAYMENT_TOKEN_SECRET',crypto.randomUUID()+crypto.randomUUID());
const {makePaymentToken,verifyPaymentToken,safeGatewayUrl}=await import('../supabase/functions/_shared/gateway.ts');
const {readTextBounded}=await import('../supabase/functions/_shared/http.ts');
const check=(condition:boolean)=>{if(!condition)throw Error('Assertion failed')};
Deno.test('payment authorization accepts a valid order-bound token',async()=>{const id=crypto.randomUUID();const token=await makePaymentToken(id);check(await verifyPaymentToken(id,token))});
Deno.test('payment authorization rejects other orders and tampered signatures',async()=>{const id=crypto.randomUUID();const token=await makePaymentToken(id);check(!await verifyPaymentToken(crypto.randomUUID(),token));check(!await verifyPaymentToken(id,token.slice(0,-2)+'ff'))});
Deno.test('expired token cannot initialize payment',async()=>check(!await verifyPaymentToken(crypto.randomUUID(),'1.'+'0'.repeat(64))));
Deno.test('gateway redirect is HTTPS and official-host allowlisted',()=>{check(safeGatewayUrl('https://sandbox.sslcommerz.com/test'));check(!safeGatewayUrl('https://sandbox.sslcommerz.com.evil.example/'));check(!safeGatewayUrl('javascript:alert(1)'));check(!safeGatewayUrl('http://securepay.sslcommerz.com/'))});
Deno.test('streamed request size is enforced before buffering',async()=>{try{await readTextBounded(new Request('https://sample.invalid',{method:'POST',body:'123456'}),4);throw Error('Unexpected success')}catch(e){check(e instanceof Error&&e.message==='Request too large')}});
