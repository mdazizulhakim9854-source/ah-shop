# AH SHOP v2 — আপনার ব্যক্তিগত dashboard, নতুন payment checkout ও Android app

আপনার দেওয়া দুইটি ছবির মতো payment selection flow তৈরি হয়েছে, কিন্তু অন্য দোকানের PayStation account/logo/invoice/দাম কপি করা হয়নি। মূল AH SHOP-এর navy/purple design বজায় রাখা হয়েছে।

## কী কী বদলেছে

- বড় selectable **Pay full amount online** ও **Cash on Delivery** card।
- Mobile-banking/card badges, actual subtotal, approved delivery, approved online discount ও final total।
- সংযোগ না থাকলে স্পষ্ট **merchant gateway যুক্ত হয়নি**; online submit বন্ধ। নকল gateway বা টাকা গ্রহণের অভিনয় নেই।
- Customer-এর header/footer/menu থেকে admin link সরানো হয়েছে।
- Owner dashboard থেকে banner title/description, accent color, পণ্য, মূল্য, discount, stock, featured/pinned position, review moderation, delivery/payment/policies পরিবর্তন করা যাবে।
- **ওপরে রাখুন / Top** action: পছন্দের পণ্য প্রথমে; একই পণ্য home hero-তেও দেখাবে। Featured ও numeric display priority সম্পাদনা করা যায়।
- Discount percentage প্রকৃত `compare_at` ও `price` থেকে গণনা, কখনো বানানো শতাংশ নয়। UI conservative floor percentage দেখায়; final price-ই মূল হিসাব।
- ৩টি **Sample review, বাস্তব রিভিউ নয়** layout example। বাস্তব rating average/count থেকে এগুলো বাদ।
- Delivered order + matching phone + purchased product দিয়ে real review submission, তারপর moderation। Public view-তে order ID/phone/address নেই।
- Capacitor Android project, নিজস্ব AH SHOP icon/splash, API 36 target, build workflow; actual compiled unsigned AAB ও sample debug APK।

## এখনই ফোনে দেখুন

1. Arena-এর **AH SHOP — Updated checkout & storefront** preview খুলুন।
2. Sample product ব্যাগে → Checkout → online card বেছে design দেখুন। Merchant যুক্ত না থাকায় online order/টাকা নেওয়া বন্ধ।
3. COD বেছে কেবল Sample তথ্য দিয়ে demo order পরীক্ষা করতে পারবেন।
4. Owner demo দেখার জন্য preview URL-এর শেষে `/#/admin` লিখুন। Public menu-তে link নেই।
5. **Demo admin খুলুন** → Products-এর **Top** → storefront-এ ফিরে প্রথম পণ্য দেখুন।
6. Settings → home banner/accent color পরিবর্তন → Save।
7. Reviews → Sample review Approve/Reject করে দেখুন। Fake real reviews যোগ করার form নেই।

> Demo admin আপনার বাস্তব ব্যক্তিগত admin নয়; কোনো password security নেই, শুধু একই ডিভাইসের sample data। আসল access-এর জন্য নিচের Supabase setup আবশ্যক। আপনি বলেছেন এখন আগে code update, account সংযোগ পরে—সেই অনুযায়ী কোনো cloud account পরিবর্তন করা হয়নি।

## শুধু আপনার জন্য বাস্তব admin

**URL লুকানো ≠ নিরাপত্তা।** যে কেউ login URL আন্দাজ করতে পারেন, কিন্তু server-role ছাড়া admin data পাবেন না।

