# Android ফোন থেকে দেখা, চালানো ও প্রকাশ

> **v2 আপডেট:** checkout, private owner access, pinning, moderated reviews, SSLCOMMERZ connector ও Android AAB/APK এখন যোগ হয়েছে। বর্তমান নির্দেশনা: [v2 guide](V2-OWNER-PAYMENT-APP.md)। নিচের v1 baseline-এর পুরোনো ‘এখনো নেই’ বক্তব্যের ক্ষেত্রে v2 guide অনুসরণ করুন।


কম্পিউটার দরকার নেই। Chrome, ফোনের Files app এবং browser-based cloud dashboard ব্যবহার করা যাবে। Dashboard ছোট দেখালে Chrome ⋮ → **Desktop site** চালু করুন। সেবার menu names বদলাতে পারে।

## পথ ১ — সবচেয়ে সহজ: প্রস্তুত static ZIP দিয়ে Sample শপ প্রকাশ

এই deliverable-এর `AH-SHOP-static-preview.zip` build করা frontend। এটি **Sample/demo**, বাস্তব business backend নয়।

1. ZIP ফোনের Downloads-এ রাখুন; source ZIP-এর সঙ্গে গুলিয়ে ফেলবেন না।
2. Cloudflare account তৈরি/লগইন করুন; শর্ত ও Free plan limits পড়ুন।
3. Dashboard → Workers & Pages → Create application → Pages → Direct Upload / Upload assets বেছে নিন।
4. নিজের project name দিন। নাম দখল হয়ে থাকলে নিজের মতো অন্য নাম দিন। কোনো domain পাওয়ার নিশ্চয়তা দেওয়া হচ্ছে না।
5. `AH-SHOP-static-preview.zip` upload করুন। ZIP-এর root-এ `index.html` এবং `assets/` আছে।
6. Deploy শেষে dashboard-এ আপনার প্রকৃত **`https://<project>.pages.dev`** URL দেখা যাবে। এই placeholder বাস্তব প্রকাশিত URL নয়।
7. Chrome incognito-তে URL খুলে পণ্য → ব্যাগ → demo checkout পরীক্ষা করুন।
8. Demo admin থেকে sample content বদলানো শুধু নিজের ফোনের localStorage বদলাবে; অন্য visitor তা দেখবেন না। সবার জন্য পণ্য বদলাতে backend লাগবে।

**এই Arena preview একটি অস্থায়ী development preview, স্থায়ী public deployment নয়।** উপরের ধাপে deploy করলে নিজের account-এ published URL পাবেন।

## পথ ২ — source code edit, Supabase যুক্ত এবং rebuild (শুধু Android browser)

একটি ব্যবহারযোগ্য browser-based Linux workspace হলো GitHub Codespaces। quota/payment terms আগে দেখুন; billable usage চালু করার দরকার নেই। এটি ঐচ্ছিক developer environment, দোকানের hosting নয়।

1. `AH-SHOP-source.zip` ফোনে download করুন।
2. নিজের GitHub account-এ private repository তৈরি করুন, যেমন নিজের পছন্দের project name। Add README দিন।
3. Desktop site-এ repository → Add file → Upload files → source ZIP upload → Commit।
4. Code → Codespaces → Create codespace। আপনার plan-এ সুবিধাটি না থাকলে অন্য browser IDE বা সহায়তাকারীর Linux environment ব্যবহার করুন।
5. Editor-এর Terminal খুলুন। repository-তে ZIP থাকলে:

```bash
unzip AH-SHOP-source.zip
cd ah-shop
npm ci
npm run dev -- --port 5173
```

6. Ports panel → 5173 → Open in browser। Code editor নয়, port preview-তে website দেখবেন। নিজের workspace access private রাখুন।
7. `src/` ফাইল পরিবর্তন করে save করলে preview update হবে। Bangla font bundle-এর অংশ।
8. Supabase চাইলে পরের guide অনুযায়ী `.env.local` তৈরি করুন। শুধু public URL ও anon/publishable key বসবে:

```env
VITE_SUPABASE_URL=আপনার-প্রকৃত-project-url
VITE_SUPABASE_ANON_KEY=আপনার-প্রকৃত-public-anon-key
```

এই লাইনগুলো নির্দেশক; বাংলা placeholder রেখে build করবেন না। ফাইলে secret service-role key দেবেন না। পরিবর্তনের পরে dev server restart করুন।

9. Production build:

```bash
npm run build
cd dist
zip -r ../AH-SHOP-live-build.zip .
cd ..
```

10. Codespaces file explorer-এ ZIP → Download। ফোন থেকে Pages dashboard-এ নতুন deployment upload করুন। `.env.local`-সহ source কখনো public ZIP করবেন না।
11. Public Vite env build-time-এ JS-এ থাকে। build হওয়ার পরে dashboard env বদলালে পুরোনো ZIP বদলায় না; rebuild দরকার।

