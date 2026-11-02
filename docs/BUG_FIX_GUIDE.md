# Green Basket — Bug & Fix Guide

A step-by-step guide to every bug, order-logic problem and issue found in the
code. Each issue has:

- **Where**: the file and line (paths are relative to ``)
- **What's wrong**, and **what goes wrong for a real user**
- **Steps to fix** by hand
- **How to check it's fixed**
- **Prompt**: a copy-paste prompt for Claude Code (or any coding AI) that fixes only that issue

**Work through them in order, one at a time.** Fix one issue, test it, commit
it, then move to the next. The order goes from most dangerous (money and
security) to least.

Line numbers are from the current commit and will move as you edit. Search for
the quoted code if a line number no longer matches.

---

## Before you start

1. Make a branch for the fixes: `git checkout -b fix/bugs`
2. Install and run the backend once so you know it works:
   ```bash
   cd backend
   npm install
   cp .env.example .env   # fill in your values
   npm run dev
   ```
3. Run the tests once and note what fails **before** you change anything:
   ```bash
   npm run test:run
   ```
   `tests/giftCardController.test.js` already fails, because the gift card code doesn't exist (Issue 17).
4. After each fix, commit it with a message like `fix: <issue title>`.

## Status: fixed on branch `fix/bugs`

Every issue below has been fixed on `fix/bugs` except where noted, with
tests. Fixing them turned up more bugs, which are listed after the table.

| # | Issue | Status | Commit |
|---|---|---|---|
| 1 | Credentials committed | ✅ Removed from the code and untracked. **You still need to change the Atlas password**: the old values remain in git history | `c95f41c`, `6af3ca8` |
| 2 | Payment not bound to its order | ✅ | `b480ca4` |
| 3 | Wallet orders were free | ✅ | `5a21ff5` |
| 4 | Wallet/referral APIs not connected | ✅ Mounted, plus 24 more app calls connected | `5e0baa9` |
| 5 | Port mismatch | ✅ 5002 everywhere | `5e0baa9` |
| 6 | Unsafe stock reservation | ✅ | `9f47060` |
| 7 | Unpaid orders hold stock forever | ✅ Webhook and expiry job | `2ec1da6` |
| 8 | Cancelling finished orders, no refunds | ✅ | `20bafe9` |
| 9 | Merchants could set any status | ✅ | `20bafe9` |
| 10 | Loyalty points awarded twice | ✅ | `20bafe9` |
| 11 | Carts mixed merchants | ✅ | `7d971be` |
| 12 | Preparation price ignored | ✅ | `7d971be` |
| 13 | Coupon checks incomplete | ✅ | `7d971be` |
| 14 | Flat ₹50 delivery | ✅ Delivery zones are used | `7d971be` |
| 15 | App always placed pickup orders | ✅ New checkout | `7c9ddc4` |
| 16 | `order_paid` event never sent | ✅ | `2ec1da6` |
| 17 | Gift cards advertised but missing | ✅ Advertising removed. Not built, because the app has no gift card screens | `5dfae1b` |
| 18 | Delivery agents | ⚠️ The crashing script is fixed. The feature itself is still not built | `5dfae1b` |
| 19 | CORS `*` and shared token secret | ✅ | `5dfae1b` |
| 20 | Repo clutter | ⚠️ Build files and logs are untracked. **The ~55 one-off scripts in `backend/` were not deleted; that needs your decision** | `5dfae1b` |
| 21 | Duplicate notification services | ⚠️ `/api` counts are now correct. The modules were not merged: they work, and merging them would be a refactor with no user-visible fix | `5dfae1b` |
| 22 | Hard-coded backend address | ✅ `--dart-define=API_URL=...` | `7c9ddc4` |

### Additional bugs found and fixed while working

**Security and money**
- `verifyTopup` credited whatever amount the app sent, and accepted payments made for normal orders.
- `useForPayment` let anyone debit any amount against any order number.
- `POST /api/payment/refund` was open to every logged-in user, so a customer could refund their own delivered order.
- `GET /api/orders/:id` and the tracking endpoints returned any order, with the customer's contact details, to any logged-in user. Anyone could also move an order's tracking pin.
- Every wallet credit (returns, disputes, admin credit, cashback, referral) used read-modify-save, which overwrote concurrent wallet changes.
- Negative quantities lowered the order total and *added* stock.
- Loyalty redemption coupons were public and guessable, a double tap could spend the same points twice, and redeeming against an order took the points for nothing.
- Customers could sign up with a merchant's email, which locked that merchant out of login.

**Broken features**
- Coupons were never applied to orders: the lookup filtered on a field (`Offer.isActive`) that doesn't exist.
- Sign-up sent a verification link using a template that doesn't exist, while the app waited for an OTP. Forgot-password promised a link, sent an OTP, and the app had no screen for entering it.
- Recipe-to-cart added recipe amounts as product units, so "200 g onion" became 200 kg. It also crashed when an ingredient had no linked product.
- The customer "Cancel Order", admin "Force Complete", admin bulk operations and merchant bulk upload buttons were mock-ups that reported success without doing anything.
- The cart couldn't update "chopped" items, and silently swallowed errors.
- Unpaid online orders were announced to merchants as new orders.
- A payment that arrived after an order expired was kept instead of refunded.
- `SIGTERM` never stopped the server.
- The loyalty tier bonus rates in the code differed from the rates shown in the app.
- Status labels were wrong: "out-for-delivery" showed as "Ready to pick up".

### How it was tested
- **Backend:** 287 Jest tests (up from 27 that could run before), with a real MongoDB through `mongodb-memory-server`.
- **App ↔ backend contract:** `npm run check:api` checks that every app API call matches a backend route.
- **Order status rules:** a test fails if the Dart copy of the rules differs from the backend's.
- **Flutter:** `flutter analyze` and `flutter test` on Flutter 3.38.8 (the version in your lock file), plus `test/api_integration_test.dart`, which drives the app's real repositories against a seeded backend.

---

### Checklist