1. নিজের published HTTPS website/domain এবং Supabase project বেছে নিন। Backup নিন; আলাদা staging project ভালো।
2. আগের AH SHOP v1 schema যদি আগে deploy করে থাকেন: শুধু নতুন `002_owner_payments_reviews.sql` চালান।
3. একদম নতুন project হলে **প্রথমে 001, পরে 002**। আপনার বিদ্যমান database অন্য structure-এর হলে না বুঝে paste করবেন না; migration review লাগবে।
4. v2-তে `one_shop_owner` unique index সর্বোচ্চ একটি `admin_roles` row অনুমোদন করে। আগে একাধিক admin থাকলে migration থামবে; কাউকে গোপনে মুছে দেবে না। Authorized project owner আগে existing roles review করবেন।
5. Supabase Auth → Users-এ নিজের email/password দিয়ে user তৈরি করুন। Default admin/password নেই।
6. নিজের actual Auth UUID দিয়ে SQL Editor-এ role দিন:

```sql
-- নির্দেশক placeholder। YOUR_ACTUAL_AUTH_USER_UUID নিজের প্রকৃত UUID দিয়ে প্রতিস্থাপন করুন।
insert into public.admin_roles(user_id) values('YOUR_ACTUAL_AUTH_USER_UUID'::uuid);
```

7. Public signup প্রয়োজন না হলে বন্ধ করুন; অন্য user নিজে admin role লিখতে পারবেন না।
8. Frontend-এর দুইটি public Supabase env বসিয়ে rebuild করুন। Service-role key frontend-এ নয়।
9. `https://আপনার-নিজস্ব-site/#/admin` bookmark করুন। নিজের email/password ছাড়া admin contents দেখা যাবে না; RLS ও SQL privileges enforcement করে।
10. Non-admin/anonymous browser দিয়ে orders/customers/stock-write পরীক্ষা করুন। Single owner হলেও Supabase project owner's account security/MFA অপরিহার্য। App-এর নিজস্ব TOTP challenge flow এই iteration-এ নেই।

একবার setup হয়ে গেলে ফোন থেকে ছোট পরিবর্তন সহজে করা যাবে। নতুন account, merchant approval ও Play Store setup এক মিনিটে শেষ হবে—এমন প্রতিশ্রুতি নয়।

## Discount এবং product placement

### পণ্যের discount

- Admin → Product edit → current price এবং প্রকৃত previous price দিন। Previous price বেশি হলে discount badge দেখাবে।
- সূত্র: `(previous − current) ÷ previous × 100`। Decimal percentage floor করে display; ক্রেতা checkout-এ actual current price দেবেন।
- Previous price আসলে প্রযোজ্য ছিল না এমন inflated price লিখবেন না। Sample price হলে Sample flag রাখুন।

### Online discount

- Default **০%**। আপনার অনুমোদন ছাড়া extra discount চালু হয়নি।
- Settings → approved online discount ০–৫০%, দুই দশমিক পর্যন্ত। শুধু ONLINE-এর product subtotal-এ; delivery-তে নয়।
- UI savings/total পরিবর্তন করবে; SQL একই discount নিজে হিসাব করে client-এর reviewed amount মেলাবে।
- Gateway unavailable থাকলে total শুধু preview; টাকা বা live order নেওয়া হবে না।

### ওপরে রাখা

- Products → **Top** চাপুন: featured=true ও প্রথম display priority।
- আরও নিয়ন্ত্রণ: Edit → Featured checkbox + ছোট numeric priority আগে।
- Unpin করতে checkbox off করুন। Customer price-based sorting দিলে সেই পছন্দ মানা হবে; default sort-এ owner priority।

## SSLCOMMERZ — প্রস্তাবিত gateway, এখনো account/টাকা চালু নয়

এটি একটি প্রস্তাবিত connector, “সবার জন্য সবচেয়ে ভালো” নিশ্চয়তা নয়। Current official documentation: https://developer.sslcommerz.com/doc/v4/ । Signup-এর আগে আপনার ব্যবসার eligibility, permitted channels, settlement/refund terms, onboarding fee, transaction fee ও IP/network requirements provider-এর কাছ থেকে লিখিতভাবে যাচাই করুন। এখানে কোনো fee amount বানানো হয়নি এবং subscription কেনা হয়নি।

