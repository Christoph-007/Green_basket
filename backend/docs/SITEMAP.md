# 🗺️ GreenBasket — Complete Sitemap (All 4 Panels)

> Generated from raw code analysis of 33 route files, 28 model files, and all controllers.
> Source of truth: Backend code only. No existing docs referenced.

---

# PART A — ADMIN PANEL

---

## A1. Authentication

### A1.1 Admin Login
- **Route:** `/login`
- **Purpose:** Authenticate admin users into the panel
- **Backend:** `POST /api/auth/admin/login`

---

## A2. Dashboard

### A2.1 Admin Dashboard (Home)
- **Route:** `/dashboard`
- **Purpose:** Overview of platform-wide statistics and activity
- **Backend:** `GET /api/admin/stats`
- **Sub-sections:**
  - Total users, merchants, orders, revenue summary
  - Recent orders list
  - Pending merchant verifications count
  - Orders needing manual delivery assignment

---

## A3. User Management

### A3.1 All Users
- **Route:** `/users`
- **Purpose:** View, search, and manage all registered customers
- **Backend:** `GET /api/admin/users`

### A3.2 User Detail
- **Route:** `/users/:id`
- **Purpose:** View user profile, block/unblock user
- **Backend:**
  - `PATCH /api/admin/users/:id/block`

---

## A4. Merchant Management

### A4.1 All Merchants
- **Route:** `/merchants`
- **Purpose:** View all merchants with their verification status
- **Backend:** `GET /api/admin/merchants`

### A4.2 Pending Merchant Approvals
- **Route:** `/merchants/pending`
- **Purpose:** Review and approve/reject merchant applications
- **Backend:**
  - `GET /api/admin/merchants/pending`
  - `PATCH /api/admin/merchants/:id/verify`

### A4.3 Merchant Detail
- **Route:** `/merchants/:id`
- **Purpose:** View full merchant profile, business info, documents, badges

---

## A5. Product Management

### A5.1 All Products
- **Route:** `/products`
- **Backend:** `GET /api/products`

### A5.2 Product Detail
- **Route:** `/products/:id`
- **Backend:** `GET /api/products/:id`

---

## A6. Category Management

### A6.1 Categories (CRUD)
- **Route:** `/categories`
- **Backend:**
  - `GET /api/categories`
  - `POST /api/categories` (Admin)
  - `PUT /api/categories/:id` (Admin)
  - `DELETE /api/categories/:id` (Admin)

---

## A7. Order Management

### A7.1 All Orders
- **Route:** `/orders`
- **Purpose:** View all platform orders, filter by status

### A7.2 Order Detail
- **Route:** `/orders/:id`
- **Backend:**
  - `GET /api/orders/:id`
  - `GET /api/orders/:id/track`
  - `GET /api/orders/:orderId/tracking`

### A7.3 Assign Delivery Agent
- **Route:** `/orders/:id/assign` (action)
- **Backend:** `POST /api/admin/orders/:orderId/assign-agent`

---

## A8. Recipe Management

### A8.1 All Recipes
- **Route:** `/recipes`
- **Backend:** `GET /api/recipes`, `GET /api/recipes/search`

### A8.2 Create/Edit Recipe
- **Route:** `/recipes/new`, `/recipes/:id/edit`
- **Backend:** `POST /api/recipes`, `PUT /api/recipes/:id`, `PATCH /api/recipes/:id`, `DELETE /api/recipes/:id` (Admin)

### A8.3 Recipe Detail
- **Route:** `/recipes/:id`
- **Backend:** `GET /api/recipes/:id`, `GET /api/recipes/:id/calculate-ingredients`

---

## A9. Review Moderation

### A9.1 Product Reviews
- **Route:** `/reviews/products`
- **Backend:** `GET /api/reviews/product/:productId`

### A9.2 Merchant Reviews
- **Route:** `/reviews/merchants`
- **Backend:** `GET /api/reviews/merchant/:merchantId`

### A9.3 Delete Review
- **Backend:** `DELETE /api/reviews/:id` (Admin)

---

## A10. Notification Center

