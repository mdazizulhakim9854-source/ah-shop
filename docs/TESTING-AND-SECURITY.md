# Testing, security ও backup checklist

> **v2 আপডেট:** checkout, private owner access, pinning, moderated reviews, SSLCOMMERZ connector ও Android AAB/APK এখন যোগ হয়েছে। বর্তমান নির্দেশনা: [v2 guide](V2-OWNER-PAYMENT-APP.md)। নিচের v1 baseline-এর পুরোনো ‘এখনো নেই’ বক্তব্যের ক্ষেত্রে v2 guide অনুসরণ করুন।


## ইতিমধ্যে এই workspace-এ যাচাই

| পরীক্ষা | ফলাফল | সীমা |
|---|---|---|
| TypeScript + Vite production build | পাস | cloud deployment নয় |
| Playwright: catalog/filter/wishlist/language | পাস | Chromium |
| Playwright: cart persistence + consent checkout + tracking privacy + cancel restock | পাস | local demo data |
| Playwright: mobile admin categories/products/settings/CSV | পাস | emulated 390px |
| Playwright: সব public/admin route ও overflow/error | পাস | emulated 360px |
| Playwright: demo label, OTP warning, missing wallet instructions | পাস | rule-based |
| ২৫টি PostgreSQL database assertion | পাস | PGlite, mock auth/storage schemas; Supabase production নয় |
| ৪টি Edge Function Deno type-check | পাস | network/runtime gateway পরীক্ষা নয় |
| npm dependency audit | ০ vulnerability পাওয়া গেছে | পরীক্ষার মুহূর্তের database; security guarantee নয় |

`tests/database.mjs` migration, role privileges, RLS, price tamper, stock, duplicate idempotency, malformed consent, duplicate lines, phone lookup privacy, rate limits, immutable totals, admin/non-admin permission এবং status transitions পরীক্ষা করে।

Browser পরীক্ষা চালাতে 5173-এ dev server থাকা চাই। Dependency install পরে server restart করুন। PostCSS error আটকে থাকলে dev server বন্ধ/চালু করুন।

```bash
npm ci
npm run dev -- --port 5173
# আলাদা terminal
npm test
npm run test:db
npx deno check supabase/functions/create-order/index.ts \
  supabase/functions/track-order/index.ts \
  supabase/functions/ai-support/index.ts \
  supabase/functions/upload-image/index.ts
npm audit
npm run build
```

## বাস্তব account-এ release gate — এখনো বাকি

### Storefront / Android

- [ ] নিজের physical Android Chrome-এ 320/360/390px equivalent, portrait/landscape, slow network পরীক্ষা।
- [ ] Font load, readable text, tap target, keyboard, focus navigation, high zoom এবং dark mode।
- [ ] Empty search/cart/wishlist, missing product, inactive/deleted catalog product cart handling।
- [ ] Price/stock বদলে থাকা cart-এ server rejection ও পুনরায় review।
- [ ] Delivery charge unset হলে live order বন্ধ; approved ৳০ হলে কেবল তখনই zero charge।
- [ ] বাস্তব ব্যবসার approved data ও policies; sample product/price দেখে কেউ কেনাকাটা করছেন না।
- [ ] মূল storefront bilingual; admin ও কিছু error/policy guidance এখন বাংলা। পূর্ণ English admin translation লাগলে আলাদা কাজ।

### Auth / RLS

- [ ] Supabase Auth admin login/logout সত্যি কাজ করে।
- [ ] Non-admin token-এ admin queries কোনো customer/order row ফেরত দেয় না।
- [ ] Anonymous REST client থেকে customer/order/admin/settings secret data পড়া যায় না।
- [ ] Public anon key দিয়ে product price/stock/order status update ব্যর্থ।
- [ ] Anonymous user privileged checkout/track/rate SQL RPC সরাসরি চালাতে পারেন না।
- [ ] Admin user কখনো client থেকে নিজের role লিখে/বাড়িয়ে নিতে পারেন না।
- [ ] Role revoke সঙ্গে সঙ্গে server permission বন্ধ করে; signout-এর পরে private order state মুছে যায়।
- [ ] Supabase account MFA; app admin MFA enforcement/strong auth অতিরিক্ত hardening হিসেবে বিবেচনা।

### Checkout / inventory

- [ ] Client subtotal/discount/price tampering প্রত্যাখ্যান।
- [ ] Same idempotency key parallel retry-তে একই ID, একবার stock reserve।
- [ ] একই stock-এর শেষ পণ্য concurrent buyer নিলে oversell হয় না—real Postgres concurrency test করুন। Local PGlite test concurrent distributed traffic প্রমাণ নয়।
- [ ] Wrong/missing customer fields, negative/decimal qty, duplicate lines ও Sample product live order প্রত্যাখ্যান।
- [ ] Current delivery/price mismatch হলে saved reviewed total silently বদলায় না।
- [ ] Pending reservation manual cleanup এবং Returned product inspection workflow লিখিতভাবে ঠিক করুন।
- [ ] Status transition, cancel double-click, return stock once, audit actor/event যাচাই।
- [ ] Manual payment declaration API-verified বলে দেখানো হয় না।