### Setup

1. নিজের নামে/ব্যবসার নামে approved merchant ও sandbox access নিন। PayStation screenshot-এর credentials ব্যবহার করা হয়নি।
2. আগের চারটি Edge Function-এর পাশাপাশি deploy করুন:

```bash
npx supabase functions deploy payment-config
npx supabase functions deploy payment-init
npx supabase functions deploy payment-notify
npx supabase functions deploy submit-review
# create-order-ও নতুন হয়েছে:
npx supabase functions deploy create-order
```

3. Supabase Edge Secrets-এ নিজের value দিন; চ্যাটে/source-এ নয়:

| Secret | কী দেবেন |
|---|---|
| `SSL_STORE_ID` | নিজের অনুমোদিত store ID |
| `SSL_STORE_PASSWORD` | নিজের store API password |
| `SSL_MODE` | প্রথমে `sandbox`; provider approval ও tests শেষে `live` |
| `PAYMENT_TOKEN_SECRET` | password manager দিয়ে তৈরি শক্ত random secret, কমপক্ষে ৩২ character |
| `PUBLIC_SITE_URL` | নিজের actual public HTTPS website URL; redirect destination |
| `SITE_ORIGINS` | নিজের website origin; Android app-এর জন্য ইচ্ছাকৃতভাবে `https://localhost`-ও যোগ করতে হবে |
| `RATE_LIMIT_SALT` | আগের server-side random secret |

4. Admin Settings → online payment request enable করুন। Approved delivery charge ও discount নির্ধারণ করুন। শুধু checkbox দিলেই হবে না; server secret/URL/model readiness নয়, payment readiness checker নিজের gateway config যাচাই করে।
5. Provider merchant panel-এ IPN URL:

```text
https://YOUR_PROJECT_REF.supabase.co/functions/v1/payment-notify
```

এটি placeholder। নিজের project ref ব্যবহার করুন। Success/fail/cancel URLs server session request-এ দেয়।

6. Supabase hosted Edge Function-এর outbound network/static egress আপনার merchant account-এর IP whitelist policy-এর সঙ্গে কাজ করে কি না sandbox-এ নিশ্চিত করুন। Static egress বাধ্যতামূলক হলে আলাদা approved backend/network লাগতে পারে; free hosting কাজ করবেই—এমন দাবি নয়।
7. New ONLINE checkout-এ gateway-এর জন্য actual email ও postcode দরকার। Fake email/address server বসায় না।
8. Cart/order SQL দিয়ে save → short-lived order-bound HMAC token → gateway session → approved official HTTPS hosted URL। App-এ native browser tab, website-এ redirect। PIN/OTP/card CVV কেবল provider-এর নিজস্ব page-এ; AH SHOP field নেই।
9. IPN বা browser return-এর `status=VALID` বিশ্বাস করা হয় না। Server credentials দিয়ে official Order Validation API-তে আবার যাচাই: transaction ID, amount, BDT currency, environment, provider validity ও risk level।
10. Unique transaction/validation IDs, locked DB updates ও repeated callback idempotency আছে। Failed/cancelled URL নিজে order/payment status বদলাতে পারে না।
11. Risk/duplicate payment/cancelled order-এ late payment হলে **Review**; admin তদন্ত করবেন। Automatic refund দেওয়া হয়নি।
12. **Sandbox verified কখনো Paid নয়**, এবং sandbox order Delivered sales value-তে গণনা হয় না। Online payment manual admin Paid button দিয়ে bypass করা যায় না।

### কী এখনো পরীক্ষা হয়নি

Code type-check এবং local database/token tests পাস করেছে; কিন্তু আপনার actual sandbox/store API call, merchant-approved channels, app-to-wallet return, real callbacks, live settlement বা refunds পরীক্ষা হয়নি। অপ্রচলিত API/contract পরিবর্তন merchant documentation অনুযায়ী adjust করতে হতে পারে। Production-ready বলে দাবি করা হচ্ছে না।