- **Route:** `/notifications`
- **Backend:**
  - `POST /api/notifications/admin/test`
  - `POST /api/notifications/admin/bulk-send`

---

## A11. Offers & Coupons

### A11.1 All Offers
- **Route:** `/offers`
- **Backend:** `GET /api/offers/admin/all`, `POST /api/offers`, `PUT /api/offers/:id`, `DELETE /api/offers/:id`

### A11.2 Offer Analytics
- **Route:** `/offers/:id/analytics`
- **Backend:** `GET /api/offers/:id/analytics`

---

## A12. Financial Management

### A12.1 Payouts
- **Route:** `/finance/payouts`
- **Backend:** `GET /api/financial/admin/payouts`, `POST /api/financial/admin/payouts/generate`, `POST /api/financial/admin/payouts/:id/process`, `PATCH /api/financial/admin/payouts/:id/hold`

### A12.2 Financial Reports
- **Route:** `/finance/reports`
- **Backend:** `GET /api/financial/admin/reports/financial`, `GET /api/financial/admin/reports/gst`

### A12.3 Commission Settings
- **Route:** `/finance/settings`
- **Backend:** `PUT /api/financial/admin/settings/commission`

---

## A13. Wallet Admin Controls

- **Route:** `/wallets`
- **Backend:** `POST /api/wallet/admin/credit`, `PATCH /api/wallet/admin/:userId/lock`, `POST /api/wallet/credit-refund`

---

## A14. Loyalty Management

- **Route:** `/loyalty`
- **Backend:** `POST /api/loyalty/admin/award-points`

---

## A15. Referral Management

- **Route:** `/referrals`
- **Backend:** `POST /api/referral/process-reward`

---

## A16. Dispute Management

### A16.1 All Disputes
- **Route:** `/disputes`
- **Backend:** `GET /api/disputes/admin/all`

### A16.2 Dispute Detail
- **Route:** `/disputes/:id`
- **Backend:** `GET /api/disputes/:id`, `PUT /api/disputes/admin/:id/resolve`, `PATCH /api/disputes/admin/:id/status`, `POST /api/disputes/:id/message`

---

## A17. Return Management

### A17.1 All Returns
- **Route:** `/returns`
- **Backend:** `GET /api/returns/admin/all`

### A17.2 Process Return
- **Backend:** `PUT /api/returns/admin/:id/process`

---

## A18. Gift Card Management

- **Route:** `/gift-cards`
- **Backend:** `GET /api/gift-cards/admin/all`, `POST /api/gift-cards/admin/generate`, `PATCH /api/gift-cards/admin/:id/toggle`, `DELETE /api/gift-cards/admin/:id/cancel`

---

## A19. Membership Management

- **Route:** `/memberships`
- **Backend:** `GET /api/membership/admin/all`

---

## A20. Pre-Booking Management

- **Route:** `/pre-bookings`
- **Backend:** `GET /api/prebooking/admin/all`

---

## A21. Document Verification

### A21.1 Pending Documents
- **Route:** `/documents/pending`
- **Backend:** `GET /api/documents/admin/pending`, `PUT /api/documents/admin/:merchantId/:documentId/verify`

### A21.2 Expiring Documents
- **Route:** `/documents/expiring`
- **Backend:** `GET /api/documents/admin/expiring-soon`

---

## A22. Delivery Agent Management

### A22.1 All Agents
- **Route:** `/agents`
- **Backend:** `GET /api/admin/agents`, `GET /api/admin/agents/analytics`

### A22.2 Agent Detail
- **Route:** `/agents/:id`
- **Backend:** `GET /api/admin/agents/:id`, `GET /api/admin/agents/:id/assignments`, `PATCH /api/admin/agents/:id/verify`, `PATCH /api/admin/agents/:id/toggle-active`

---

## A23. Search & Uploads

- **Search:** `GET /api/search`, `GET /api/search/suggestions`, `GET /api/search/trending`
- **Uploads:** `POST /api/upload/image`, `POST /api/upload/images`, `POST /api/upload/document`, `GET /api/upload/my-uploads`, `DELETE /api/upload/:uploadId`, `POST /api/upload/bulk-delete`

---

### Admin Panel Navigation Tree

