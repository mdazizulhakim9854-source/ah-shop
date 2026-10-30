# AI, WhatsApp ও payment integration

> **v2 আপডেট:** checkout, private owner access, pinning, moderated reviews, SSLCOMMERZ connector ও Android AAB/APK এখন যোগ হয়েছে। বর্তমান নির্দেশনা: [v2 guide](V2-OWNER-PAYMENT-APP.md)। নিচের v1 baseline-এর পুরোনো ‘এখনো নেই’ বক্তব্যের ক্ষেত্রে v2 guide অনুসরণ করুন।


## A. বর্তমানে chat কী?

Preview-তে **Rule-based demo · Not AI**। এটি regex/keyword ও Sample catalog থেকে সহায়তা করে; কোনো AI API-তে প্রশ্ন যায় না। Live Supabase সংযুক্ত থাকলেও key/enable/model/consent না থাকলে backend rule-based mode স্পষ্ট দেখায়। Network failure-কে AI success বলা হয় না।

এটি full autonomous sales representative নয়। বর্তমানে checkout-এ প্রয়োজনীয় customer information ও explicit consent নেওয়া হয়। Agent নিজে order confirm, payment verify, discount edit বা tracking বানাতে পারে না।

## B. আসল AI কীভাবে যুক্ত করবেন

1. আগের guide অনুযায়ী Supabase schema এবং `ai-support` deploy করুন।
2. নিজের অনুমোদিত AI provider account তৈরি করুন; model compatibility ও token pricing আগে দেখুন। এই কোড JSON response mode-সহ OpenAI-compatible `POST /chat/completions` interface ব্যবহার করে। সব provider/model একরকম নয়।
3. Supabase Edge Secrets-এ `AI_API_KEY` রাখুন। শুধু server-side।
4. প্রয়োজন হলে `AI_API_URL`-এ provider-এর HTTPS full chat-completions endpoint দিন; এটি admin settings input নয়। default OpenAI endpoint কোডে আছে, API key নেই।
5. Admin → AI ও ইন্টিগ্রেশন → নিজের provider-এর **বাস্তব model ID** → enable → Save। কোনো model ID বা credit অনুমান করে বসানো হয়নি।
6. অতিরিক্ত business note-এ শুধু অনুমোদিত, প্রকাশযোগ্য তথ্য লিখুন। এটি business-info প্রশ্নে সরাসরি ব্যবহার হতে পারে; secret বা ব্যক্তিগত তথ্য নয়।
7. Website privacy notice-এ provider data processing/retention এবং customer consent আপনার বাস্তব আইনগত চাহিদা অনুযায়ী প্রকাশ করুন।
8. Chat-এর AI processing consent checkbox ব্যবহার করুন। সম্মতি ছাড়া provider call হবে না; সাধারণ সহায়তা fallback চলবে।
9. Billing cap, provider key restriction এবং alerts নিজের account-এ দিন। Request count limit token budget-এর বিকল্প নয়।
10. Staging-এ প্রশ্ন করুন: budget, product names, comparison, stock, delivery, payment, tracking, unknown question, human escalation, prompt injection। Mode label এবং provider usage logs যাচাই করুন।

### নিরাপদ উত্তর তৈরির কাঠামো

```text
Customer question + consent
  → rate-limited Edge Function
  → approved catalog read
  → AI classifies intent, budget and known product IDs (JSON only)
  → validate enum and IDs, discard model’s free-form text
  → deterministic response from database/settings
  → label mode: ai / rule-based
```

এটি ইচ্ছাকৃতভাবে সীমিত: AI-এর natural-language বোঝার ক্ষমতা ব্যবহার করা হয়, কিন্তু তার লিখে দেওয়া দাম, স্টক, payment confirmation, delivery promise বা order ID বিশ্বাস করা হয় না।

- Backend শুধুই active catalog read করে; suggestion-এ stock > 0; comparison-এ unavailable পণ্য থাকলে out-of-stock বলা হয়।
- Customer-order PII AI provider-এ database থেকে পাঠানো হয় না। শুধু সর্বশেষ user question ও catalog names পাঠানো হয়। user নিজে প্রশ্নে sensitive তথ্য দেবেন না।
- PIN/OTP/password mention হলে provider call-এর আগেই সতর্কতা দেয়। এটি সব ভাষার secret detection guarantee নয়।
- AI history থেকে order edit/write tools নেই। Budget/intent parsing ভুল হতে পারে; মানব সহায়তার পথ সবসময় আছে।
- বর্তমান AI catalog context সর্বোচ্চ ২০০ active product। বড় catalog-এ server-side search/retrieval যোগ করুন।
- অনুমোদিত English product name এবং প্রশ্নের ভাষা অনুযায়ী core agent reply বাংলা/English; descriptions/policies আপনার নিজস্ব content।

## C. WhatsApp Phase 1: click-to-chat