Payment token ৩০ মিনিটের। Page reload/app process termination-এ token হারাতে পারে; order ID device-এ থাকে এবং tracking করা যায়। Checkout session recovery/OTP-authorized retry আলাদা কাজ; নতুন duplicate order না করে human support ব্যবহার করুন।

## Review policy

- Customer শুধু Delivered purchase থেকে submit করতে পারবেন; matching ID/phone লাগবে।
- এক order/product-এর এক review। Name/body/rating যাচাই, server rate limit, default Pending।
- Owner Approve/Reject করেন; বাস্তব feedback-এর body/rating admin form থেকে পাল্টানোর ব্যবস্থা নেই।
- Public projection-এ order ID/customer phone নেই। Author-এর chosen public name/body দেখাবে; moderation-এ accidental PII সরানোর জন্য reject/request resubmission করুন।
- “Delivered order checked” মানে database purchase match; SMS identity/KYC verification নয়।
- Test/sandbox reviews Sample; actual average/count থেকে বাদ। Demo-র positive stars বাস্তব customer rating হিসেবে ব্যবহার করা যাবে না।
- Full dispute/appeal, reviewer edit/delete ও content-abuse tooling এখনো নেই। নিরপেক্ষ moderation policy প্রকাশ করুন।

## Android APK বনাম AAB — আপনার ফাইল

### `AH-SHOP-Sample-Test.apk`

- আসল compiled Android **debug-signed APK**, bundled Sample app।
- নিজের ফোনে পরীক্ষার জন্য; Play Store release নয়। Payment credentials/database env এতে নেই।
- Download করে Android Files থেকে খুলতে পারেন। Install source permission লাগলে শুধু নিজের বিশ্বস্ত test file-এর জন্য দিন; warning বুঝে না নিয়ে নিরাপত্তা ব্যবস্থা বন্ধ করবেন না। পরীক্ষা শেষে permission off করুন।
- একই package-এর অন্য signing key-র app থাকলে আগে sample app uninstall লাগতে পারে; local demo data হারাবে। বাস্তব গ্রাহকের তথ্য দেবেন না।
- Physical Android device-এ পরীক্ষা আমরা করিনি। Payment handoff, keyboard/back button, low-memory process restart ও accessibility নিজে পরীক্ষা করুন।

### `AH-SHOP-Sample-Unsigned.aab`

- আসল compiled **unsigned Android App Bundle**। APK-এর মতো সরাসরি install করা যায় না।
- **এখন Play Console upload-ready নয়।** নিজের স্থায়ী upload key দিয়ে sign করে আবার build করুন; এখানে আপনার হয়ে production key বানানো/মালিকানা নেওয়া হয়নি।
- Current proposed application ID `com.ahshop.store`, versionCode 1, targetSdk 36, minSdk 23। এটি নিবন্ধিত/আপনার জন্য reserved ID নয়। প্রথম upload-এর আগে নিজের unique package ID নিশ্চিত করুন; পরে package identity পরিবর্তন করা যায় না।
- Source-এর `android/`, `capacitor.config.ts`, `scripts/build-android.sh` এবং `.github/workflows/android-aab.yml` দিয়ে নতুন bundle তৈরি করবেন।

### ফোন দিয়েই cloud build / signed AAB

