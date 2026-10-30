# AH SHOP v2 — নতুন checkout, owner dashboard ও Android app

**বর্তমান নির্দেশিকা:** [ব্যক্তিগত admin, payment ও APK/AAB setup](docs/V2-OWNER-PAYMENT-APP.md)

আপনার reference screenshot অনুযায়ী online/COD payment selection, SSLCOMMERZ connector code, single-owner role limit, customer menu থেকে admin link অপসারণ, featured/pin-to-top, approved discounts, banner/accent customization এবং moderated purchase-linked reviews যোগ হয়েছে। তিনটি Sample review বাস্তব rating average-এ গণনা হয় না।

- Owner URL bookmark: `/#/admin` — customer menu-তে নেই; বাস্তব নিরাপত্তা Supabase Auth/RLS-এর।
- Migration: নতুন project-এ 001 → 002; আগের AH SHOP schema থাকলে backup নিয়ে শুধু 002। অন্য schema হলে আগে review।
- Online gateway activation এখনো হয়নি; credentials ছাড়া online submit বন্ধ। Sandbox result বাস্তব Paid নয়।
- Actual Android artifacts: Sample debug APK এবং **unsigned** AAB। নিজের upload key দিয়ে sign করার আগে AAB Play Console-ready নয়।
- Tests: ৭ browser suites, ৪২ local PG checks, ৫ Deno security tests, ৮ Edge Function type-checks; web ও Android builds পাস। Actual merchant/cloud/physical-device পরীক্ষা বাকি।

> নিচের অংশ v1 baseline documentation। বর্তমান activation/status-এর ক্ষেত্রে উপরের v2 guide প্রাধান্য পাবে। নিজের Supabase বা merchant account-এ কোনো পরিবর্তন করা হয়নি; আপনি আগে code update চেয়েছেন।

---

# AH SHOP — শুরু করুন এখান থেকে

**বাংলাদেশের জন্য mobile-first e-commerce prototype + deployable backend foundation**  
প্রস্তুতের তারিখ: ২৯ অক্টোবর ২০২৬

> **এটি এখনো production shop নয়।** Live preview-তে Sample পণ্য, Sample মূল্য এবং browser-local demo order আছে। বাস্তব ব্যবসার ফোন, ঠিকানা, ডেলিভারি চার্জ, AI key বা merchant credentials বসানো হয়নি। Demo-তে বাস্তব গ্রাহকের তথ্য দেবেন না।

## আপনার জন্য কী তৈরি করা হয়েছে

- প্রিমিয়াম navy, white ও soft-purple ডিজাইন; Android ছোট স্ক্রিন, Unicode বাংলা, মূল storefront-এর English toggle, light/dark mode।
- Home, catalog, categories, product details, search, budget/category/stock filters, sorting, wishlist।
- স্থায়ী local cart; quantity, stock guard, remove এবং মোটের হিসাব।
- Customer details → সম্পূর্ণ order summary → checkbox-এ স্পষ্ট সম্মতি → submit।
- COD; অনুমোদিত নির্দেশনা থাকলে manual bKash/Nagad Transaction ID। **ID দিলেই Paid নয়।**
- Admin: product/category CRUD, image upload, offer price, active/inactive, inventory, order status, manual payment verification, database-derived reports ও CSV।
- অনুমোদিত WhatsApp নম্বর থেকে click-to-chat message: items, quantities, subtotal, delivery, discount, total, saved ID। **ক্রেতাকে নিজে Send চাপতে হবে।**
- সৎভাবে চিহ্নিত rule-based support chat; server-side AI intent classifier-এর সংযোগ কোড। AI-এর বানানো free-form ব্যবসায়িক উত্তর দেখানো হয় না।
- Order ID + phone দিয়ে শুধু নিজের status lookup; tracking-এ নাম/ঠিকানা/ফোন প্রকাশ করা হয় না।
- Support, contact, about ও policy পেজ। অনুমোদিত policy না থাকলে “প্রকাশের অপেক্ষায়”—আইনি শর্ত বানানো হয়নি।

## এখনই ফোন থেকে পরীক্ষা করুন

Arena-এর **AH SHOP — Live storefront** preview খুলুন।

