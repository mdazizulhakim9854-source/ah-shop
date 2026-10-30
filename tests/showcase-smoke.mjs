// Checks the Sample-only build locally or after GitHub Pages deployment.
// Usage: AH_SHOWCASE_URL=https://OWNER.github.io/ah-shop/ node tests/showcase-smoke.mjs
import {chromium} from 'playwright';
import assert from 'node:assert/strict';
const base=process.env.AH_SHOWCASE_URL||'http://127.0.0.1:4173/ah-shop/';
const browser=await chromium.launch({headless:true});
try {
 const page=await browser.newPage({viewport:{width:390,height:844}});
 const errors=[];const forbidden=[];page.on('pageerror',e=>errors.push(e.message));
 page.on('request',r=>{if(/supabase\.(co|in)|api\.openai\.com|wa\.me\//.test(r.url()))forbidden.push(r.url())});
 const response=await page.goto(base,{waitUntil:'networkidle'});assert.equal(response.status(),200);
 assert.ok(await page.locator('.showcase-notice').isVisible());
 assert.ok((await page.locator('.showcase-notice').innerText()).includes('বাস্তব দোকান নয়'));
 assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false);
 await page.goto(new URL('#/products',base).href,{waitUntil:'networkidle'});
 assert.ok(await page.locator('.product-card').count()>0);
 await page.locator('.add-btn').first().click();
 await page.goto(new URL('#/cart',base).href,{waitUntil:'networkidle'});
 assert.ok(await page.locator('.cart-line').count()>0);
 await page.goto(new URL('#/checkout',base).href,{waitUntil:'networkidle'});
 assert.ok((await page.locator('body').innerText()).includes('Sample')||(await page.locator('body').innerText()).includes('Demo'));
 await page.goto(new URL('setup.html',base).href,{waitUntil:'networkidle'});
 assert.ok((await page.locator('h1').innerText()).includes('কী চালু'));
 assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false);
 assert.deepEqual(errors,[]);assert.deepEqual(forbidden,[]);
 console.log('PASS: Sample banner, catalog, cart, checkout, status page, 390px layout; no backend/payment/WhatsApp requests or JS errors.');
} finally {await browser.close()}