1. নিজের অনুমোদিত business WhatsApp নম্বর নিশ্চিত করুন।
2. Admin → শপ সেটিংস → `8801XXXXXXXXX` format-এ নিজের নম্বর দিন; `+`, space বা dash নয়। উদাহরণটি placeholder, ব্যবহারযোগ্য আসল নম্বর নয়।
3. Cart → WhatsApp-এ আলোচনা; অথবা saved order → WhatsApp মেসেজ প্রস্তুত।
4. Browser `wa.me` URL তৈরি করবে, text URL-encoded।
5. Message-এ items/quantity/line total/subtotal/delivery/discount/grand total থাকে; saved order থাকলে actual saved ID ও customer order details থাকে।
6. নম্বর না থাকলে স্পষ্ট warning। ডেলিভারি charge অজানা হলে “নিশ্চিত নয়”—০ বা free delivery বলা হয় না।
7. WhatsApp-এ খুলে **ক্রেতাকে নিজে Send** করতে হবে। Website জানতে পারে না তিনি পাঠিয়েছেন কি না। কোনো delivery/read receipt বা auto-confirmation তৈরি হয় না।
8. Admin অর্ডার দেখে যোগাযোগ ও payment যাচাই করে Confirmed করবেন।

Saved demo order-এর WhatsApp message-এ **SAMPLE / TEST ONLY** label থাকে। নমুনা তথ্যকে বাস্তব অর্ডার হিসেবে পাঠাবেন না।

## D. WhatsApp Phase 2: official Business Platform — এখনো বাস্তবায়িত নয়

Credentials না থাকায় কোনো webhook deploy, incoming chatbot বা automated send চালু করা হয়নি। `integrations/contracts.ts` শুধু ভবিষ্যৎ adapter-এর type boundary। পরিকল্পিত কাজ:

1. Meta Business account, WhatsApp Business Account, business phone number ও প্রয়োজনীয় business verification/consent policy।
2. Developer app ও official Cloud API বা অনুমোদিত BSP; system-user access token, phone-number ID, app secret server-side secret manager-এ।
3. Webhook verification challenge; POST-এর **raw body HMAC signature** validate; ভুল signature reject।
4. Provider message ID-তে unique constraint/processing log দিয়ে webhook replay duplicate আটকানো।
5. Incoming messages queue; supported service window ও opt-in যাচাই; তারপর বর্তমান bounded agent backend-এ পাঠানো।
6. Business-initiated message-এর জন্য approved templates/category/language এবং customer opt-in।
7. Human handoff state; human handling চললে bot reply স্থগিত; লগে PII redaction।
8. Delivery status webhook শুধু messaging delivery। **Order Confirmed বা payment Paid-এর প্রমাণ নয়।**
9. Rate, quota, template rejection, retry/backoff, unsubscribe এবং billing alerts পরীক্ষা।

**খরচ:** Meta-এর ৩০ সেপ্টেম্বর ২০২৬-এ updated official pricing page ১ অক্টোবর ২০২৬-এর pricing পরিবর্তন অন্তর্ভুক্ত করে। Delivered message category ও recipient market অনুযায়ী চার্জ হয়; পুরোনো 24-hour service reply সবসময় free বলবেন না। Activate করার আগে Bangladesh market rate, বর্তমান monthly service-message allowance ও provider/BSP markup যাচাই করুন।

Official reference: https://developers.facebook.com/documentation/business-messaging/whatsapp/pricing

এই প্রজেক্টে unofficial WhatsApp Web scraping, QR session automation বা spam/bulk send নেই।

## E. bKash ও Nagad: বর্তমান manual flow

1. নিজের business-এর জন্য provider অনুমোদিত payment receiving method ঠিক করুন। কোনো ব্যক্তিগত wallet-কে অনুমোদিত merchant account বলা হয়নি।
2. Admin settings-এ অনুমোদিত নম্বর/merchant নির্দেশনা লিখুন। না থাকলে টাকা না পাঠানোর notice এবং checkout block।
3. Customer method ও Transaction ID দেন; server status **Verification pending**।
4. Admin bank/merchant statement/provider dashboard-এ টাকা পাওয়া, amount, reference ও reuse নিজে যাচাই করবেন।
5. তারপর Orders → বিস্তারিত → manual verification confirmation → Paid। এটি admin declaration; API verification নয়।
6. PIN/OTP/password/card security code-এর field নেই।

Manual Transaction ID reuse/fraud automatedভাবে provider-এ যাচাই করা হয় না। একই ID multiple order-এ থাকলে admin তদন্ত করবেন; live business-এর জন্য merchant API reconciliation উত্তম।

## F. Merchant payment API — এখনো বাস্তবায়িত নয়

নিজের approved merchant account ও provider documentation ছাড়া API route/keys কার্যকর করা হয়নি। ভবিষ্যৎ adapter-এ:

- Server database order থেকে amount/currency নেবে; browser-এর দাম নয়।
- Official create-payment → provider hosted checkout; PIN/OTP শুধু provider-এর interface, AH SHOP-এ নয়।
- Signed/verified callback, provider transaction lookup, expected merchant/order/amount/currency match।
- Unique provider event/transaction ID, idempotent Paid transition, audit এবং replay prevention।
- Success URL/query string, customer screenshot বা Transaction ID **কখনো Paid-এর প্রমাণ নয়**।
- Pending/failed/expired/refund state, duplicate callback ও timeout testing।
- Sandbox → provider certification → live permission; fee ও settlement terms আগে জানাতে হবে।

Refund button/API দেওয়া হয়নি। `Returned` status-এর অর্থ স্বয়ংক্রিয় refund নয়; বাস্তব refund/reconciliation প্রক্রিয়া আলাদাভাবে তৈরি করতে হবে।