```
ADMIN PANEL
├── Login
├── Dashboard
├── Users (All Users / User Detail)
├── Merchants (All / Pending / Detail)
├── Products (All / Detail)
├── Categories (CRUD)
├── Orders (All / Detail / Assign Agent)
├── Recipes (All / Create / Edit / Detail)
├── Reviews (Product / Merchant / Moderate)
├── Subscriptions
├── Notifications (Send)
├── Offers & Coupons (All / Analytics)
├── Finance (Payouts / Reports / Settings)
├── Wallets (Credit / Lock)
├── Loyalty (Award Points)
├── Referrals (Process Rewards)
├── Disputes (All / Detail / Resolve)
├── Returns (All / Process)
├── Gift Cards (All / Generate)
├── Memberships
├── Pre-Bookings
├── Documents (Pending / Expiring)
├── Delivery Agents (All / Detail)
└── Uploads
```

---

---

# PART B — MERCHANT PANEL

---

## B1. Authentication

### B1.1 Merchant Signup
- **Route:** `/signup`
- **Purpose:** Register new merchant account
- **Backend:** `POST /api/auth/merchant/signup`

### B1.2 Merchant Login
- **Route:** `/login`
- **Purpose:** Authenticate merchant
- **Backend:** `POST /api/auth/merchant/login`

---

## B2. Merchant Dashboard

### B2.1 Dashboard Home
- **Route:** `/dashboard`
- **Purpose:** Overview of merchant business stats
- **Backend:** `GET /api/merchants/dashboard-stats`
- **Sub-sections:**
  - Total orders, revenue, active products count
  - Store open/closed toggle
  - Recent orders

---

## B3. Merchant Profile

### B3.1 View/Edit Profile
- **Route:** `/profile`
- **Purpose:** View and update business profile (name, address, operating hours, delivery settings, bank details, certifications)
- **Backend:**
  - `GET /api/merchants/profile`
  - `PUT /api/merchants/profile`

### B3.2 Toggle Store Status
- **Route:** — (action on Dashboard or Profile page)
- **Purpose:** Open/close store or enable vacation mode
- **Backend:** `PATCH /api/merchants/toggle-store`

---

## B4. Product Management

### B4.1 My Products
- **Route:** `/products`
- **Purpose:** View, create, edit, delete own products
- **Backend:**
  - `GET /api/products` (filtered by merchant)
  - `POST /api/products` (Merchant)
  - `PUT /api/products/:id` (Merchant)
  - `DELETE /api/products/:id` (Merchant)

### B4.2 Stock Management
- **Route:** `/products/:id/stock` (action)
- **Purpose:** Update product stock
- **Backend:** `PATCH /api/products/:id/stock` (Merchant)

### B4.3 Bulk Operations
- **Route:** `/products/bulk`
- **Purpose:** Bulk upload, price update, stock update, export
- **Backend:**
  - `POST /api/bulk/products/bulk-upload` (Merchant, file upload)
  - `PUT /api/bulk/products/bulk-update-price` (Merchant)
  - `PUT /api/bulk/products/bulk-update-stock` (Merchant)
  - `GET /api/bulk/products/export` (Merchant)

---

## B5. Order Management

### B5.1 Merchant Orders
- **Route:** `/orders`
- **Purpose:** View all orders assigned to this merchant
- **Backend:** `GET /api/orders/merchant/orders`

### B5.2 Update Order Status
- **Route:** `/orders/:id` (action)
- **Purpose:** Advance order through statuses (confirmed → preparing → ready)
- **Backend:** `PATCH /api/orders/merchant/:id/status`

---

## B6. Analytics

### B6.1 Sales Analytics
- **Route:** `/analytics/sales`
- **Backend:** `GET /api/merchants/analytics/sales`

### B6.2 Product Analytics
- **Route:** `/analytics/products`
- **Backend:** `GET /api/merchants/analytics/products`

### B6.3 Customer Analytics
- **Route:** `/analytics/customers`
- **Backend:** `GET /api/merchants/analytics/customers`

### B6.4 Inventory Analytics
- **Route:** `/analytics/inventory`
- **Backend:** `GET /api/merchants/analytics/inventory`