1. একটি Sample পণ্যের **+** চাপুন।
2. **আমার ব্যাগ** → quantity পরিবর্তন করে দেখুন।
3. **চেকআউট** → শুধুই পরীক্ষামূলক তথ্য দিন।
4. **সারাংশ যাচাই** → সম্মতির checkbox → **Demo অর্ডার সংরক্ষণ**।
5. পাওয়া `DEMO-…` ID ও একই test phone দিয়ে tracking করুন।
6. নিজের bookmark `/#/admin` → **Demo admin খুলুন**।
7. পণ্য যোগ/সম্পাদনা, স্টক, অর্ডার, CSV ও শপ সেটিংস পরীক্ষা করুন।

Demo admin কোনো নিরাপদ login নয়। আপনার ব্রাউজারের data সবাইকে প্রকাশ করছে না, কিন্তু একই ডিভাইসের অন্য ব্যবহারকারী দেখতে পারবেন। ব্রাউজারের data মুছলে demo orders/settings হারাবে।

## কোনটি বাস্তব, কোনটি demo?

| অংশ | বর্তমান preview | Supabase setup-এর পরে |
|---|---|---|
| Responsive UI, search/filter, cart, wishlist | কার্যকর | কার্যকর |
| পণ্য ও দাম | স্পষ্ট Sample | আপনার অনুমোদিত আসল catalog; Sample flag আলাদা |
| Checkout | demo order, localStorage | transactional database order, stock lock, immutable price snapshot |
| Order ID | `DEMO-` + UUID; একই ব্রাউজারে | PostgreSQL-generated UUID |
| Delivery | নির্ধারিত নয়; demo হিসাবের ৳০ বাস্তব চার্জ নয় | admin-approved flat charge; না দিলে server অর্ডার নেবে না |
| Admin | খোলামেলা demo workspace | Supabase Auth + server-enforced admin role + RLS |
| Images | local demo image, 1 MB সীমা | authenticated Edge upload + signatures/MIME/3 MB + Storage |
| Tracking | local test lookup | server-side UUID + normalized phone match, rate limit, no PII |
| WhatsApp click-to-chat | নম্বর না দিলে blocked + message | অনুমোদিত নম্বর দিলে কার্যকর |
| Incoming WhatsApp chatbot | **নেই** | official integration এখনো তৈরি/অনুমোদন করতে হবে |
| Chat | **Rule-based demo, AI নয়** | key/model/consent থাকলে bounded AI intent parsing; অন্যথায় labeled fallback |
| bKash/Nagad | নির্দেশনা না দিলে বন্ধ | manual verification only; Merchant API এখনো নেই |
| Policies/about/contact | তথ্য নেই বলে স্পষ্ট notice | admin-approved text প্রকাশ হবে |
| Dashboard sales | local demo orders থেকে গণনা; Sample label | database orders থেকে গণনা; Delivered order value, profit নয় |
| Permanent deployment/custom domain | করা হয়নি | আপনার account থেকে করতে হবে |

**পূর্ণ স্বয়ংক্রিয় E-commerce Agent তৈরি/চালু হয়েছে—এমন দাবি করা হচ্ছে না।** AI ক্রেতার হয়ে অনুমতি ছাড়া cart পরিবর্তন, payment, order confirmation বা refund করতে পারে না। কথোপকথন থেকে customer form স্বয়ংক্রিয়ভাবে পূরণ করে না; নিরাপদ checkout-এ পাঠায়।

## ফাইল এবং নির্দেশিকা

```text
ah-shop/
├── src/
│   ├── main.tsx          # React boot + bundled Bengali font
│   ├── App.tsx           # storefront, cart, checkout, tracking, support
│   ├── Admin.tsx         # mobile admin + live/demo repositories
│   ├── Art.tsx           # local SVG sample product illustrations
│   ├── data.ts           # marked sample catalog + empty business settings
│   ├── api.ts            # optional Supabase connection
│   ├── types.ts
│   └── styles.css        # responsive design + dark mode
├── public/               # icon + Cloudflare security headers
├── supabase/
│   ├── config.toml
│   ├── migrations/001_secure_shop.sql
│   └── functions/
│       ├── _shared/http.ts
│       ├── create-order/index.ts
│       ├── track-order/index.ts
│       ├── ai-support/index.ts
│       └── upload-image/index.ts
├── integrations/contracts.ts  # future official API boundaries; not implementations
├── tests/shop.spec.ts
├── tests/database.mjs
├── docs/ANDROID-GUIDE.md
├── docs/BACKEND-SETUP.md
├── docs/AI-WHATSAPP-PAYMENTS.md
├── docs/TESTING-AND-SECURITY.md
├── docs/STATUS.md
├── .env.example
├── package.json + package-lock.json
├── vite.config.ts + tsconfig.json
├── playwright.config.ts
├── vercel.json
└── README.md
```

