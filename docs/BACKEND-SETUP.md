# Supabase: নিরাপদ database এবং admin login

> **v2 আপডেট:** checkout, private owner access, pinning, moderated reviews, SSLCOMMERZ connector ও Android AAB/APK এখন যোগ হয়েছে। বর্তমান নির্দেশনা: [v2 guide](V2-OWNER-PAYMENT-APP.md)। নিচের v1 baseline-এর পুরোনো ‘এখনো নেই’ বক্তব্যের ক্ষেত্রে v2 guide অনুসরণ করুন।


এই ধাপ আপনার account-এ করতে হবে। এখানে কোনো cloud account বা credentials বানানো হয়নি। প্রদত্ত SQL একটি **নতুন খালি Supabase project-এর একবারের migration**, existing production database-এ না পড়ে চালাবেন না।

## ১. Project তৈরি

1. Supabase dashboard-এ account → New project। Free plan নির্বাচন করার আগে limits পড়ুন।
2. শক্ত database password নিজের password manager-এ রাখুন। চ্যাট/source code-এ দেবেন না।
3. উপযুক্ত region নির্বাচন করুন; সেবা তৈরি হওয়া পর্যন্ত অপেক্ষা করুন।
4. Project URL এবং public anon/publishable key Project API settings থেকে নিন। নতুন publishable key ব্যবহার করলে আপনার dashboard/SDK-এর supported format নিশ্চিত করুন।
5. **Service-role/secret key frontend-এ নয়।** Supabase hosted Edge Function-এ built-in service-role environment ব্যবহার করা হচ্ছে; browser কখনো সেটি পায় না।

## ২. SQL বসান

Dashboard → SQL Editor → New query → `supabase/migrations/001_secure_shop.sql`-এর পুরো কোড paste → Run। Error হলে migration পুরোটি rollback হওয়ার কথা; error না বুঝে RLS off করবেন না।

টেবিল:

- `products`, `categories`: public catalog; শুধু active products public।
- `orders`, `order_items`, `customers`: public access নেই।
- `inventory`: products.stock trigger-এর synchronized snapshot, আলাদা দ্বৈত stock source নয়।
- `site_settings`: শুধু অনুমোদিত public business text; secret নিষিদ্ধ।
- `ai_agent_settings`: admin-only config, key এখানে রাখা হয় না।
- `admin_roles`: নিজে admin তৈরি করা যায় না।
- `audit_logs`: admin-only event metadata; customer address/payment secret dump করা হয় না।
- `rate_limits`: service-role-only hashed request buckets।

Migration কোনো আসল পণ্য, দাম, ফোন, ঠিকানা বা বিক্রয় সংখ্যা seed করে না। SQL-এর default empty settings দেখে admin দিয়ে তথ্য দিন।

## ৩. নিজের admin user

1. Authentication → Users → Add user / Create user। নিজের email ও শক্ত password দিন।
2. Email confirmation/SMTP setup provider অনুযায়ী করুন; public signup প্রয়োজন না হলে বন্ধ রাখুন।
3. Auth user-এর প্রকৃত UUID copy করুন। এটি database owner বা project ID নয়।
4. SQL Editor-এ নিচের নমুনায় `YOUR_AUTH_USER_UUID`-এর বদলে **সেই প্রকৃত UUID** দিন:

```sql
insert into public.admin_roles(user_id)
values ('YOUR_AUTH_USER_UUID'::uuid);
```

5. নিজের site → `/#/admin` → email/password দিয়ে login করুন। কোনো default admin/password নেই।
6. Role সরাতে SQL Editor-এ প্রকৃত UUID দিয়ে `delete from public.admin_roles where user_id='YOUR_AUTH_USER_UUID'::uuid;`। Session থাকলেও RLS আবার role দেখে।
7. Non-admin user তৈরি করে admin access না পাওয়া নিশ্চিত করুন। UI hidden রাখাই security নয়; RLS ও SQL grant আসল সুরক্ষা।

**MFA:** provider account-এ MFA চালু করুন। এই prototype-এর app login-এ TOTP challenge flow তৈরি করা হয়নি; production admin MFA enforce করতে অতিরিক্ত কাজ লাগবে। Password recovery admin/provider dashboard থেকে পরিচালনা করুন; custom recovery UI নেই।

## ৪. Frontend env

`.env.example` copy করে `.env.local`। দুইটি public value বসান, server restart/rebuild করুন। কোনো value না থাকলে demo mode; দুইটি থাকলে cloud mode। ভুল URL থাকলে setup error দেখাবে; গোপনে Sample data দিয়ে database success সাজাবে না।

## ৫. Edge functions deploy

Android-এর browser-based Linux workspace terminal (যেমন Codespaces), project folder-এ:

```bash
npx supabase login
npx supabase link --project-ref YOUR_ACTUAL_PROJECT_REF
npx supabase functions deploy create-order
npx supabase functions deploy track-order
npx supabase functions deploy ai-support
npx supabase functions deploy upload-image
```

`YOUR_ACTUAL_PROJECT_REF` dashboard থেকে প্রকৃত project ref দিয়ে প্রতিস্থাপন করুন। CLI login token নিজের password manager/encrypted workspace secret দিয়ে ব্যবহার করুন, public repo/চ্যাট/স্ক্রিনশটে নয়। Android Termux-এ Supabase CLI binary চলবেই—এমন ধরে নেওয়া হয়নি; Linux cloud terminal সুপারিশ করা হয়েছে।