### B6.5 Revenue Forecast
- **Route:** `/analytics/forecast`
- **Backend:** `GET /api/merchants/analytics/forecast`

### B6.6 Review Analytics
- **Route:** `/analytics/reviews`
- **Backend:** `GET /api/merchants/analytics/reviews`

---

## B7. Delivery Zones

### B7.1 Zone Management
- **Route:** `/delivery-zones`
- **Purpose:** Set merchant location, manage delivery zones, check serviceability
- **Backend:**
  - `PUT /api/merchants/zones/location` (Merchant)
  - `POST /api/merchants/zones/delivery-zones` (Merchant)
  - `PUT /api/merchants/zones/delivery-zones/:zoneId` (Merchant)
  - `DELETE /api/merchants/zones/delivery-zones/:zoneId` (Merchant)
  - `POST /api/merchants/zones/check-serviceability` (Merchant)

---

## B8. Financial

### B8.1 Earnings
- **Route:** `/finance/earnings`
- **Backend:** `GET /api/financial/merchants/earnings`

### B8.2 Payouts
- **Route:** `/finance/payouts`
- **Backend:** `GET /api/financial/merchants/payouts`

### B8.3 Payout Detail
- **Route:** `/finance/payouts/:id`
- **Backend:** `GET /api/financial/payouts/:id`

---

## B9. Offers & Coupons

### B9.1 My Offers
- **Route:** `/offers`
- **Purpose:** Create and manage merchant-specific offers
- **Backend:**
  - `GET /api/offers/merchant` (Merchant)
  - `POST /api/offers` (Merchant)
  - `PUT /api/offers/:id` (Merchant)
  - `DELETE /api/offers/:id` (Merchant)
  - `GET /api/offers/:id/analytics` (Merchant)

---

## B10. Pre-Booking Management

### B10.1 Merchant Pre-Bookings
- **Route:** `/pre-bookings`
- **Purpose:** View pre-bookings for merchant's products, mark available, update status, configure settings
- **Backend:**
  - `GET /api/prebooking/merchant/all` (Merchant)
  - `PATCH /api/prebooking/products/:id/mark-available` (Merchant)
  - `PATCH /api/prebooking/:id/update-status` (Merchant)
  - `PATCH /api/prebooking/merchant/products/:productId/prebooking` (Merchant)

---

## B11. Document Management

### B11.1 My Documents
- **Route:** `/documents`
- **Purpose:** Upload, view, and manage verification documents
- **Backend:**
  - `POST /api/documents/upload` (Merchant)
  - `GET /api/documents` (Merchant)
  - `GET /api/documents/history` (Merchant)
  - `DELETE /api/documents/:documentId` (Merchant)

---

## B12. Subscriptions

### B12.1 Merchant Subscriptions
- **Route:** `/subscriptions`
- **Purpose:** View recurring delivery subscriptions for this merchant
- **Backend:** `GET /api/subscriptions/merchant/all` (Merchant)

---

## B13. Reviews

### B13.1 My Reviews
- **Route:** `/reviews`
- **Purpose:** View reviews left for this merchant's products
- **Backend:** `GET /api/reviews/merchant/:merchantId`

---

## B14. Notifications

### B14.1 Notifications Inbox
- **Route:** `/notifications`
- **Purpose:** View notifications (new orders, low stock, etc.)
- **Backend:**
  - `GET /api/notifications`
  - `GET /api/notifications/unread-count`
  - `PATCH /api/notifications/read-all`
  - `PATCH /api/notifications/:id/read`
  - `DELETE /api/notifications/:id`
  - `DELETE /api/notifications/clear-all`

---

## B15. Uploads

### B15.1 Image/Document Uploads
- **Route:** `/uploads`
- **Backend:**
  - `POST /api/upload/image`
  - `POST /api/upload/images`
  - `POST /api/upload/document` (Merchant)
  - `PUT /api/upload/products/:productId/images` (Merchant)
  - `GET /api/upload/my-uploads`
  - `DELETE /api/upload/:uploadId`
  - `POST /api/upload/bulk-delete` (Merchant)