| # | Issue | Severity | Area |
|---|---|---|---|
| 1 | Credentials committed to the repo | 🔴 Critical | Security |
| 2 | Payment check doesn't confirm the payment belongs to this order | 🔴 Critical | Payment |
| 3 | "Wallet" orders are placed without taking money from the wallet | 🔴 Critical | Payment |
| 4 | Wallet and referral APIs are not connected | 🔴 High | Broken feature |
| 5 | Port numbers don't match | 🟠 Medium | Setup |
| 6 | Stock is not reserved safely (partial decrement, race condition) | 🔴 High | Order logic |
| 7 | Unpaid online orders hold stock forever (no webhook, no expiry) | 🔴 High | Order logic |
| 8 | Customers can cancel completed or delivered orders, and no refund is made | 🔴 High | Order logic |
| 9 | Merchants can set any status (no transition rules) | 🔴 High | Order logic |
| 10 | Loyalty points can be awarded twice for one order | 🟠 Medium | Order logic |
| 11 | Cart mixes merchants, but the order goes to one merchant | 🔴 High | Order logic |
| 12 | Order total ignores the preparation price shown in the cart | 🟠 Medium | Order logic |
| 13 | Coupon checks at order time are incomplete | 🟠 Medium | Order logic |
| 14 | Delivery charge is always ₹50 (ignores delivery zones) | 🟠 Medium | Order logic |
| 15 | The app always places pickup orders | 🟠 Medium | App |
| 16 | Merchant never receives the `order_paid` event | 🟡 Low | Real-time |
| 17 | Gift cards are advertised but don't exist | 🟠 Medium | Missing feature |
| 18 | Delivery agents are designed but not built | 🟡 Low | Missing feature |
| 19 | CORS allows any site; one secret shared for everything | 🟠 Medium | Security |
| 20 | Repo clutter (scripts, logs, build files) | 🟡 Low | Hygiene |
| 21 | Duplicate notification services and wrong API counts | 🟡 Low | Hygiene |
| 22 | Backend address hard-coded in the app | 🟡 Low | App |

---

# Phase 1 — Security and money (do these first)

## Issue 1 — Credentials committed to the repo 🔴

