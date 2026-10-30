# Phase অনুযায়ী implementation status

> **v2 আপডেট:** checkout, private owner access, pinning, moderated reviews, SSLCOMMERZ connector ও Android AAB/APK এখন যোগ হয়েছে। বর্তমান নির্দেশনা: [v2 guide](V2-OWNER-PAYMENT-APP.md)। নিচের v1 baseline-এর পুরোনো ‘এখনো নেই’ বক্তব্যের ক্ষেত্রে v2 guide অনুসরণ করুন।


এটি কাজের সৎ তালিকা, marketing claim নয়। প্রথমে frontend ও cart তৈরি করে তারপর secure backend foundation যোগ করা হয়েছে। আপনার cloud account/credentials-এর কাজ পরের পর্যায়।

| Phase | হয়েছে | বাকি |
|---|---|---|
| 1. Responsive frontend | ২২টি requested page/feature area এবং supporting wishlist/offers, mobile nav, Bengali font, মূল storefront English toggle, light/dark | পূর্ণ English admin/content translation, physical Android usability audit |
| 2. Catalog/cart | Sample catalog, details/search/filter/sort, categories, wishlist, stock-bound persistent cart | আপনার আসল catalog, variants, বড় catalog pagination |
| 3. Checkout/WhatsApp | Summary+consent, phone/address/notes, order request, click-to-chat message builder, missing-number guard | আপনার অনুমোদিত WhatsApp ও delivery settings; actual message sending user-initiated |
| 4. Secure database/auth | SQL schema, RLS/grants/admin roles, transaction RPC, auth client, image-validation Edge Function, rate-limited order/track endpoints | আপনার Supabase-এ deploy, actual Auth/Storage/CORS/concurrency tests, stronger auth/OTP if required |
| 5. Admin | Demo/live CRUD wiring, orders/status/manual paid, inventory, low stock, CSV reports, public settings/policies | Cloud credentials/admin setup, large-data aggregation, richer accounting |
| 6. AI backend | Deployable bounded intent-classifier endpoint, opt-in, database-grounded response builder, fallback labels, admin config | Your API key/model/provider contract, real usage verification, full conversational checkout tool workflow |
| 7. Official WhatsApp API | Click-to-chat complete; future adapter contract ও approval/security/cost blueprint | Official inbound webhook, queue, template send, token/business approval, handoff operations |
| 8. Payments | COD, approved manual-wallet instructions/Transaction ID, manual Paid confirmation | Official merchant API, callback verification, provider sandbox/live approval, refunds/reconciliation |
| 9. Testing/security | Frontend build, ৫ browser suites, ২৫ local PG checks, ৪ Edge Deno checks, dependency audit | Full cloud/security/load/accessibility/physical-device audit |
| 10. Deployment/domain | Running Arena development preview, deployable source/static ZIP, Android publication guide, hosting config | আপনার account-এ permanent deploy, actual public URL, purchased/owned domain DNS+SSL |

## API/credential ছাড়া যা চলছে

- React website ও সব navigation/forms/filters/cart/wishlist।
- Clearly marked demo order save এবং demo admin workflows।
- Rule-based assistant; বাস্তব AI নয়।
- WhatsApp message preparation logic; নম্বর না থাকলে informative block।
- Testable PostgreSQL schema/RLS/RPC code।

## নিজের তথ্য না দেওয়া পর্যন্ত যা intentionally blocked/empty

- বাস্তব ব্যবসার ঠিকানা/ফোন/ইমেইল/নীতি।
- অনুমোদিত flat delivery charge, delivery ETA।
- bKash/Nagad payment instructions।
- WhatsApp launch to a business number।
- AI provider invocation without consent/key/model/enable।
- Real database orders without configured deployed backend।
- Live Sample-product checkout: database প্রত্যাখ্যান করে।

## আপনার পরের সিদ্ধান্ত

1. প্রথমে Sample preview দেখে design/cart/admin flow পরীক্ষা।
2. Free-tier limits মেনে নিজের Supabase project তৈরি।
3. Actual catalog, authorized WhatsApp, delivery/policies ও merchant-approved instructions দিন।
4. Secure staging checklist পাস।
5. তারপর commercial-appropriate host-এ public launch।
6. Official WhatsApp/payment approvals এবং AI spend budget দিয়ে পরের integration iteration।

গোপন key কখনো এই ডকুমেন্ট, admin public settings বা frontend-এ বসাবেন না।