---

### Merchant Panel Navigation Tree

```
MERCHANT PANEL
├── Login / Signup
├── Dashboard (Stats + Store Toggle)
├── Profile (View / Edit)
├── Products
│   ├── My Products (CRUD)
│   ├── Stock Management
│   └── Bulk Operations (Upload / Price / Stock / Export)
├── Orders (Merchant Orders / Update Status)
├── Analytics
│   ├── Sales
│   ├── Products
│   ├── Customers
│   ├── Inventory
│   ├── Forecast
│   └── Reviews
├── Delivery Zones (CRUD + Serviceability)
├── Finance (Earnings / Payouts)
├── Offers (My Offers / Create / Analytics)
├── Pre-Bookings (View / Mark Available)
├── Documents (Upload / View / History)
├── Subscriptions (Merchant Subscriptions)
├── Reviews (My Reviews)
├── Notifications (Inbox)
└── Uploads
```

---

---

# PART C — USER (CUSTOMER) PANEL

---

## C1. Authentication

### C1.1 User Signup
- **Route:** `/signup`
- **Backend:** `POST /api/auth/user/signup`

### C1.2 User Login
- **Route:** `/login`
- **Backend:** `POST /api/auth/user/login`

### C1.3 Email Verification
- **Route:** `/verify-email`
- **Backend:** `POST /api/auth/user/verify-email`

### C1.4 Forgot Password
- **Route:** `/forgot-password`
- **Backend:** `POST /api/auth/user/forgot-password`

### C1.5 Reset Password
- **Route:** `/reset-password`
- **Backend:** `POST /api/auth/user/reset-password`

### C1.6 Token Management
- **Backend:** `POST /api/auth/refresh-token`, `POST /api/auth/logout`

---

## C2. Home / Browse

### C2.1 Home Page
- **Route:** `/home`
- **Purpose:** Browse categories, featured products, search
- **Backend:**
  - `GET /api/categories`
  - `GET /api/products`
  - `GET /api/search`
  - `GET /api/search/suggestions`
  - `GET /api/search/trending`
  - `GET /api/offers/flash-sales` (public)

### C2.2 Product Listing
- **Route:** `/products`
- **Purpose:** View all products, filter/search
- **Backend:**
  - `GET /api/products`
  - `GET /api/products/search`

### C2.3 Product Detail
- **Route:** `/products/:id`
- **Purpose:** View product info, reviews, add to cart/wishlist
- **Backend:**
  - `GET /api/products/:id`
  - `GET /api/reviews/product/:productId`

### C2.4 Category View
- **Route:** `/categories/:id`
- **Backend:** `GET /api/categories/:id`

---

## C3. Cart

### C3.1 Cart Page
- **Route:** `/cart`
- **Purpose:** View cart, update quantities, remove items, apply coupons
- **Backend:**
  - `GET /api/cart`
  - `POST /api/cart/add`
  - `PUT /api/cart/update/:productId`
  - `DELETE /api/cart/remove/:productId`
  - `DELETE /api/cart/clear`
  - `POST /api/cart/recipe-to-cart`
  - `POST /api/offers/cart/apply-coupon`
  - `DELETE /api/offers/cart/remove-coupon`

---

## C4. Checkout & Orders

### C4.1 Checkout
- **Route:** `/checkout`
- **Purpose:** Select address, payment method, delivery slot, place order
- **Backend:**
  - `POST /api/orders`
  - `POST /api/payment/create-order`
  - `POST /api/payment/verify`
  - `GET /api/payment/methods`

### C4.2 My Orders
- **Route:** `/orders`
- **Purpose:** View all past and current orders
- **Backend:** `GET /api/orders/my-orders`

### C4.3 Order Detail
- **Route:** `/orders/:id`
- **Purpose:** View order info, track delivery, cancel order
- **Backend:**
  - `GET /api/orders/:id`
  - `GET /api/orders/:id/track`
  - `GET /api/orders/:orderId/tracking`
  - `PATCH /api/orders/:id/cancel`
  - `PATCH /api/orders/:id/location`