> Source upload-এর ZIP বড় লাগলে Files app দিয়ে extract করে নিজের পছন্দের private git workflow-ও ব্যবহার করতে পারেন। মোবাইল git/editor অ্যাপ অপরিহার্য নয়। Secret token লিখে terminal history/screenshot-এ রাখবেন না; workspace encrypted secrets ব্যবহার করুন।

## ঐচ্ছিক — Vercel

- Source folder repo-তে রাখুন, শুধু ZIP রেখে Vercel import করলে build হবে না। Codespaces-এ extract করা folder-কে repo root বা configured Root Directory করুন; `node_modules`, `dist`, `.env.local` commit করবেন না।
- Import project → Framework: Vite → Build `npm run build` → Output `dist`। Node 20.19+ বা নতুন compatible LTS।
- Environment-এ শুধু দুইটি `VITE_SUPABASE_…` public value দিন; পরে Redeploy।
- **Hobby personal/non-commercial**। Sample personal prototype-এর terms মেনে ব্যবহার করুন; actual দোকানের জন্য appropriate commercial plan/host লাগবে।
- `vercel.json` routing এবং basic security headers দেয়।

## Custom domain পরে যুক্ত করা

1. Domain আগে থেকেই আপনার হলে hosting dashboard → Custom domains / Domains → Add domain। না থাকলে registrar থেকে কিনতে খরচ হবে।
2. Dashboard যে DNS record/nameserver দেখায় সেটিই registrar-এ বসান; অনুমান করে IP দেবেন না।
3. DNS verification + HTTPS certificate ready হওয়া পর্যন্ত অপেক্ষা করুন।
4. Supabase Auth URL settings-এ নিজের HTTPS site URL যোগ করুন।
5. Edge Function `SITE_ORIGINS`-এ ঠিক এই origin যোগ করুন, শেষে `/` ছাড়া। `www` হলে সেটিও আলাদা origin।
6. সব functions redeploy করুন যদি provider secret reload-এর জন্য দরকার হয়। Incognito-তে cart/checkout/admin/tracking পরীক্ষা করুন।
7. ভবিষ্যতে custom Supabase domain ব্যবহার করলে `public/_headers`-এর `connect-src` ও `img-src` update করতে হবে।

## প্রতিদিন মোবাইল থেকে পরিচালনা

- নিজের published URL → bookmark `/#/admin` → নিজের email/password।
- পণ্য/ক্যাটাগরি যোগ, স্টক সংশোধন, active/inactive ও offer edit।
- Orders-এ বিস্তারিত দেখে phone/address অনুযায়ী fulfillment করুন; manual payment verify না করে Paid করবেন না।
- Status transition ক্রমানুসারে: Pending → Confirmed → Processing → Shipped → Delivered।
- Pending/Confirmed/Processing → Cancelled; Shipped/Delivered → Returned। শেষ দুইটি terminal; পুনরায় active করা হয় না।
- CSV report download; Delivered value-তে delivery charge আছে, profit নয়। UTC date filtering মনে রাখুন।
- Settings-এ approved flat delivery, WhatsApp নম্বর, policies update। কোনো API secret নয়।
- Shared phone ব্যবহার করলে শেষে Logout এবং browser lock ব্যবহার করুন।

## সাধারণ সমস্যা

| সমস্যা | করণীয় |
|---|---|
| Preview সাদা | browser refresh; dev terminal-এর error দেখুন; `npm ci` শেষে server restart |
| Backend দিলে catalog খালি | স্বাভাবিক: production database-এ Sample seed নেই। Admin দিয়ে categories/products যোগ করুন |
| Admin role নেই | Auth user তৈরি করাই যথেষ্ট নয়; BACKEND-SETUP অনুযায়ী role grant করুন |
| Checkout ব্যর্থ | approved delivery charge, active/non-Sample stock, changed price, function deployment, CORS যাচাই |
| WhatsApp খোলে না | নিজের valid `8801XXXXXXXXX` নম্বর দিন; browser popup অনুমতি ও WhatsApp install দেখুন |
| Demo order অন্য ফোনে নেই | local demo; Supabase সংযোগ ছাড়া device sync নেই |
| Cloudflare ZIP-এ পেজ নেই | root-এ index.html আছে কি দেখুন; source ZIP নয়, build ZIP upload করুন |
| Storage upload ব্যর্থ | upload-image function deploy, authentication, admin role ও bucket যাচাই |
| Free backend ঘুমিয়ে গেছে | provider dashboard-এ resume করুন; Free plan uptime guarantee নয় |