`supabase/config.toml`-এ এই endpoints-এর JWT gateway check off আছে কারণ guest checkout/tracking অনুমোদিত এবং নতুন key formats-এর সঙ্গে আলাদা handler ব্যবহার করা হয়েছে। **এটি database RLS off করা নয়।** `upload-image` handler নিজেই bearer token যাচাই করে এবং admin role চায়। Guest endpoints শুধু সীমাবদ্ধ কাজের server handler।

### Edge secrets — Supabase dashboard-এর Functions → Secrets

| নাম | ব্যবহার |
|---|---|
| `SITE_ORIGINS` | নিজের অনুমোদিত HTTPS origins, comma-separated; trailing slash নয়; `*` নয় |
| `RATE_LIMIT_SALT` | password manager দিয়ে তৈরি কমপক্ষে ৩২ random byte-এর secret |
| `AI_API_KEY` | ঐচ্ছিক AI provider secret; AI চাইলে পরে |
| `AI_API_URL` | ঐচ্ছিক HTTPS OpenAI-compatible chat completions endpoint |

`SITE_ORIGINS`-এ উদাহরণস্বরূপ **আপনার নিজের** Pages/Vercel/custom domain origin বসবে; অন্যের URL বা এই guide-এর placeholder নয়। Codespaces preview origin দিয়ে পরীক্ষা করলে সেটিও সুনির্দিষ্টভাবে যোগ করুন। Cloudflare security header-এ Supabase default domain অনুমোদিত।

Supabase-এর `SUPABASE_URL` এবং `SUPABASE_SERVICE_ROLE_KEY` hosted functions-এর built-in পরিবেশে ব্যবহৃত হয়। এগুলো public env বা git-এ copy করবেন না।

## ৬. কেন server-side order দরকার

`create-order` → service-role-only `create_order_secure` RPC। Browser যে মোট পাঠায় সেটিকে অনুমোদিত মূল্য হিসেবে ব্যবহার করা হয় না।

- Explicit consent, Bangladesh phone, নাম/ঠিকানা/জেলা/এলাকার length, qty range, item count যাচাই।
- Product exists, active, non-Sample, sufficient stock নিশ্চিত।
- `FOR UPDATE` row locks + consistent lock order: stock atomically reserve।
- Server database থেকে product price ও delivery charge পড়ে।
- Browser-এর reviewed `expected_subtotal`/`expected_delivery` current server value-এর সঙ্গে না মিললে **reject**, নতুন মূল্য নিয়ে আবার review লাগবে।
- Full transaction-এ customer, order, items, stock লেখা হয়; মাঝপথে ব্যর্থ হলে rollback।
- `idempotency_key` unique + advisory lock + request hash; একই key/একই payload আবার দিলে একই order; payload বদলালে reject।
- Frontend double-submit button disable করে; retry key success পর্যন্ত ডিভাইসে থাকে। নতুন সম্মতিপূর্ণ checkout নতুন order হতে পারে—একই customer/product মানেই duplicate নয়।
- Status Pending; COD Unpaid; manual-wallet Verification pending।
- Order tracking-এ শুধু ID/status/payment status/date/total, কোনো PII নয়।

Phone match possession-এর SMS OTP প্রমাণ নয়। UUID-এর গোপনীয়তা + পুরো ফোন match ও server rate limit ব্যবহার করা হয়েছে। Sensitive details, cancel/refund বা account history চালু করতে authenticated customer/OTP verification যোগ করবেন। Tracking-এ এখন সেগুলো নেই।

## ৭. Images

- Browser: allowlist, 1 MB demo / 3 MB live, `createImageBitmap` decode check।
- Cloud: `upload-image` bearer user verification + admin role; streamed 3 MB cap, MIME + JPEG/PNG/WebP binary signature match।
- UUID filename, no overwrite; Storage bucket MIME/size restrictions। SVG/HTML নয়।
- সাধারণ authenticated user-কে Storage insert policy দেওয়া হয়নি; validated service handler upload করে। Product images ইচ্ছাকৃতভাবে public; customer documents এখানে রাখবেন না।
- এটি full malware scanning বা server-side image re-encoding নয়। Production-এ image pixel budget/sanitization/CDN pipeline দরকার হলে যোগ করুন। Orphan images-এর lifecycle cleanup এখন manual।

## ৮. সীমাবদ্ধতা ও launch gate

- একটিমাত্র approved flat delivery charge; district-wise courier rate integration নেই।
- Pending stock reservation auto-expire হয় না। Pending abandoned orders নিয়মিত দেখে Cancelled করুন।
- Cancelled/Returned stock একবার ফিরিয়ে দেয়। বাস্তব Returned পণ্য ক্ষতিগ্রস্ত হলে stock নিজে সংশোধন করুন; warehouse inspection/quarantine flow এখনো নেই।
- Offer price product-এ admin নির্ধারিত; coupon engine বা customer-নির্বাচিত discount নেই। Order discount বর্তমানে ০, ইচ্ছামতো client discount নেওয়া হয় না।
- Reports client-side filtered admin database data; বড় ডেটাসেটে server aggregation/pagination/time-zone accounting যোগ করতে হবে।
- IP rate limit distributed database-এ থাকে; hosting gateway যে forwarded IP header overwrite করে, staging-এ যাচাই করুন। CORS নিজে authentication বা anti-bot নয়। Bot protection/CAPTCHA/WAF এবং legitimate customer-এর mobile carrier shared IP effects review করে production চালু করুন।
- Query/Edge/Auth/Storage বাস্তব project-এ staging checklist পাস না করে গ্রাহকের তথ্য নেবেন না।