### C4.4 Payment Status
- **Route:** `/orders/:id/payment`
- **Backend:**
  - `GET /api/payment/:orderId/status`
  - `POST /api/payment/:orderId/retry`
  - `GET /api/payment/history`

---

## C5. Recipes

### C5.1 Browse Recipes
- **Route:** `/recipes`
- **Backend:** `GET /api/recipes`, `GET /api/recipes/search`

### C5.2 Recipe Detail
- **Route:** `/recipes/:id`
- **Purpose:** View recipe, calculate ingredients per servings, add ingredients to cart
- **Backend:**
  - `GET /api/recipes/:id`
  - `GET /api/recipes/:id/calculate-ingredients`
  - `POST /api/cart/recipe-to-cart`

---

## C6. Wishlist

### C6.1 My Wishlist
- **Route:** `/wishlist`
- **Purpose:** View saved products, move to cart
- **Backend:**
  - `GET /api/wishlist`
  - `POST /api/wishlist/add`
  - `DELETE /api/wishlist/remove/:productId`
  - `POST /api/wishlist/move-to-cart/:productId`
  - `GET /api/wishlist/check/:productId`

---

## C7. User Profile

### C7.1 Profile
- **Route:** `/profile`
- **Purpose:** View/edit name, phone, dietary preferences, allergies, profile image
- **Backend:**
  - `GET /api/users/profile`
  - `PUT /api/users/profile`

### C7.2 Addresses
- **Route:** `/profile/addresses`
- **Purpose:** Manage delivery addresses (CRUD)
- **Backend:**
  - `GET /api/users/addresses`
  - `POST /api/users/addresses`
  - `PUT /api/users/addresses/:id`
  - `DELETE /api/users/addresses/:id`

### C7.3 Notification Preferences
- **Route:** `/profile/notifications`
- **Purpose:** Toggle email, push, SMS notification categories
- **Backend:**
  - `GET /api/users/notification-preferences`
  - `PUT /api/users/notification-preferences`

### C7.4 FCM Token Registration
- **Backend:** `POST /api/users/fcm-token`

---

## C8. Wallet

### C8.1 My Wallet
- **Route:** `/wallet`
- **Purpose:** View balance, add money, transaction history, use for payment
- **Backend:**
  - `GET /api/wallet`
  - `GET /api/wallet/transactions`
  - `POST /api/wallet/add-money`
  - `POST /api/wallet/verify-topup`
  - `POST /api/wallet/use-for-payment`

---

## C9. Loyalty & Rewards

### C9.1 Loyalty Page
- **Route:** `/loyalty`
- **Purpose:** View points, tier, benefits, redeem points, history
- **Backend:**
  - `POST /api/loyalty/redeem`
  - `GET /api/loyalty/history`
  - `GET /api/loyalty/tier-benefits`

---

## C10. Referrals

### C10.1 Referral Page
- **Route:** `/referrals`
- **Purpose:** Generate referral code, view stats, apply referral
- **Backend:**
  - `POST /api/referral/generate`
  - `GET /api/referral/stats`
  - `POST /api/referral/apply`
  - `GET /api/referral/validate/:code`

---

## C11. Membership

### C11.1 Membership Page
- **Route:** `/membership`
- **Purpose:** View plans, subscribe, manage membership
- **Backend:**
  - `GET /api/membership/plans`
  - `GET /api/membership/my-membership`
  - `POST /api/membership/initiate`
  - `POST /api/membership/activate`
  - `POST /api/membership/cancel`
  - `GET /api/membership/premium-products`
  - `GET /api/membership/history`

---

## C12. Gift Cards

### C12.1 Gift Cards Page
- **Route:** `/gift-cards`
- **Purpose:** Purchase, redeem, view gift cards
- **Backend:**
  - `GET /api/gift-cards/balance/:code` (public)
  - `POST /api/gift-cards/validate`
  - `POST /api/gift-cards/redeem`
  - `GET /api/gift-cards/my-cards`
  - `POST /api/gift-cards/purchase/initiate`
  - `POST /api/gift-cards/purchase/verify`

---

## C13. Pre-Bookings