**Where**
- `backend/debug_analytics.js`, `backend/seed_kumar_data.js`, `backend/check_prod_db.js`: these appear to contain a hard-coded MongoDB Atlas connection string with a username and password. (Claude didn't open the values.)
- `backend/.token`: a saved login token
- `backend/dump.rdb`: a Redis database dump
- `flutter_app/ios/Runner/GoogleService-Info.plist` and the Firebase keys in `flutter_app/lib/main.dart`. Firebase client keys are designed to ship inside apps, so they're lower risk, but restrict them in the Firebase console.

**What's wrong:** anyone who can see the repo can log into your database and
read or delete all users, orders and payments.

**Steps to fix**
1. **Rotate first.** In MongoDB Atlas, go to Database Access and change the password of the database user in those scripts, or delete that user and create a new one. Update your local `.env` with the new `MONGODB_URI`.
2. In the three scripts, replace the hard-coded string with `process.env.MONGODB_URI`, and add `require('dotenv').config()` at the top if it's missing.
3. Delete the committed secret files from git, keeping your local copies:
   ```bash
   git rm --cached backend/.token backend/dump.rdb
   ```
4. Add these lines to `backend/.gitignore`: `.token`, `*.rdb`, `server_log*.txt`.
5. Optional: the old password stays in git history. After rotating (step 1) it no longer works, so this step only removes the old value. To remove it anyway, use [`git filter-repo`](https://github.com/newren/git-filter-repo) and force-push. This rewrites history, so only do it if no one else has cloned the repo or you've warned them.
6. In Firebase console → Google Cloud → Credentials, restrict the iOS/Android API key to your app's bundle ID and package name.

**How to check:** run the following and confirm it prints nothing except `.env.example`:
```bash
git grep -n "mongodb+srv://" -- ':!*.md'
```

**Prompt**
```
In the repo at backend, three scripts
(debug_analytics.js, seed_kumar_data.js, check_prod_db.js) contain a
hard-coded MongoDB connection string. Replace each hard-coded string with
process.env.MONGODB_URI, and make sure each script loads dotenv at the top
(require('dotenv').config({ path: require('path').join(__dirname, '.env') })).
Do not print the old connection strings in your output. Then run
`git rm --cached backend/.token backend/dump.rdb` and add `.token`, `*.rdb`
and `server_log*.txt` to backend/.gitignore. Finally, search the whole repo
(excluding .md files and .env.example) for any other "mongodb+srv://" strings,
API keys or passwords, and list the files that still contain them without
showing the secret values. Don't change anything else.
```

---

## Issue 2 — Payment check doesn't confirm the payment belongs to this order 🔴

**Where:** `backend/src/controllers/paymentController.js`, `verifyPayment`, around line 153.

**What's wrong:** the server checks that the Razorpay signature is valid, but
never checks that `razorpayOrderId` is the Razorpay order **created for this
order** (`order.razorpayOrderId`).

**What goes wrong:** a user pays ₹1 for a cheap order, then sends that valid
`razorpayOrderId`, `razorpayPaymentId` and signature together with the
`orderId` of an expensive order. The expensive order is marked **paid and
confirmed**.

**Steps to fix**
1. In `verifyPayment`, after loading `order`, add:
   ```js
   if (!order.razorpayOrderId || order.razorpayOrderId !== razorpayOrderId) {
       return res.status(400).json({ success: false, error: 'Payment does not belong to this order' });
   }
   ```
2. Recommended: fetch the payment from Razorpay (`razorpay.payments.fetch(razorpayPaymentId)`). Check that `status === 'captured'` (or `authorized`), that `order_id === order.razorpayOrderId`, and that `amount === Math.round(order.totalAmount * 100)`.
3. Also refuse if the order is `cancelled`.
4. Add a Jest test for this case: "a valid signature for a different Razorpay order is rejected".

**How to check:** create two orders and pay for one. Call `/api/payment/verify` with the other order's `orderId` and the first order's Razorpay IDs. You should get a 400, and the second order should stay `payment_pending`.

**Prompt**
```
In backend/src/controllers/paymentController.js,
the verifyPayment handler checks the Razorpay signature but never checks that
the razorpayOrderId sent by the client equals order.razorpayOrderId (set in
createPaymentOrder). That lets a valid payment for one order confirm a
different order. Fix it:
1. Reject with 400 if order.razorpayOrderId is missing or differs from razorpayOrderId.
2. Reject with 400 if the order status is 'cancelled'.
3. After the signature check, fetch the payment from Razorpay using the client
   in src/config/razorpay.js (or paymentService if it already wraps it) and
   require payment.order_id === order.razorpayOrderId,
   payment.amount === Math.round(order.totalAmount * 100), and status
   'captured' or 'authorized'. If the Razorpay fetch fails because keys are
   missing in development, log a warning and continue only when
   NODE_ENV !== 'production'.
Add a Jest test in backend/tests/payment.test.js covering the mismatched
razorpayOrderId case (mock the signature check to return true). Keep the
existing success flow unchanged. Run `npm run test:run -- payment` and show
the result.
```

---

## Issue 3 — "Wallet" orders are placed without taking money from the wallet 🔴

**Where:** `backend/src/controllers/orderController.js`, `createOrder` (lines ~160–205).

**What's wrong:** `createOrder` accepts `paymentMethod: 'wallet'`, creates the
order as `pending`, and clears the cart, but **never deducts the wallet
balance or checks that it's enough**. The separate `/api/wallet/use-for-payment`
endpoint exists, but nothing forces it to be called, and it isn't even mounted
(Issue 4).

**What goes wrong:** anyone calling the API with `paymentMethod: "wallet"`
gets goods without paying.

**Steps to fix**
1. In `createOrder`, before `Order.create`, if `paymentMethod === 'wallet'`:
   - Load the user's `Wallet`. Reject if it's missing, locked, or `balance < totalAmount`.
   - Deduct atomically:
     ```js
     Wallet.findOneAndUpdate(
       { user: userId, balance: { $gte: totalAmount }, isLocked: { $ne: true } },
       { $inc: { balance: -totalAmount } },
       { new: true }
     )
     ```
     If this returns `null`, reject with "Insufficient wallet balance".
   - Record a debit transaction the same way `walletController.useForPayment` does. Reuse `src/utils/walletHelpers.js` if it has a helper.
2. Create the order with `paymentStatus: 'completed'` and status `confirmed` for wallet payments.
3. If anything fails after the deduction, refund the wallet (add the amount back).
4. When a wallet-paid order is cancelled or refunded, credit the money back to the wallet (see Issue 8).

**How to check:** a user with ₹0 who orders with `paymentMethod: "wallet"` gets a 400. A user with ₹1000 who places a ₹300 wallet order ends with ₹700, and the order shows as paid.

**Prompt**
```
In backend/src/controllers/orderController.js,
createOrder accepts paymentMethod 'wallet' but never deducts the wallet, so
wallet orders are free. Read src/models/Wallet.js, src/utils/walletHelpers.js
and walletController.useForPayment first to follow the existing transaction
format. Then, in createOrder, when paymentMethod === 'wallet':
- Atomically deduct totalAmount with Wallet.findOneAndUpdate using a
  { balance: { $gte: totalAmount } } condition (and respect the wallet's lock
  flag, whatever it is called in the model). If no document is returned,
  respond 400 "Insufficient wallet balance" before creating the order.
- Push a debit transaction entry linked to the order, matching useForPayment.
- Create the order with paymentStatus 'completed' and status 'confirmed'.
- If Order.create throws after the deduction, credit the amount back.
Add Jest tests for "insufficient balance is rejected" and "balance is reduced
by the order total". Don't change COD or Razorpay behaviour.
```

---

# Phase 2 — Broken features

## Issue 4 — Wallet and referral APIs are not connected 🔴

**Where:** `backend/server.js`, the route block around lines 357–378.
`src/routes/walletRoutes.js` and `src/routes/referralRoutes.js` exist but are
never imported or mounted.

**What goes wrong:** the app's Wallet screen and Referral screen call
`/api/wallet/...` and `/api/referral`, and every call returns **404 Not Found**.

**Steps to fix**
1. In `server.js`, add these with the other route imports:
   ```js
   const walletRoutes = require('./src/routes/walletRoutes');
   const referralRoutes = require('./src/routes/referralRoutes');
   ```
2. Add these with the other `app.use` lines:
   ```js
   app.use('/api/wallet', walletRoutes);
   app.use('/api/referral', referralRoutes);
   ```
3. The app also calls `GET /wallet/balance`, but `walletRoutes.js` has no `/balance` route. Either add `router.get('/balance', walletController.getWallet)` or change the app to call `GET /wallet`.
4. The app calls `/referral` (bare). The backend has `/referral/stats`, `/generate`, `/apply` and `/validate/:code`. Check `flutter_app/lib` for that call and point it at the right one.
5. Do Issue 3 **before or together with** this one. Mounting `/wallet/use-for-payment` without fixing wallet orders opens more payment paths.

**How to check:**
```bash
curl -H "Authorization: Bearer <customer token>" http://localhost:5002/api/wallet
```
This should return JSON instead of a 404. Then open the Wallet and Referral screens in the app.

**Prompt**
```
In backend/server.js, walletRoutes
(src/routes/walletRoutes.js) and referralRoutes (src/routes/referralRoutes.js)
are never required or mounted, so /api/wallet/* and /api/referral/* return 404.
Mount them at /api/wallet and /api/referral alongside the other routes.
Then grep flutter_app/lib for every '/wallet' and '/referral' API call and
compare each one with the routes that actually exist in those two route files.
For any call the backend doesn't support (for example GET /wallet/balance),
either add a matching backend route that reuses an existing controller
function, or change the Flutter call to the correct existing path. Pick
whichever needs less change, and list each mismatch and what you did.
Make sure all wallet and referral controller functions referenced by the
routes exist, so the server starts. Start the server and confirm it boots.
```

---

## Issue 5 — Port numbers don't match 🟠

**Where:** `backend/.env.example` (`PORT=5001`), `backend/server.js:385`
(falls back to `6000`), `.claude/launch.json` (5002), and
`flutter_app/lib/config/constants.dart` (5002).

**What goes wrong:** a new developer copies `.env.example`, the server starts
on 5001, and the app can't connect.

**Steps to fix**
1. Set `PORT=5002` in `.env.example`.
2. Change the fallback in `server.js` to `process.env.PORT || 5002`.
3. Note in `backend/README.md` that the app expects port 5002.

**Prompt**
```
Make the backend port consistent at 5002:
set PORT=5002 in backend/.env.example, change the fallback in backend/server.js
from 6000 to 5002, and add one line to backend/README.md saying the Flutter
app expects port 5002. Change nothing else.
```

---

# Phase 3 — Order logic

These fixes all touch `backend/src/controllers/orderController.js`. Do them one
at a time and run the order tests after each.

## Issue 6 — Stock is not reserved safely 🔴

**Where:** `createOrder`, the loop at lines ~54–96.

**What's wrong**
- Stock is checked and decremented **one item at a time**. If item 3 is out of stock or missing, the function returns an error, but items 1 and 2 have **already been decremented**. Stock is lost for an order that was never created.
- The check (`product.stock < quantity`) and the save are separate steps. Two customers ordering the last unit at the same moment can both succeed, and stock goes negative.

**Steps to fix** (no replica set needed)
1. **First pass:** loop over the items and load the products, checking each exists and has enough stock and building `orderItems`. Don't change anything yet.
2. **Second pass:** for each item, decrement atomically:
   ```js
   const updated = await Product.findOneAndUpdate(
     { _id: item.product, stock: { $gte: item.quantity } },
     { $inc: { stock: -item.quantity, totalSales: item.quantity } },
     { new: true }
   );
   ```
   If `updated` is `null`, someone else bought it first. **Add back** the stock for the items already decremented in this request, then return 400.
3. If `Order.create` fails later, add back the stock for all items too.
4. Update the `dailySales` fields after the order is created. They're stats, not money.
5. Alternative: MongoDB transactions (`session.withTransaction`). Atlas supports them, but local tests then need `MongoMemoryReplSet`.

**How to check:** order [item A qty 1, item B qty 9999]. You should get a 400, and item A's stock should be unchanged. Also fire two orders for the last unit at the same time; only one should succeed.

**Prompt**
```
In backend/src/controllers/orderController.js,
createOrder decrements product stock inside the validation loop. If a later
item fails validation, earlier items stay decremented, and the
check-then-save is not atomic, so concurrent orders can oversell. Refactor
the stock handling:
1. First pass: load and validate every item (exists, enough stock) and build
   orderItems, without writing anything.
2. Second pass: decrement each item with
   Product.findOneAndUpdate({ _id, stock: { $gte: qty } }, { $inc: { stock: -qty, totalSales: qty } }).
   If any returns null, roll back the decrements already made in this request
   and return 400 "Insufficient stock for <name>".
3. If Order.create or anything after the decrement throws, roll back all
   decrements.
4. Keep the dailySales/lastDailyActivity bookkeeping, but do it after the
   order is created.
Put the rollback in a small helper (restoreStock(items)) so Issues 7–9 can
reuse it. Add Jest tests: (a) a failing second item leaves the first item's
stock unchanged; (b) two concurrent orders for the last unit, one succeeds.
Don't change pricing, coupon or notification logic.
```

---

## Issue 7 — Unpaid online orders hold stock forever 🔴

**Where**
- `createOrder` reduces stock **as soon as** a Razorpay order is drafted (`status: 'payment_pending'`).
- `paymentController.handleWebhook` (line 257) is an empty stub.
- `src/utils/cronJobs.js` is a placeholder, and `src/cron/reminderCron.js` is a TODO.

**What goes wrong:** a customer opens Razorpay, then closes the app or the
payment fails. The order stays `payment_pending` forever and its stock is never
released, so products appear "out of stock" while nobody bought them. If the
payment **succeeds** but the app dies before calling `/verify`, the customer
paid but the order is never confirmed.

**Steps to fix**
1. **Webhook:** implement `handleWebhook`.
   - Verify the `X-Razorpay-Signature` header against the **raw body** with `RAZORPAY_WEBHOOK_SECRET` (HMAC SHA256). The route is already mounted with `express.raw`.
   - On `payment.captured` / `order.paid`: find the order by `razorpayOrderId`, mark it paid and confirmed, and clear the cart. This should be the same code as `verifyPayment`, so move it into a shared function and make it safe to run twice.
   - On `payment.failed`: add a payment event, but leave the order alone. The customer can retry.
   - Add `RAZORPAY_WEBHOOK_SECRET` to `.env.example`, and register the webhook URL in the Razorpay dashboard.
2. **Expiry cron:** in `src/utils/cronJobs.js`, every 5 minutes, find orders with `status: 'payment_pending'` older than 30 minutes. Mark them `cancelled` (`cancelledBy: 'system'`) and restore their stock with the helper from Issue 6.
3. Either implement or delete `reminderCron.js`. It currently only logs.

**How to check:** create a Razorpay order and don't pay. After 30 minutes (or a shorter setting for testing), the order is cancelled and its stock is back. Use Razorpay's test-mode webhook tool to send `payment.captured`; the order becomes confirmed without the app calling `/verify`.

**Prompt**
```
In backend, online (Razorpay) orders reduce
stock when created with status 'payment_pending', but if payment never
completes nothing releases the stock. paymentController.handleWebhook is an
empty stub, and src/utils/cronJobs.js is a placeholder. Implement:
1. handleWebhook: verify X-Razorpay-Signature against the raw body
   (the route in server.js already uses express.raw) using HMAC-SHA256 with
   process.env.RAZORPAY_WEBHOOK_SECRET; respond 400 on a bad signature.
   Handle 'payment.captured' and 'order.paid' by finding the order by
   razorpayOrderId and confirming it. Move the confirm logic currently inside
   verifyPayment into a shared, idempotent function (e.g.
   confirmOrderPayment(order, paymentId)) used by both. Log 'payment.failed'
   as a paymentEvent without cancelling.
2. A node-cron job in src/utils/cronJobs.js, every 5 minutes, that cancels
   orders with status 'payment_pending' older than
   PAYMENT_PENDING_TIMEOUT_MINUTES (default 30). Set cancelledBy 'system',
   push a statusHistory entry with updatedByModel 'System', and restore stock
   (reuse the restoreStock helper if it exists, otherwise create one).
3. Add RAZORPAY_WEBHOOK_SECRET and PAYMENT_PENDING_TIMEOUT_MINUTES to
   .env.example.
Add Jest tests for the webhook signature check and for the expiry job
(call the job function directly). Don't change COD orders.
```

---

## Issue 8 — Customers can cancel completed or delivered orders, and no refund is made 🔴

**Where:** `cancelOrder`, line ~589:
`if (['delivered', 'cancelled'].includes(order.status))`

**What's wrong**
- Only `delivered` and `cancelled` are blocked. A customer can still cancel an order that is **`completed`**, **`refunded`** or **`out-for-delivery`**, and every cancel **adds the stock back**. Cancelling a completed order puts sold goods back into stock.
- For prepaid orders (Razorpay or wallet), the SMS says "Any prepaid amount will be refunded", but **no refund is made**.
- Loyalty points already earned are not taken back.

**Steps to fix**
1. Allow customer cancellation only from an allow-list:
   `const CANCELLABLE = ['payment_pending', 'pending', 'confirmed'];`
   You can include `preparing` if you want.
2. If `order.paymentStatus` is `completed` or `paid`:
   - Razorpay: call the existing refund logic (`paymentController.processRefund` / `paymentService`) and set `order.refund.status = 'initiated'`.
   - Wallet: credit the amount back to the wallet with a refund transaction.
   - Set `paymentStatus: 'refunded'` once done.
3. Restore stock with the shared helper (Issue 6).
4. Push a `statusHistory` entry. `cancelOrder` currently sets `status` but adds no history.

**How to check:** cancelling a `completed` order returns 400 and the stock is unchanged. Cancelling a paid `confirmed` order produces a refund (Razorpay test dashboard or wallet balance).

**Prompt**
```
In backend/src/controllers/orderController.js,
cancelOrder only blocks 'delivered' and 'cancelled', so customers can cancel
'completed', 'refunded' and 'out-for-delivery' orders, and each cancel
restores stock. It also never refunds prepaid orders. Fix it:
1. Only allow cancellation when status is one of
   ['payment_pending', 'pending', 'confirmed']; otherwise return 400 with a
   clear message.
2. Push a statusHistory entry (updatedByModel 'User').
3. If paymentStatus is 'completed' or 'paid': for Razorpay orders, start a
   refund using the existing refund code in paymentController/paymentService
   (read it first and reuse it; don't duplicate the Razorpay call); for
   wallet orders, credit the wallet back with a refund transaction in the
   same format walletController uses. Update order.refund and paymentStatus.
4. Restore stock via the shared restoreStock helper if it exists.
Add Jest tests: cancelling a 'completed' order is rejected and stock is
unchanged; cancelling a paid wallet order credits the wallet back.
```

---

## Issue 9 — Merchants can set any status 🔴

**Where:** `updateOrderStatus`, line ~377: `order.status = status;`

**What's wrong**
- There are no transition rules. A merchant can move an order from `cancelled` → `delivered`, or from `payment_pending` (unpaid) → `delivered`. Delivery triggers loyalty points, so points are earned on unpaid or cancelled orders.
- A merchant can set `cancelled`, but that path **doesn't restore stock** and **doesn't refund**.
- A merchant can set `refunded` without any refund happening.
- An invalid status string causes a Mongoose validation error, which surfaces as a 500 instead of a 400.

**Steps to fix**
1. Define the allowed transitions once, for example in `src/utils/orderStatus.js`:
   ```js
   const TRANSITIONS = {
     pending:            ['confirmed', 'cancelled'],
     confirmed:          ['preparing', 'cancelled'],
     preparing:          ['ready', 'cancelled'],
     ready:              ['out-for-delivery', 'delivered'],   // 'delivered' = picked up
     'out-for-delivery': ['delivered'],
     delivered:          ['completed'],
   };
   ```
   `payment_pending`, `cancelled`, `completed` and `refunded` cannot be changed by the merchant.
2. In `updateOrderStatus`, reject (400) any status not in `TRANSITIONS[order.status]`.
3. When the merchant cancels, restore stock and refund, using the same code as Issue 8. Move that code into a shared `cancelAndRefund(order, by)` function.
4. Remove `refunded` from what merchants can set. Refunds come from the refund or return flows.

**How to check:** `pending → delivered` returns 400. `cancelled → confirmed` returns 400. A merchant cancelling a `confirmed` order restores stock.

**Prompt**
```
In backend/src/controllers/orderController.js,
updateOrderStatus sets order.status to whatever the merchant sends, with no
transition rules. Create src/utils/orderStatus.js exporting a TRANSITIONS
map and a canTransition(from, to) function using:
pending→[confirmed,cancelled], confirmed→[preparing,cancelled],
preparing→[ready,cancelled], ready→[out-for-delivery,delivered],
out-for-delivery→[delivered], delivered→[completed]. Nothing else may be
changed by a merchant (payment_pending, cancelled, completed and refunded are
locked). In updateOrderStatus, return 400 for unknown or disallowed
transitions. When the merchant sets 'cancelled', restore stock and refund
prepaid orders: move the cancel/refund logic from cancelOrder into one
shared function (e.g. cancelAndRefund(order, cancelledBy)) used by both
handlers. Add Jest tests for an allowed transition, a disallowed one, and
merchant cancellation restoring stock.
```

---

## Issue 10 — Loyalty points can be awarded twice for one order 🟠

**Where:** `updateOrderStatus`, line ~398: points are awarded when
`status === 'delivered' || status === 'completed'`.

**What goes wrong:** the merchant marks an order `delivered`, then later
`completed`, and the customer earns points **twice**. Nothing records that
points were already given.

**Steps to fix**
1. Add `loyaltyPointsAwarded: { type: Number, default: 0 }` and `loyaltyAwardedAt: Date` to the `Order` schema.
2. Award points only if `!order.loyaltyAwardedAt`, then set both fields. Use an atomic update so two quick requests can't both award:
   ```js
   Order.updateOne({ _id: order._id, loyaltyAwardedAt: null }, { $set: { ... } })
   ```
   Only award if `modifiedCount === 1`.
3. Award only when the order is paid (or is COD and delivered).
4. Use `src/config/loyaltyTiers.js` as the single source for rates. The controller currently hard-codes its own `rateMap`.
5. When an order is cancelled or refunded after points were given, take the points back (see Issues 8 and 9).

**Prompt**
```
In backend, updateOrderStatus awards loyalty
points on both 'delivered' and 'completed', so one order can award points
twice. Add loyaltyPointsAwarded (Number, default 0) and loyaltyAwardedAt
(Date) to src/models/Order.js. In updateOrderStatus, award points only once
per order, guarded by an atomic Order.updateOne({ _id, loyaltyAwardedAt: null }, ...)
and proceeding only if modifiedCount === 1. Take the per-tier rate from
src/config/loyaltyTiers.js instead of the hard-coded rateMap in the
controller. If the shared cancel/refund function exists, make it deduct
order.loyaltyPointsAwarded from the user when it is greater than 0.
Add a Jest test: delivered then completed awards points once.
```

---

## Issue 11 — Cart mixes merchants, but the order goes to one merchant 🔴

**Where**
- `cartController.addToCart` (line 36) and `addRecipeToCart` allow products from **any** merchant in one cart.
- `createOrder`, line ~99: `// Get merchant from first product` → the whole order is assigned to `items[0]`'s merchant.

**What goes wrong:** a customer buys tomatoes from Farmer A and milk from
Farmer B. Farmer A receives the whole order, including B's milk, and A's
earnings and payouts include B's sales. Farmer B never hears about the order.

**Steps to fix.** Choose one approach.
- **Option A, simpler (recommended for this project): one merchant per cart.**
  1. In `addToCart` and `addRecipeToCart`, if the cart already has items from a different merchant, return 409 with `code: 'DIFFERENT_MERCHANT'`.
  2. In the app, on that error, show a dialog: "Your cart has items from another store. Clear the cart and add this item?"
  3. In `createOrder`, also reject if the items belong to more than one merchant. Don't trust the client.
- **Option B: split orders.** Group items by merchant and create one `Order` per merchant, linked by a shared `checkoutId`, with one payment for the total. This takes much more work (payment, refunds and tracking all need changes).

**How to check:** adding a product from a second merchant gives the 409. Sending mixed items straight to `POST /api/orders` returns 400.

**Prompt**
```
In this repository, the cart can hold products from several
merchants, but createOrder (backend/src/controllers/orderController.js)
assigns the whole order to the first item's merchant. Enforce one merchant
per cart:
1. Backend: in cartController.addToCart and addRecipeToCart, if the cart
   already has items whose product.merchant differs from the new product's
   merchant, respond 409 { success:false, code:'DIFFERENT_MERCHANT',
   message:'Your cart has items from another store' }. For addRecipeToCart,
   explain in your summary how you handled recipes whose ingredients come
   from several merchants (e.g. pick the closest merchant that stocks the
   most ingredients, or reject).
2. Backend: in createOrder, reject with 400 if the items span more than one
   merchant.
3. Flutter: find where the app calls add-to-cart (cart_controller.dart and
   the cart/product repositories). On a 409 with code DIFFERENT_MERCHANT,
   show a GetX dialog offering "Clear cart & add", which calls the
   clear-cart API and then retries the add.
Add backend Jest tests for both checks.
```

---

## Issue 12 — Order total ignores the preparation price 🟠

**Where**
- `cartController.addToCart`, line ~75: `finalPrice += option.additionalPrice`. The cart **charges extra** for preparation (cut, chopped, ...).
- `createOrder`, line ~70: `const subtotal = product.price * item.quantity;` The order **ignores** it.

**What goes wrong:** the cart shows ₹120 (₹100 + ₹20 for chopping), but the
order and payment are ₹100. The totals disagree, and the merchant does extra
work for free.

**Steps to fix**
1. In `createOrder`, look up the chosen preparation in `product.preparationOptions` and add its `additionalPrice` to the unit price, exactly as the cart does.
2. Move the price calculation into one helper (e.g. `src/utils/pricing.js → unitPrice(product, preparation)`) and use it in both the cart and the order.
3. The Order model only allows `['whole','cut','chopped','diced','sliced']` for `preparation`, and anything else is silently changed to `whole`. Make sure merchants can only create those option types, or widen the enum.

**Prompt**
```
In backend, the cart adds a preparation
option's additionalPrice to the item price (cartController.addToCart), but
orderController.createOrder computes subtotal as product.price * quantity,
so order totals are lower than cart totals. Create src/utils/pricing.js with
unitPrice(product, preparation) that matches the cart logic exactly, and use
it in both cartController (add/update and recipe-to-cart) and createOrder.
Store the unit price including preparation in order.items[].price. Also
check that the preparation option types merchants can save on Product match
the Order model's preparation enum; if not, tell me which values differ
rather than changing the enum yourself. Add a Jest test: cart total equals
order itemsTotal for an item with a 'chopped' option.
```

---

## Issue 13 — Coupon checks at order time are incomplete 🟠

**Where:** `createOrder`, lines ~106–147.

**What's wrong**
- The cart's `applyCoupon` checks usage limits (total and per-user), but `createOrder` **re-checks only the dates and minimum value**. Sending `couponCode` in the request body skips the cart and **skips the usage limits**, so the same coupon can be used many times.
- Merchant coupons are not checked against the order's merchant (`Offer.merchant`). Farmer A's coupon works on Farmer B's products.
- `usedCount` is increased **when the order is drafted**, even for online orders that are never paid, and is not decreased on cancel.
- `createOrder` checks `isActive: true`, while the cart checks `status: 'active'`. Make sure both fields actually exist and agree.

**Steps to fix**
1. Move the coupon validation into one function, `validateCoupon(offer, { userId, merchantId, itemsTotal })`. It checks dates, active state, minimum order value, `totalUsageLimit`, `usagePerUser` and the merchant. Use it in both `applyCoupon` and `createOrder`.
2. Increase the usage atomically, with the limit as part of the update condition:
   ```js
   Offer.findOneAndUpdate(
     { _id, $or: [{ totalUsageLimit: null }, { $expr: { $lt: ['$usedCount', '$totalUsageLimit'] } }] },
     { $inc: { usedCount: 1 }, $push: { usedBy: { user, usedAt } } }
   )
   ```
3. Store `appliedOfferId` on the order. On cancel, refund or expiry, decrease `usedCount` and remove the `usedBy` entry.

**Prompt**
```
In backend, coupon checks differ between
cartController.applyCoupon (checks totalUsageLimit and usagePerUser) and
orderController.createOrder (only dates and minOrderValue, and accepts
couponCode from the request body). Read src/models/Offer.js first. Create
src/utils/coupon.js with validateCoupon(offer, { userId, merchantId,
itemsTotal }) that checks active state (use whichever of isActive/status the
model really uses, consistently), dates, minOrderValue, totalUsageLimit,
usagePerUser and, for merchant-created offers, offer.merchant === merchantId,
and returns { ok, reason, discount }. Use it in both places. In createOrder,
reserve usage atomically with a findOneAndUpdate guarded by the usage limit;
save the offer id on the order (add an appliedOffer field to Order if
needed), and release the usage (decrement usedCount, pull the usedBy entry)
in the cancel/refund/expiry paths. Add Jest tests: per-user limit enforced
when couponCode is sent in the body; another merchant's coupon is rejected.
```

---

## Issue 14 — Delivery charge is always ₹50 🟠

**Where:** `createOrder`, line ~103:
`const deliveryCharges = deliveryType === 'pickup' ? 0 : 50;`

**What's wrong:** merchants set up delivery zones (`Merchant.deliveryZones[]`
with `radiusKm`, `deliveryCharge`, `freeDeliveryAbove`), and the Merchant also
has `deliveryCharges` and `freeDeliveryAbove`. The order ignores all of them,
and it doesn't check that the address is inside **any** zone. Loyalty tiers
also promise `freeDeliveryThreshold`, which is never applied.

**Steps to fix**
1. For home delivery, load the delivery `Address` and check it belongs to this user (`address.user === userId`). Reject otherwise. The code currently accepts any address ID.
2. Calculate the distance from the merchant's location to the address using `src/utils/haversine.js`. `deliveryZoneController` already has distance logic, so reuse it.
3. Pick the smallest zone whose `radiusKm` covers the distance. If none does, return 400 "Address is outside this store's delivery area".
4. Charge the zone's `deliveryCharge`, or 0 if `itemsTotal >= freeDeliveryAbove`, or 0 if the user's tier has `freeDeliveryThreshold` and `itemsTotal` reaches it. Fall back to the merchant-level `deliveryCharges` if there are no zones.
5. Show the same number in the app before ordering. Return it from a "quote" endpoint, or reuse `POST /api/merchants/zones/check-delivery`.

**Prompt**
```
In backend/src/controllers/orderController.js,
createOrder hard-codes deliveryCharges = 50 for home delivery and never
checks the delivery address. Read src/models/Merchant.js (deliveryCharges,
freeDeliveryAbove, deliveryZones[]), src/models/Address.js,
src/utils/haversine.js, src/controllers/deliveryZoneController.js (reuse its
distance/zone logic; extract it into a shared function if needed) and
src/config/loyaltyTiers.js. Then, for deliveryType 'home-delivery':
1. Require a deliveryAddress that belongs to req.user (400 otherwise).
2. Compute the distance merchant→address and pick the smallest covering
   active zone; return 400 if none covers it. If the merchant has no zones,
   fall back to merchant.deliveryCharges.
3. Delivery is free if itemsTotal >= the zone's (or merchant's)
   freeDeliveryAbove, or >= the user's tier freeDeliveryThreshold.
Keep pickup at 0. Make the 'free_delivery' coupon type offset the new charge.
Add Jest tests for in-zone, out-of-zone and free-above-threshold.
```

---

## Issue 15 — The app always places pickup orders 🟠

**Where:** `flutter_app/lib/modules/customer/checkout/checkout_screen.dart`, lines ~95–97:
```dart
addressId: null,
deliveryType: 'pickup',
```

**What's wrong:** checkout always sends `pickup` with no address, so customers
can never get home delivery. The address screens exist but checkout doesn't
use them. Wallet is also not offered as a payment method; only COD and Razorpay
appear in the list.

**Steps to fix**
1. Add a Delivery / Pickup toggle to the checkout screen.
2. For Delivery, show the address picker (`selectedAddress` already exists in the controller) and send `addressId: selectedAddress.value!.id` with `deliveryType: 'home-delivery'`. Block "Place order" until an address is chosen.
3. Show the delivery charge from the backend (Issue 14) in the order summary.
4. After Issues 3 and 4 are done, add `{'id': 'wallet', 'label': 'Wallet (₹<balance>)'}` to `paymentMethods`, and disable it when the balance is too low.
5. Remove the debug `print(...)` lines.

**Prompt**
```
In flutter_app/lib/modules/customer/checkout/checkout_screen.dart,
placeOrder always sends deliveryType 'pickup' and addressId null, so home
delivery is impossible. Add a Delivery/Pickup selector (GetX observable) to
the checkout UI. For Delivery, use the existing selectedAddress observable
and address list (see modules/customer/profile/addresses_screen.dart and the
user repository for how addresses are loaded), require an address before
placing the order, and send deliveryType 'home-delivery' with the selected
address id. Show the delivery charge returned by the backend in the
summary. Also add 'wallet' as a payment option showing the wallet balance
from WalletRepository, disabled when the balance is below the total. Remove
the debug print statements in this file. Follow the existing GB* widgets and
AppTheme for styling. Run `flutter analyze` on the changed files.
```

---

## Issue 16 — Merchant never receives the `order_paid` event 🟡

**Where:** `paymentController.verifyPayment`, line ~190: `const io = req.app.get('io');`
Nothing ever calls `app.set('io', ...)`, so `io` is undefined and the event is
silently skipped.

**Steps to fix:** replace the `req.app.get('io')` call with
`require('../config/socket').getIO()`, wrapped in try/catch, or call a helper
in `src/sockets/orderSocket.js` like the other events do. Also add an
`order_paid` listener in `flutter_app/lib/data/services/socket_service.dart`
so the merchant's order list refreshes.

**Prompt**
```
In backend/src/controllers/paymentController.js,
verifyPayment emits 'order_paid' via req.app.get('io'), but app.set('io') is
never called, so the event never fires. Add a notifyOrderPaid(merchantId,
payload) helper to src/sockets/orderSocket.js following the existing helpers
there, and call it instead. In flutter_app/lib/data/services/socket_service.dart,
add an 'order_paid' listener that follows the pattern of the 'new_order'
listener so the merchant orders screen refreshes.
```

---

# Phase 4 — Missing features

## Issue 17 — Gift cards are advertised but don't exist 🟠

**Where:** `server.js` `GET /api` lists nine `/api/gift-cards/...` endpoints,
and `backend/tests/giftCardController.test.js` requires
`src/controllers/giftCardController` and `src/models/GiftCard`. **Neither
file exists, and no route is mounted.** `docs/features/FEATURE_20_GIFT_CARDS_GUIDE.md`
describes the design.

**Decide first:**
- **Remove** (fast): delete the `giftCards` block from `/api`, delete or skip the test file, and mark the feature "planned" in the docs.
- **Build:** implement the model, controller and routes to satisfy the existing test file. The tests are your specification.

**Prompt (build)**
```
backend/tests/giftCardController.test.js
requires src/controllers/giftCardController.js and src/models/GiftCard.js,
which don't exist. Read that test file and
docs/features/FEATURE_20_GIFT_CARDS_GUIDE.md, then implement the model,
controller and src/routes/giftCardRoutes.js so the existing tests pass,
using the endpoints listed under giftCards in server.js's GET /api handler.
Mount the routes at /api/gift-cards. Gift card purchase must use Razorpay
the same way the wallet top-up does (read walletController.addMoney and
verifyTopup), and redemption must credit the wallet atomically. Don't
modify the test expectations; if a test looks wrong, tell me instead.
Run `npm run test:run -- giftCard` and show the output.
```

**Prompt (remove)**
```
Gift cards are not implemented in backend.
Remove the giftCards block and the 'Gift Cards & Vouchers' feature line from
the GET /api handler in server.js, fix the totalAPIs/total counts there to
match the routes actually mounted (count them from src/routes), and delete
tests/giftCardController.test.js. Add a note at the top of
docs/features/FEATURE_20_GIFT_CARDS_GUIDE.md saying the feature is planned
and not implemented.
```

---

## Issue 18 — Delivery agents are designed but not built 🟡

**Where:** `docs/DELIVERY_AGENT_SYSTEM.md`, `docs/DELIVERY_AGENT_IMPLEMENTATION.md`,
`template/agents.html`, `template/assign-orders.html`, and `AGENT_JWT_SECRET`
in `.env.example`. There is no model, controller or route.
`backend/fetch_creds.js` requires `src/models/Driver`, which doesn't exist, so
the script crashes.

**Steps:** for now, delete `fetch_creds.js` (or remove its Driver lines) and
mark the feature as planned. Building it is a large feature: an agent model
and login, order assignment, location updates, and an agent app or screens.
Plan it separately, using the two design docs.

**Prompt**
```
In backend, fetch_creds.js requires
src/models/Driver, which doesn't exist. Remove the Driver import and usage
from that script so it runs. Then read docs/DELIVERY_AGENT_SYSTEM.md and
docs/DELIVERY_AGENT_IMPLEMENTATION.md and write me a short implementation
plan (models, endpoints, socket events, Flutter screens, and the changes
needed in the order status flow) as docs/DELIVERY_AGENT_PLAN.md. Don't
implement it yet.
```

---

# Phase 5 — Security hardening and hygiene

## Issue 19 — CORS allows any site; one secret shared for everything 🟠

**Where:** `server.js:53` uses `origin: process.env.FRONTEND_URL || '*'`
(with `credentials: true`), and `src/config/socket.js` does the same.
`authMiddleware` and the socket both verify tokens with `JWT_SECRET`. Check
`authController.generateRefreshToken` to confirm that refresh tokens really
use `REFRESH_TOKEN_SECRET`.

**Steps**
1. In production, refuse to start if `FRONTEND_URL` is unset. Accept a comma-separated list of allowed origins. A mobile app sends no Origin header, so allow requests without one.
2. Make sure refresh tokens are signed with `REFRESH_TOKEN_SECRET` and can't be used as access tokens (add `tokenType` to the payload and check it in `authenticate`).
3. Make sure `JWT_SECRET` is at least 32 characters; refuse to start otherwise.

**Prompt**
```
Harden auth/CORS config in backend:
1. In server.js and src/config/socket.js, replace the `FRONTEND_URL || '*'`
   CORS origin with an allow-list parsed from a comma-separated
   CORS_ORIGINS env var; allow requests with no Origin header (mobile app);
   in production, exit with an error if CORS_ORIGINS is unset.
2. Check authController: refresh tokens must be signed with
   REFRESH_TOKEN_SECRET and carry tokenType:'refresh'; access tokens must
   carry tokenType:'access'. In authMiddleware.authenticate and the socket
   auth middleware, reject tokens whose tokenType isn't 'access'. Tokens
   issued before this change should still work until they expire: treat a
   missing tokenType as 'access'.
3. At startup, exit if JWT_SECRET is shorter than 32 characters when
   NODE_ENV === 'production'.
Update .env.example. Run the auth tests.
```

---

## Issue 20 — Repo clutter 🟡

**What:** `backend/` has about 55 one-off scripts in its root (`check_*`,
`debug_*`, `fix_*`, `seed_*`, `test_*`, `verify_*`, `move_papaya.js`, ...).
Also committed: `server_log*.txt`, `test_eval.dart` (inside the Node backend),
`flutter_app/ios/build/`, `.DS_Store` files, and three Postman collections.
The project folder had an auto-generated name (since renamed: `backend/` and `flutter_app/` are now at the top level).

**Steps**
1. Move the scripts worth keeping (seeders, `verify-geocoding`, `send-test-email`) into `backend/scripts/`. Delete the one-off fix and debug scripts. They're still in git history if you ever need them.
2. Run `git rm -r --cached` on `flutter_app/ios/build`, `**/.DS_Store` and `backend/server_log*.txt`, and add them to `.gitignore`.
3. Keep one Postman collection.
4. Optional: rename the project folder to `greenbasket/` (`git mv`), and update `.claude/launch.json` and any docs that mention the old path.

**Prompt**
```
Clean up backend without changing app
behaviour. List every .js/.dart/.txt file directly in backend/ (not in src/
or tests/) with a one-line description of what it does. Group them into
"keep → move to backend/scripts/" (seeders and reusable checks), "delete"
(one-off fixes, debugging, logs) and "unsure". Show me that list and wait
for my confirmation before moving or deleting anything. After I confirm:
use git mv/git rm, update package.json scripts that reference moved files,
untrack flutter_app/ios/build, all .DS_Store files and server_log*.txt, and
add them to the relevant .gitignore files.
```

---

## Issue 21 — Duplicate notification services and wrong API counts 🟡

**What**
- `src/services/` has `notification.js` (the main hub), `notificationService.js` (only re-exports `notification.js`), `notify.js` (fire-and-forget wrappers), and both `email.js` and `emailService.js`. Controllers use a mix of them.
- `GET /api` says `totalAPIs: 221` and `'20 features, 204 APIs'`, and lists gift cards. The route files define about 209 routes, and about 196 are mounted until Issue 4 is fixed.
- `template/*.html` mock-ups are branded "Groceasy".

**Prompt**
```
In backend/src/services, there are
overlapping notification modules: notification.js, notificationService.js
(an alias), notify.js, email.js and emailService.js. Map which controllers
use which module and which functions, then propose one structure (e.g.
notification.js as the hub plus channel modules email/sms/push) and show me
the proposal before changing code. After I approve, update the imports so
every controller uses the chosen modules, delete the unused ones, and run
the full test suite to show nothing broke.
```

---

## Issue 22 — Backend address hard-coded in the app 🟡

**Where:** `flutter_app/lib/config/constants.dart`:
`baseUrl = 'http://10.126.242.57:5002/api'`. It only works on one Wi-Fi
network, and must be edited by hand for an emulator, another network, or a
real server.

**Steps:** read the URL at build time:
```dart
static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:5002/api');
```
Then run with `flutter run --dart-define=API_URL=http://<your-ip>:5002/api`.
Do the same for `socketUrl`, deriving it from the API URL. Document the
command in `flutter_app/README.md`.

**Prompt**
```
In flutter_app/lib/config/constants.dart,
baseUrl and socketUrl are hard-coded to a LAN IP. Change them to read from
--dart-define: API_URL (default 'http://10.0.2.2:5002/api', the Android
emulator host) and derive socketUrl by stripping the trailing '/api'. Add a
"Running against your backend" section to flutter_app/README.md with
example flutter run commands for the Android emulator, iOS simulator
(localhost) and a real device (LAN IP).
```

---

## After all fixes

1. Run `npm run test:run` in `backend/`. Everything should pass, including the new tests.
2. Run `flutter analyze` and `flutter test` in `flutter_app/`.
3. Do a manual test pass in the app:
   - COD order
   - Razorpay order: pay, then fail, then abandon
   - Wallet order
   - Cancel at each status
   - Each merchant status change
   - Coupon reuse
   - Mixed-merchant cart
   - Delivery outside a zone
4. Update `PROJECT_OVERVIEW.md` §9 to mark the issues as fixed.