1. Browser-based Linux workspace-এ project খুলুন। Website-এর code ও `.github/` **repository root**-এ রাখুন, শুধু ZIP বা nested `ah-shop/.github` রাখলে workflow দেখা যাবে না।
2. Java 21 + Android SDK platform 36 ব্যবহার করুন। Workflow-এ এগুলো setup করা আছে। Account/CI quota ও billing terms আগে দেখুন; auto-publish নেই।
3. Repo Actions → **Build AH SHOP Android bundle** → Run workflow। Default unsigned AAB ও debug APK artifacts পাবেন।
4. Production app-এ public Supabase values চাইলে repository **Variables**-এ `VITE_SUPABASE_URL` ও `VITE_SUPABASE_ANON_KEY` দিন। এগুলো public build config; service-role/merchant key এখানে নয়।
5. নিজের upload keystore তৈরি/ব্যবস্থাপনার জন্য trusted secure environment ও password manager ব্যবহার করুন। Existing app থাকলে তার approved upload key-ই লাগবে। Key/password chat/public repo-এ দেবেন না।
6. Repo encrypted **Secrets**:
   - `ANDROID_KEYSTORE_BASE64`: নিজের upload `.jks` file-এর base64।
   - `ANDROID_KEYSTORE_PASSWORD`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`
7. Workflow temporary key file বানিয়ে sign করবে; শেষে temporary file মুছবে। চারটি signing value অসম্পূর্ণ হলে build থামবে। সব অনুপস্থিত হলে unsigned—এই পার্থক্য নিজে signature check করে নিশ্চিত করুন।
8. Private workflow logs/artifacts access সীমিত করুন। CI/keystore compromise হলে provider/Play recovery process অনুসরণ করুন।
9. New signed build, নিজের actual backend/policies/catalog দিয়ে test tracks-এ দিন। Demo/sample build public commerce app হিসেবে publish করবেন না।

### Play Store-এর প্রয়োজনীয়তা ও খরচ

২৯ অক্টোবর ২০২৬-এ official documentation যাচাই:

- Developer account-এর এককালীন **US$25 registration fee**; local card acceptance/tax/FX আলাদা হতে পারে। https://support.google.com/googleplay/android-developer/answer/6112435
- ১৩ নভেম্বর ২০২৩-এর পরে তৈরি personal account-এ production access-এর আগে অন্তত **১২ opted-in tester, টানা ১৪ দিন** closed testing দরকার। Identity/device verification-ও প্রযোজ্য হতে পারে। https://support.google.com/googleplay/android-developer/answer/14151465
- বর্তমান নতুন app submission target **API 36** requirement অনুযায়ী project সেট করা হয়েছে; upload-এর দিন আবার যাচাই করুন। https://developer.android.com/google/play/requirements/target-sdk
- Privacy policy public URL, accurate Data safety declaration (orders, phone/address/email, reviews, payment processor, optional AI), content rating, app access instructions, support contact, screenshots/icon/store listing লাগবে। Customer account creation বর্তমানে নেই; ভবিষ্যতে যোগ করলে account deletion requirements review করুন।
- Physical goods commerce-এর জন্য payment policy পড়ুন; digital goods যোগ করলে Play Billing-এর আলাদা নিয়ম প্রযোজ্য হতে পারে।
- App review/approval নিশ্চিত নয়। Minimum functionality, quality, commerce, payment, privacy ও content policy মানতে হবে। শুধু AAB file পেলেই Play Store-এ প্রকাশ হয়ে যায় না।

## পরীক্ষা — v2

- ৭টি browser suite: পাস।
- ৪২টি local PostgreSQL/PGlite assertion: পাস।
- ৫টি Deno token/URL/body-limit test: পাস।
- ৮টি Edge Function Deno type-check: পাস।
- Web production build: পাস।
- Android Gradle `bundleRelease` ও `assembleDebug`: সফল; unsigned bundle ও debug APK তৈরি। SDK metadata target 36 যাচাই।
- Actual merchant/API/live Supabase/physical Android/Play review: **এখনো যাচাই করা হয়নি**।

## পরবর্তী ছোট ধাপ

আগে APK/website-এ design ও product pinning দেখে নিন। এরপর নিজের Supabase admin role ও approved merchant sandbox setup করুন। Secret key এখানে পাঠাবেন না। Production activation ও store publication আলাদা অনুমোদন ও testing-এর কাজ।