### C13.1 My Pre-Bookings
- **Route:** `/pre-bookings`
- **Purpose:** Pre-book seasonal products, view bookings, convert to order
- **Backend:**
  - `POST /api/prebooking`
  - `GET /api/prebooking/my-prebookings`
  - `DELETE /api/prebooking/:id`
  - `POST /api/prebooking/:id/convert-to-order`

---

## C14. Subscriptions

### C14.1 My Subscriptions
- **Route:** `/subscriptions`
- **Purpose:** Create and manage recurring delivery subscriptions
- **Backend:**
  - `POST /api/subscriptions`
  - `GET /api/subscriptions`
  - `GET /api/subscriptions/:id`
  - `PUT /api/subscriptions/:id`
  - `DELETE /api/subscriptions/:id`
  - `PATCH /api/subscriptions/:id/status`

---

## C15. Offers

### C15.1 Available Offers
- **Route:** `/offers`
- **Purpose:** Browse available offers and flash sales
- **Backend:**
  - `GET /api/offers/available`
  - `GET /api/offers/flash-sales` (public)

---

## C16. Reviews

### C16.1 Write/Manage Reviews
- **Route:** `/reviews`
- **Purpose:** Add, edit, delete reviews on delivered orders
- **Backend:**
  - `POST /api/reviews`
  - `GET /api/reviews/my-reviews`
  - `PUT /api/reviews/:id`
  - `DELETE /api/reviews/:id`

---

## C17. Disputes

### C17.1 My Disputes
- **Route:** `/disputes`
- **Purpose:** Raise, view, and escalate disputes
- **Backend:**
  - `POST /api/disputes`
  - `GET /api/disputes/my-disputes`
  - `GET /api/disputes/:id`
  - `POST /api/disputes/:id/message`
  - `PATCH /api/disputes/:id/escalate`

---

## C18. Returns

### C18.1 My Returns
- **Route:** `/returns`
- **Purpose:** Request returns/exchanges, view status
- **Backend:**
  - `POST /api/returns`
  - `GET /api/returns/my-returns`
  - `GET /api/returns/:id`
  - `DELETE /api/returns/:id`

---

## C19. Notifications

### C19.1 Notification Inbox
- **Route:** `/notifications`
- **Purpose:** View in-app notifications
- **Backend:**
  - `GET /api/notifications`
  - `GET /api/notifications/unread-count`
  - `PATCH /api/notifications/read-all`
  - `PATCH /api/notifications/:id/read`
  - `DELETE /api/notifications/:id`
  - `DELETE /api/notifications/clear-all`

---

### User Panel Navigation Tree

```
USER (CUSTOMER) PANEL
├── Login / Signup / Forgot Password / Verify Email
├── Home (Categories / Search / Flash Sales)
├── Products (Browse / Search / Detail)
├── Cart (Add / Update / Remove / Apply Coupon)
├── Checkout (Address / Payment / Place Order)
├── Orders
│   ├── My Orders
│   ├── Order Detail
│   ├── Track Order
│   └── Cancel Order
├── Recipes (Browse / Detail / Add to Cart)
├── Wishlist (Add / Remove / Move to Cart)
├── Profile
│   ├── Edit Profile
│   ├── Addresses (CRUD)
│   └── Notification Preferences
├── Wallet (Balance / Add Money / Transactions)
├── Loyalty (Points / Tier / Redeem)
├── Referrals (Generate / Share / Apply)
├── Membership (Plans / Subscribe / Cancel)
├── Gift Cards (Buy / Redeem / Balance)
├── Pre-Bookings (Book / View / Convert)
├── Subscriptions (Create / Manage)
├── Offers (Available / Flash Sales)
├── Reviews (Write / Edit / My Reviews)
├── Disputes (Raise / View / Escalate)
├── Returns (Request / View / Cancel)
└── Notifications (Inbox)
```

---

---

# PART D — DELIVERY AGENT PANEL

---

## D1. Authentication

### D1.1 Agent Registration
- **Route:** `/register`
- **Purpose:** Register new delivery agent account (pending admin verification)
- **Backend:** `POST /api/agents/register`

### D1.2 Agent Login
- **Route:** `/login`
- **Purpose:** Authenticate delivery agent
- **Backend:** `POST /api/agents/login`

