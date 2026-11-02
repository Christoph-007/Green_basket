# Green Basket — Project Overview

Written from a full read of the repository (November 2026). It covers what the
app is, how it is built, where things live, and what is incomplete or broken.

---

## 1. What Green Basket is

Green Basket is a **marketplace for fresh and organic produce** that connects
local sellers (home growers, organic farmers, local farmers) with customers.
It has **three user roles**, each with its own part of one mobile app:

| Role | What they do |
|---|---|
| **Customer** | Browse and search produce, add to cart (including a whole recipe's ingredients), check out (COD / Razorpay / wallet), track orders live, review, earn loyalty points, use coupons, wishlist, pre-book seasonal items, raise returns and disputes. |
| **Merchant** (seller) | Signs up and waits for admin approval. Then manages products and stock (single or CSV bulk), accepts and advances orders, sets delivery zones, creates offers, and views analytics, earnings and payouts. |
| **Admin** | Approves or rejects merchants, manages users, categories, recipes and offers, resolves disputes and returns, generates and processes payouts, sets the commission rate, and sends bulk notifications. |

It was built as a college **mini project**; the report documents at the repo
root belong to that submission.

---

## 2. Repository layout

```
Green_basket/
├── backend/          ← Node.js + Express + MongoDB REST API
├── flutter_app/      ← Flutter mobile app (all 3 roles)
├── docs/             ← this overview, the bug-fix guide, Flutter API docs, the nearby-seller spec
├── design/           ← HTML admin mock-ups and the Pencil design file
└── .claude/launch.json  ← dev launcher: `npx nodemon server.js` on port 5002
```

---

## 3. Tech stack

### Backend (`backend/`)
- **Runtime:** Node.js ≥ 18, Express 4
- **Database:** MongoDB through Mongoose 8 (GeoJSON `Point` locations on users and merchants)
- **Auth:** JWT access tokens plus refresh tokens, bcrypt passwords, OTP model for email and phone verification
- **Real-time:** Socket.IO, JWT-authenticated, one room per identity (`<userType>_<id>`)
- **Payments:** Razorpay (orders, signature verification, webhook, refunds)
- **Notifications:** SendGrid email (Gmail SMTP fallback) with Handlebars templates, Twilio SMS, Firebase Cloud Messaging push, plus in-app notifications stored in MongoDB
- **Media:** Cloudinary + Multer (+ sharp)
- **Other:** helmet, CORS, express-rate-limit, Joi / express-validator, node-cron, ioredis (optional), csv-parse / csv-stringify
- **Tests:** Jest + Supertest + mongodb-memory-server

### Mobile app (`flutter_app/`)
- Flutter (Dart SDK ^3.10), **GetX** for state, DI and routing
- **Dio** HTTP client with an auth interceptor and automatic refresh-token retry
- `socket_io_client`, `get_storage` (local storage), Firebase Messaging, Google Maps, Geolocator / Geocoding, `razorpay_flutter`, `cached_network_image`, shimmer, pinput (OTP)
- Theme: green primary `#2E7D32`, orange secondary `#FFA726`
- Roughly **39,000 lines of Dart**

---

## 4. Backend architecture

`server.js` builds the Express app, attaches Socket.IO, applies helmet, CORS,
JSON parsing, morgan, a timing logger and the rate limiter, then mounts the
route modules. The Razorpay webhook is mounted **before** `express.json()` so it
can verify the raw request body. `GET /api` returns a self-describing list of
endpoints, and `GET /api/health` is the health check.

```
src/
├── config/       database, socket, razorpay, cloudinary, email, firebase, redis, loyaltyTiers, referral
├── models/       23 Mongoose models (see §5)
├── controllers/  27 controllers (~19k lines in src overall)
├── routes/       27 route files
├── middlewares/  authMiddleware, rate limiting, validation, upload, error handling
├── services/     notification (multi-channel hub), notify (fire-and-forget wrappers),
│                 email / sms / pushNotification, paymentService, geocodingService,
│                 recipeCalculator, uploadService, sendgridContactService
├── sockets/      orderSocket, notificationSocket, inventorySocket
├── cron/ utils/  cron jobs (placeholders), seeder, haversine, generateToken, walletHelpers, validators
└── templates/email/  12 Handlebars templates (welcome, OTP, order placed, status update, refund, ...)
```

### Auth model
`authenticate` decodes the JWT, which carries `{ id, userType }`, and loads the
account from **User**, **Merchant** or **Admin** depending on `userType`.
Blocked accounts are rejected. Role guards are `isUser`, `isMerchant` (which
also requires `verificationStatus === 'approved'`), `isAdmin`, and
`restrictTo(...roles)`. There is also a `unifiedLogin` endpoint alongside the
role-specific login endpoints.

### API surface (mounted under `/api`)

| Prefix | Area |
|---|---|
| `/auth` | signup/login per role, unified login, email verify, forgot/reset password, refresh, logout |
| `/products`, `/categories`, `/search`, `/home` | catalogue, advanced search/suggestions/trending, home feed |
| `/cart` | cart CRUD, **recipe-to-cart**, apply/remove coupon |
| `/orders` | create, my orders, merchant orders, status updates, cancel, review, live tracking/location |
| `/payment` (+ `/payment/webhook`) | Razorpay create/verify/refund/retry, history, status |
| `/recipes` | recipes, search, ingredient scaling for N servings |
| `/users`, `/merchants`, `/admin` | profiles, addresses, FCM tokens, notification prefs, store toggle, dashboards, verification, blocking, stats |
| `/reviews`, `/wishlist`, `/notifications`, `/loyalty`, `/offers` | the matching features |
| `/merchants/analytics`, `/merchants/zones` | sales/product/customer/inventory analytics and forecast; delivery zones, nearby merchants, delivery check |
| `/prebooking`, `/disputes`, `/returns` | pre-orders, dispute threads with escalation, returns |
| `/financial`, `/bulk` | earnings, payouts, GST and financial reports, commission settings; CSV bulk upload/export |

### Order lifecycle
`payment_pending → pending → confirmed → preparing → ready → out-for-delivery → delivered → completed`
(or `cancelled` / `refunded`). Every change is pushed onto `statusHistory`,
along with who made it (User, Merchant, Admin or System).

`createOrder` (in `orderController.js`) does the following:
1. Takes items from the request body, or from the cart if none are given.
2. Checks stock for each item and decrements it.
3. Assigns the order to the merchant of the first item.
4. Adds a delivery charge of ₹50, or ₹0 for pickup.
5. Applies the coupon, either pre-validated on the cart or sent as `couponCode`.
6. Clears the cart for COD and wallet orders. Online orders keep the cart until payment is verified.
7. Notifies the merchant (socket `new_order`, in-app, SMS) and the customer (push, email, SMS, in-app).

When a merchant marks an order `delivered` or `completed`, loyalty points are
awarded at 1 point per ₹10, multiplied by tier (bronze ×1, silver ×1, gold ×1.5,
platinum ×2). The tier is recalculated afterwards (bronze 0–499, silver 500–999,
gold 1000–2499, platinum 2500+).

### Money
The platform commission comes from `PlatformSettings` and defaults to **5%**.
Merchant net earnings are gross sales minus commission. Payouts are generated
and processed by admins, with a ₹1000 default minimum and a weekly schedule.

### Real-time events (server → client)
`new_order`, `order_status_update`, `order_location_update`, `order_cancelled`,
`order_count_update`, `notification`, `broadcast_notification`,
`low_stock_alert`, `stock_updated`, `out_of_stock`.

---

## 5. Data model (MongoDB collections)

| Model | Purpose |
|---|---|
| `User` | customer; dietary preferences and allergies, GeoJSON location, loyalty points/tier/history, referral code, FCM tokens, block flag |
| `Merchant` | seller; business type and selling model (retail/wholesale), address and location, FSSAI/GST/PAN, certifications, verification status, badges, ratings, operating hours, store open flag, delivery zones |
| `Admin` | platform administrator |
| `Product` | price/comparePrice, unit, stock and low-stock threshold, preparation options (cut, chopped, ...), images, nutrition, origin/harvest date, seasonality, status, ratings, sales/views, pre-bookable flag |
| `Category`, `Recipe` | catalogue and recipes (ingredients linked to products) |
| `Cart`, `Wishlist`, `Address` | shopping state |
| `Order` | items with preparation, totals, coupon, delivery type and slot, Razorpay IDs, payment events, refund, status history, tracking |
| `Offer`, `Coupon` | promotions, flash sales, coupon rules |
| `Review` | product and merchant reviews |
| `Wallet` | balance, transactions, lock flag |
| `LoyaltyLog` | points ledger |
| `PreBooking` | pre-orders for upcoming stock |
| `Dispute`, `Return`, `Ticket` | after-sales support |
| `Payout`, `PlatformSettings` | finance and global config |
| `Notification`, `OTP` | messaging and verification |

---

## 6. Flutter app architecture

```
lib/
├── main.dart, app.dart          GetStorage init, Firebase init, portrait lock, GetMaterialApp
├── config/                      routes.dart (~73 named routes), theme.dart, constants.dart (API base URL)
├── bindings/app_bindings.dart   registers ApiProvider, Storage, Socket, 10 repositories, Auth/Wishlist controllers
├── data/
│   ├── providers/api_provider.dart   Dio singleton: Bearer token, 401 → refresh → retry, else logout
│   ├── repositories/                 auth, product, order, user, merchant, admin, wallet, loyalty, notification, recipe, review
│   ├── models/                       user, product, cart, order, merchant, offer, wallet, loyalty, notification, recipe
│   └── services/                     socket, notification (FCM), location, storage
├── modules/
│   ├── auth/       splash (redirects by stored role), login, signup, OTP, forgot password
│   ├── customer/   shell + home, categories, product detail, search, recipes, cart, checkout,
│   │               orders (list/detail/tracking/success/review), profile (addresses, wallet,
│   │               loyalty, wishlist, referral, notifications, returns, disputes), offers
│   ├── merchant/   shell + dashboard, products (add/edit/stock/bulk), orders, disputes, analytics,
│   │               reviews, offers (+analytics), delivery zones, financial, payouts, store settings, profile
│   └── admin/      shell + dashboard, users, merchants (+analytics), orders, returns, disputes,
│                   products, categories, recipes, offers, finance, payouts, commission, bulk ops,
│                   notifications, settings
├── widgets/        GB* design-system widgets (app bar, button, card, text field, loader, empty state), product card
└── utils/          validators, helpers, responsive helper
```

**Navigation:** the splash screen reads the stored role and routes to
`/customer/home`, `/merchant/dashboard` or `/admin/dashboard`. Otherwise it
goes to `/login`.

**Backend address:** `constants.dart` points at a hard-coded LAN IP
(`http://10.126.242.57:5002/api`). Change it for your network, emulator
(`10.0.2.2`) or a deployed URL.

---

## 7. Documentation already in the repo

- `backend/docs/` holds about 80 markdown files: API references (an "ALL_103_APIS" list, per-controller docs), feature guides numbered 3–20, audits and fix reports, test-data references, a delivery-agent design, and a 13-part frontend specification (design system, screens, state/navigation, testing, deployment, security).
- `FLUTTER_DOCUMENTATION/`: API docs, models reference, route map and site map for the app.
- Postman collections (three) plus `POSTMAN_GUIDE.md`.

Many of these docs describe planned or earlier states. Where they disagree,
trust the code (`server.js` and `src/routes/`).

---

## 8. Running it locally

```bash
cd backend
npm install
cp .env.example .env      # fill MONGODB_URI, JWT secrets, and the Razorpay / Cloudinary / SendGrid / Twilio / Firebase keys you have
npm run seed              # optional: sample data (src/utils/seeder.js)
npm run dev               # nodemon; the app expects port 5002 (set PORT=5002)
npm run test:run          # Jest suite
```

```bash
cd flutter_app
flutter pub get
# edit lib/config/constants.dart → baseUrl / socketUrl
flutter run
```

`.env.example` uses port 5001, the code falls back to 6000, and the app and
`launch.json` expect **5002**. Set `PORT=5002`.

---

## 9. Gaps, bugs and risks found while reading

> **Update:** these issues, and many more found while fixing them, are fixed on the `fix/bugs` branch. See the status table at the top of `BUG_FIX_GUIDE.md`.

**Broken or unwired features**
1. **Wallet and referral APIs are not mounted.** `walletRoutes.js` and `referralRoutes.js` exist, but `server.js` never calls `app.use` for them. The Flutter app calls `/wallet/*` and `/referral`, so those screens get **404**s.
2. **Gift cards are advertised but missing.** `/api` lists nine gift-card endpoints, and `tests/giftCardController.test.js` requires `giftCardController` and a `GiftCard` model. Neither file exists, so that test file fails to load.
3. **Delivery agents are designed but not built.** There are docs, HTML templates (`agents.html`, `assign-orders.html`) and `AGENT_JWT_SECRET` in `.env.example`, but no agent or driver model or routes. `fetch_creds.js` requires a non-existent `src/models/Driver`.
4. **Cron jobs are placeholders** (`cronJobs.js` and the TODO in `reminderCron.js`).

**Order logic**
5. **One merchant per order, but carts can mix merchants.** The cart allows products from several merchants, and `createOrder` assigns the whole order to the first item's merchant.
6. **Stock is decremented item by item before the whole order is validated.** If a later item fails (not found or out of stock), the earlier items stay decremented. A MongoDB transaction would fix this.
7. **The delivery charge is a flat ₹50** even though merchants configure per-zone delivery charges. Tier-based free-delivery thresholds aren't applied here either.

**Security and hygiene**
8. **`debug_analytics.js`, `seed_kumar_data.js` and `check_prod_db.js` appear to contain hard-coded MongoDB Atlas connection strings.** `backend/.token` looks like a committed auth token, and `dump.rdb` is a committed Redis dump. Rotate those credentials and remove the files from git history.
9. Server logs (`server_log*.txt`) and iOS build caches (`ios/build/...`) are committed. Add them to `.gitignore`.
10. **CORS allows `*`** when `FRONTEND_URL` is unset, and the access JWT and socket JWT share one secret.

**Clutter**
11. `backend/` contains about 60 one-off `check_*`, `debug_*`, `fix_*`, `seed_*` and `test_*` scripts. Move the useful ones into `scripts/` and delete the rest.
12. `services/` has overlapping notification modules (`notification.js`, `notificationService.js` as an alias, `notify.js`, `emailService.js` vs `email.js`). `totalAPIs` in `/api` says 221 while the features list says 204.
13. The `template/` HTML mock-ups are branded "Groceasy", not Green Basket.

---

## 10. Suggested next steps (in order)
1. Mount `walletRoutes` and `referralRoutes` in `server.js`: a two-line fix that unblocks two app screens.
2. Rotate and remove the committed credentials (§9.8).
3. Either restrict carts to one merchant or split checkout into one order per merchant, and wrap `createOrder` in a transaction.
4. Use delivery-zone pricing in `createOrder`.
5. Build or drop gift cards and delivery agents, and fix the failing gift-card test accordingly.
6. Move the base URL into a build-time config (`--dart-define`) and clean up the repo root.