### Edge / storage / tracking

- [ ] SITE_ORIGINS allowlist, preflight এবং unknown origin reject। CORS curl/bot-এর security boundary নয়।
- [ ] RATE_LIMIT_SALT set; server-hosted shared counter কাজ করে; trusted IP forwarding নিশ্চিত।
- [ ] WAF/CAPTCHA, application-wide budget বা abuse detection প্রয়োজন অনুযায়ী যোগ করুন। বর্তমান limits per-IP/action; shared mobile-carrier IP false-positive হতে পারে।
- [ ] No auth/ordinary user upload প্রত্যাখ্যান; admin correct image গ্রহণ।
- [ ] SVG/HTML/oversize/mismatched signature প্রত্যাখ্যান; uploaded valid image load।
- [ ] Order ID+wrong phone একই generic error; correct match-এ কোনো PII নেই।
- [ ] Phone match SMS possession verification নয়; sensitive action-এর আগে stronger auth।
- [ ] Body limit এবং log-এ sensitive payload নেই; screenshot/monitoring-এ PII redaction।

### AI / official APIs

- [ ] Consent off হলে AI provider usage নেই; mode label fallback।
- [ ] Enabled+valid model+key+consent-এ actual API request ও billing confirm।
- [ ] Prompt injection কখনো discount/price/status/write execute করতে পারে না।
- [ ] Unknown question-এ অনুমোদিত তথ্য নেই; complex complaints human handoff।
- [ ] AI timeout/invalid JSON/provider error-এ safe fallback, fabricated answer নয়।
- [ ] Privacy notice/provider retention/consent approved।
- [ ] Official WhatsApp/payment APIs যুক্ত না থাকলে active দাবি নেই।
- [ ] Future signed callbacks, replay IDs, amount match ও provider sandbox tests before activation।

### Deployment

- [ ] `.env.local`, access token, service-role/AI key source/static ZIP-এ নেই।
- [ ] Compiled frontend-এ শুধু public Supabase URL+anon key; service-role নয়।
- [ ] Host plan business-use terms এবং quota review। Vercel Hobby commercial নয়।
- [ ] HTTPS/custom DNS, auth redirect URLs, CORS origins, CSP domain allowlist ঠিক।
- [ ] Business owner policies approve, support contacts real, no made-up delivery promise।

## Backup ও disaster recovery

Free plan-এ managed backup আছে ধরে নেবেন না। বাস্তব order নেওয়ার আগে:

1. Database schema/migrations private version control-এ রাখুন।
2. Approved operator-এর secure environment থেকে নিয়মিত database export নিন। Provider CLI/dashboard-এর বর্তমান backup/export নির্দেশনা অনুসরণ করুন। সাধারণ SQL data export যথেষ্ট নয়—auth users, role settings, Storage objects আলাদাভাবে বিবেচনা করুন।
3. Product images-এর আসল ফাইল আলাদাভাবে backup; database backup-এ image bytes থাকে না।
4. Customer export encrypt করুন; ফোনের public Downloads/WhatsApp group-এ রাখবেন না। Access minimum, retention লিখিতভাবে ঠিক করুন।
5. দৈনিক order backup, সাপ্তাহিক full export, এবং restore drill-এর owner/schedule ঠিক করুন—প্রোটোটাইপে scheduled job তৈরি হয়নি।
6. আলাদা staging project-এ schema + data + images restore করে real functional checks করুন। Backup থাকা আর restore করা যাওয়া এক নয়।
7. Paid managed backup/PITR দরকার হলে আগে provider cost ও retention terms মেনে enable করুন।
8. Demo localStorage-কে কখনো backup বা business database ভাববেন না।

### Retention ও maintenance

- `audit_logs` metadata-এ retention ও access policy নির্ধারণ করুন।
- Rate limit records-এর পুরোনো bucket admin SQL job দিয়ে মুছতে পারেন:

```sql
-- PostgreSQL dashboard/approved maintenance role only. Not public frontend.
delete from public.rate_limits where window_start < now() - interval '7 days';
```

- এই cleanup automatically scheduled নয়। Provider-supported scheduler ব্যবহার করলে staging-এ পরীক্ষা করুন।
- Customer deletion/export requests, accounting retention ও legal requirements অনুযায়ী workflow আলাদা করে তৈরি করতে হবে।
- Secret ফাঁস হলে revoke/rotate আগে, তারপর repository/logs পরিষ্কার। Secret কখনো public chat-এ পাঠাবেন না।

## পরিচিত production gaps

Automated courier labels, SMS notifications/OTP, customer accounts/history, password recovery UI, advanced English admin, multi-zone delivery, variant sizes/colors, coupon engine, refund accounting, searchable large-scale reports, background jobs, malware scanning/re-encoding, real human ticket queue এবং official WhatsApp/payment adapters এই iteration-এ নেই। Scope লুকিয়ে “সম্পূর্ণ production-ready” বলা হচ্ছে না।