---

## D2. Agent Dashboard

### D2.1 Dashboard Home
- **Route:** `/dashboard`
- **Purpose:** Overview of current assignment, status toggle, today's earnings
- **Backend:**
  - `GET /api/agents/assignments/current` — Active delivery
  - `GET /api/agents/earnings` — Earnings summary
  - `PUT /api/agents/me/status` — Go Available / Offline

---

## D3. Profile

### D3.1 View/Edit Profile
- **Route:** `/profile`
- **Purpose:** View and update personal info, vehicle details, profile photo
- **Backend:**
  - `GET /api/agents/me`
  - `PUT /api/agents/me`

---

## D4. Status & Location

### D4.1 Online/Offline Toggle
- **Route:** — (action on Dashboard/nav bar)
- **Purpose:** Toggle between available/offline status (requires verification to go available)
- **Backend:** `PUT /api/agents/me/status`

### D4.2 Location Update
- **Route:** — (background service)
- **Purpose:** Continuously update current GPS location for live tracking
- **Backend:** `POST /api/agents/me/location`

---

## D5. Current Assignment

### D5.1 Active Delivery
- **Route:** `/assignments/current`
- **Purpose:** View current active delivery with order details, customer info, delivery address, map
- **Backend:** `GET /api/agents/assignments/current`
- **Populated Data:**
  - Order: orderId, items, totalAmount, deliveryAddress, deliveryInstructions
  - Customer: name, phone
  - Address: fullAddress, street, city, state, pincode, location coordinates

### D5.2 Update Delivery Status
- **Route:** — (actions on current assignment page)
- **Purpose:** Progress delivery through stages
- **Backend:** `PUT /api/agents/assignments/:id/status`
- **Valid Transitions:**
  - `assigned` → `picked_up` or `failed`
  - `picked_up` → `in_transit` or `failed`
  - `in_transit` → `delivered` or `failed`

---

## D6. Assignment History

### D6.1 All Assignments
- **Route:** `/assignments`
- **Purpose:** View past delivery assignments (paginated, filterable by status)
- **Backend:** `GET /api/agents/assignments`
- **Query Params:** `status`, `page`, `limit`

### D6.2 Assignment Detail
- **Route:** `/assignments/:id`
- **Purpose:** View full details of a past assignment
- **Backend:** `GET /api/agents/assignments/:id`

---

## D7. Earnings

### D7.1 Earnings Summary
- **Route:** `/earnings`
- **Purpose:** View total earnings, delivery count, average per delivery, filterable by date range
- **Backend:** `GET /api/agents/earnings`
- **Query Params:** `startDate`, `endDate`

---

## D8. Notifications

### D8.1 Agent Notifications
- **Route:** `/notifications`
- **Purpose:** View assignment notifications, new delivery alerts
- **Backend:**
  - `GET /api/notifications`
  - `GET /api/notifications/unread-count`
  - `PATCH /api/notifications/read-all`
  - `PATCH /api/notifications/:id/read`
  - `DELETE /api/notifications/:id`
  - `DELETE /api/notifications/clear-all`

---

### Delivery Agent Panel Navigation Tree

```
DELIVERY AGENT PANEL
├── Register / Login
├── Dashboard (Current Delivery + Status Toggle + Today's Earnings)
├── Profile (View / Edit)
├── Current Assignment
│   ├── Order Details
│   ├── Customer Info + Map
│   └── Update Status (Picked Up → In Transit → Delivered / Failed)
├── Assignment History (View All / Filter / Detail)
├── Earnings (Summary / Date Filter)
└── Notifications (Inbox)
```

---

## Complete Endpoint Coverage Summary

| Panel | Pages | Backend Endpoints |
|-------|-------|-------------------|
| Admin | 40+ views | ~90 endpoints |
| Merchant | 25+ views | ~55 endpoints |
| User | 30+ views | ~76 endpoints |
| Delivery Agent | 10+ views | ~11 agent + ~6 notification endpoints |
| **Total** | **105+ views** | **232+ endpoints** |

---

**All backend endpoints are now fully mapped across all four panels.**