### কোন ফাইল খুলবেন?

- **ফোনে প্রকাশ:** [Android নির্দেশিকা](docs/ANDROID-GUIDE.md)
- **Database, secure admin login:** [Backend setup](docs/BACKEND-SETUP.md)
- **AI, WhatsApp, payments:** [Integration নির্দেশিকা](docs/AI-WHATSAPP-PAYMENTS.md)
- **পরীক্ষা, backup, launch gate:** [Testing & security](docs/TESTING-AND-SECURITY.md)
- **Phase অনুযায়ী অসম্পূর্ণ কাজ:** [Implementation status](docs/STATUS.md)

## Developer commands — Android browser-এর Codespaces terminal-এও চলবে

```bash
npm ci
npm run dev -- --port 5173
# আলাদা terminal:
npm run build
npm run test:db
npx playwright install --with-deps chromium
npm test
```

Node 20.19+ বা সামঞ্জস্যপূর্ণ নতুন LTS ব্যবহার করুন। React + TypeScript + Vite; CSS নিজস্ব, Tailwind dependency দরকার নেই। Font স্থানীয় bundle-এ আছে; Google Fonts/CDN লাগে না। Routing hash-based (`/#/products`) যাতে static hosting সহজ হয়। Cart localStorage-এ থাকে; offline order sync নেই।

## খরচ ও সীমা — “আজীবন ফ্রি” নয়

২৯ অক্টোবর ২০২৬-এ official documentation যাচাই করা হয়েছে; signup করার সময় আবার দেখবেন।

- **Supabase Free:** 500 MB database, 1 GB file storage, 5 GB egress; 2 active project; ১ সপ্তাহ inactivity-তে project pause হতে পারে। এটি uptime বা backup guarantee নয়। [Official pricing](https://supabase.com/pricing)
- **Vercel Hobby:** non-commercial personal use only। বাস্তব AH SHOP business-এর জন্য Hobby-কে বিনামূল্যের commercial hosting ধরে নেবেন না; উপযুক্ত paid plan/host বেছে নিন। [Official Hobby rules](https://vercel.com/docs/plans/hobby)
- **Cloudflare Pages Free:** এই static prototype-এর বিকল্প; official limits-এ মাসে 500 builds, 1 concurrent build, 20,000 files। ব্যবহারের terms ও account limits পুনরায় পড়ুন। [Official limits](https://developers.cloudflare.com/pages/platform/limits/)
- **AI:** provider/model অনুযায়ী API খরচ। নিজের spend limit দিন; এখানে কোনো free API credit ধরে নেওয়া হয়নি।
- **Official WhatsApp:** category ও recipient market অনুযায়ী delivered-message pricing; service messages-ও ২০২৬-এর পরিবর্তিত pricing-এর অধীন হতে পারে। পুরোনো “সব service reply free” ধারণা ব্যবহার করবেন না। Bangladesh rate card, monthly allowance এবং BSP fee activation-এর আগে দেখুন। [Meta pricing, updated Sep 30 2026](https://developers.facebook.com/documentation/business-messaging/whatsapp/pricing)
- **Domain, SMS OTP, merchant gateway, email service, paid backup** আলাদা খরচ হতে পারে। কোনো কেনাকাটা বা paid subscription করা হয়নি।

## পরীক্ষা সম্পর্কে সৎ বিবরণ

- Production frontend build: পাস।
- ৫টি Playwright end-to-end suite: পাস (catalog, checkout/consent/tracking, admin, 360px routes, chat)।
- ২৫টি local PostgreSQL/PGlite database check: পাস (RLS/privileges, validation, idempotency, price/stock, tracking privacy, status transitions, rate limiting)।
- ৪টি Supabase Edge Function: Deno type-check পাস।
- Dependency audit: পরীক্ষার সময় vulnerability পাওয়া যায়নি। এটি পূর্ণ security audit নয়।
- **যা পরীক্ষা করা হয়নি:** আপনার বাস্তব Supabase project/Auth/Storage gateway, cloud Edge CORS, AI provider response/billing, real WhatsApp sending, payment settlement, custom DNS এবং physical Android browser। ছোট স্ক্রিন Chromium emulation পরীক্ষা হয়েছে; Android device নয়।

**পরবর্তী বাস্তব ধাপ:** নিজের Supabase project এবং অনুমোদিত business information যুক্ত করে staging-এ checklist সম্পন্ন করুন। Secret/API key চ্যাটে বা public frontend-এ দেবেন না।
