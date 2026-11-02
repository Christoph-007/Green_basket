# 🛣️ GreenBasket API Route Map

## Base URL
```
Development: http://localhost:6000/api
Production: https://api.greenbasket.com/api
```

## Authentication
All protected routes require Bearer token in header:
```
Authorization: Bearer <token>
```

## Response Format
All APIs return standardized response:
```json
{
  "success": true|false,
  "message": "Description",
  "data": { ... },
  "count": 42,           // For list endpoints
  "total": 100,          // Total records for pagination
  "page": 1,
  "pages": 10
}
```

---

## 📱 AUTHENTICATION ROUTES

### Base: `/api/auth`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/login` | No | Unified login for all roles |
| POST | `/user/signup` | No | Customer registration |
| POST | `/user/login` | No | Customer login |
| POST | `/user/verify-email` | No | Verify email with OTP |
| POST | `/user/forgot-password` | No | Request password reset |
| POST | `/user/reset-password` | No | Reset password |
| POST | `/merchant/signup` | No | Merchant registration |
| POST | `/merchant/login` | No | Merchant login |
| POST | `/admin/login` | No | Admin login |
| POST | `/refresh-token` | No | Refresh JWT token |
| POST | `/logout` | Yes | Logout user |

---

## 👤 USER ROUTES

### Base: `/api/users`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/profile` | User | Get user profile |
| PUT | `/profile` | User | Update profile |
| GET | `/addresses` | User | Get all addresses |
| POST | `/addresses` | User | Add new address |
| PUT | `/addresses/:id` | User | Update address |
| DELETE | `/addresses/:id` | User | Delete address |
| GET | `/notification-preferences` | User | Get notification settings |
| PUT | `/notification-preferences` | User | Update notification settings |
| POST | `/fcm-token` | User | Register FCM token |
| DELETE | `/fcm-token` | User | Remove FCM token |

---

## 🛍️ PRODUCT ROUTES

### Base: `/api/products`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | Optional | Get all products (with filters) |
| GET | `/search` | Optional | Search products |
| GET | `/:id` | Optional | Get product by ID |
| GET | `/merchant/my-products` | Merchant | Get merchant's products |
| POST | `/` | Merchant | Create product |
| PUT | `/:id` | Merchant | Update product |
| DELETE | `/:id` | Merchant | Delete product |
| PATCH | `/:id/stock` | Merchant | Update stock |

### Query Parameters for GET `/`
| Param | Type | Description |
|-------|------|-------------|
| category | String | Filter by category ID |
| merchant | String | Filter by merchant ID |
| minPrice | Number | Minimum price |
| maxPrice | Number | Maximum price |
| sort | String | Sort: price_asc, price_desc, newest, popular |
| page | Number | Page number |
| limit | Number | Items per page |
| search | String | Text search |
| tags | String | Comma-separated tags |
| isOrganic | Boolean | Organic products only |
| inStock | Boolean | In stock only |

---

## 📂 CATEGORY ROUTES

### Base: `/api/categories`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | No | Get all categories |
| GET | `/:id` | No | Get category by ID |
| POST | `/` | Admin | Create category |
| PUT | `/:id` | Admin | Update category |
| DELETE | `/:id` | Admin | Delete category |

---

## 🛒 CART ROUTES

### Base: `/api/cart`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | User | Get cart |
| POST | `/add` | User | Add item to cart |
| PUT | `/update/:productId` | User | Update cart item |
| DELETE | `/remove/:productId` | User | Remove from cart |
| DELETE | `/clear` | User | Clear cart |
| POST | `/recipe-to-cart` | User | Add recipe ingredients |

### Request Body: POST `/add`
```json
{
  "productId": "string",
  "quantity": 1,
  "preparation": "whole|cut|chopped|diced|sliced"
}
```

---

## 📦 ORDER ROUTES

### Base: `/api/orders`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/` | User | Create order |
| GET | `/my-orders` | User | Get my orders |
| GET | `/:id` | User | Get order by ID |
| PATCH | `/:id/cancel` | User | Cancel order |
| GET | `/:id/track` | User | Track order (enhanced) |
| GET | `/:orderId/tracking` | User | Get tracking info |
| PATCH | `/:id/location` | User | Update delivery location |
| GET | `/merchant/orders` | Merchant | Get merchant orders |
| PATCH | `/merchant/:id/status` | Merchant | Update order status |

### Order Status Values
- `pending` → `confirmed` → `ready` → `out-for-delivery` → `delivered`
- `cancelled`
- `refunded`

---

## 💳 PAYMENT ROUTES

### Base: `/api/payment`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/create-order` | User | Create payment order |
| POST | `/verify` | User | Verify payment |
| POST | `/refund` | User | Process refund |
| GET | `/methods` | User | Get payment methods |
| GET | `/history` | User | Get payment history |
| GET | `/:orderId/status` | User | Get payment status |
| POST | `/:orderId/retry` | User | Retry payment |

### Webhook
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/payment/webhook` | No | Stripe webhook (raw body) |

---

## 🏪 MERCHANT ROUTES

### Base: `/api/merchants`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | No | Get all merchants |
| GET | `/:id` | No | Get merchant by ID |
| GET | `/profile` | Merchant | Get merchant profile |
| PUT | `/profile` | Merchant | Update profile |
| POST | `/upload-image` | Merchant | Upload profile image |
| PATCH | `/toggle-store` | Merchant | Toggle store open/close |
| GET | `/dashboard-stats` | Merchant | Get dashboard statistics |
| PATCH | `/update-password` | Merchant | Update password |
| PATCH | `/notification-settings` | Merchant | Update notification settings |

---

## 👨‍💼 ADMIN ROUTES

### Base: `/api/admin`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/merchants/pending` | Admin | Get pending merchants |
| PATCH | `/merchants/:id/verify` | Admin | Verify/reject merchant |
| GET | `/merchants/all` | Admin | Get all merchants |
| GET | `/users` | Admin | Get all users |
| PATCH | `/users/:id/block` | Admin | Block/unblock user |
| GET | `/stats` | Admin | Get platform statistics |
| GET | `/subscriptions/all` | Admin | Get all subscriptions |
| GET | `/agents` | Admin | Get all agents |
| GET | `/agents/analytics` | Admin | Get delivery analytics |
| GET | `/agents/:id` | Admin | Get agent by ID |
| GET | `/agents/:id/assignments` | Admin | Get agent assignments |
| PATCH | `/agents/:id/verify` | Admin | Verify agent |
| PATCH | `/agents/:id/toggle-active` | Admin | Toggle agent active |
| POST | `/orders/:orderId/assign/:agentId` | Admin | Manually assign order |
| GET | `/orders/unassigned` | Admin | Get unassigned orders |
| GET | `/assignments` | Admin | Get all assignments |

---

## 🔔 NOTIFICATION ROUTES

### Base: `/api/notifications`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | User | Get notifications |
| GET | `/unread-count` | User | Get unread count |
| PATCH | `/:id/read` | User | Mark as read |
| PATCH | `/read-all` | User | Mark all as read |
| DELETE | `/:id` | User | Delete notification |
| DELETE | `/clear-all` | User | Clear all notifications |
| POST | `/admin/test` | Admin | Send test notification |
| POST | `/admin/bulk-send` | Admin | Send bulk notifications |

---

## 💰 WALLET ROUTES

### Base: `/api/wallet`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | User | Get wallet |
| GET | `/transactions` | User | Get transaction history |
| POST | `/add-money` | User | Add money to wallet |
| POST | `/verify-topup` | User | Verify top-up |
| POST | `/use-for-payment` | User | Use wallet for payment |
| POST | `/admin/credit` | Admin | Credit wallet (admin) |
| PATCH | `/admin/:userId/lock` | Admin | Lock/unlock wallet |
| POST | `/credit-refund` | Admin | Credit refund to wallet |

---

## ❤️ WISHLIST ROUTES

### Base: `/api/wishlist`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | User | Get wishlist |
| POST | `/add` | User | Add to wishlist |
| DELETE | `/remove/:productId` | User | Remove from wishlist |
| POST | `/move-to-cart/:productId` | User | Move to cart |
| GET | `/check/:productId` | User | Check if wishlisted |

---

## ⭐ REVIEW ROUTES

### Base: `/api/reviews`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/product/:productId` | No | Get product reviews |
| GET | `/merchant/:merchantId` | No | Get merchant reviews |
| POST | `/` | User | Create review |
| GET | `/my-reviews` | User | Get my reviews |
| PUT | `/:id` | User | Update review |
| DELETE | `/:id` | User/Admin | Delete review |
| POST | `/:id/reply` | Merchant | Reply to a review |

---

## 🔄 SUBSCRIPTION ROUTES

### Base: `/api/subscriptions`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/` | User | Create subscription |
| GET | `/` | User | Get my subscriptions |
| GET | `/:id` | User | Get subscription by ID |
| PUT | `/:id` | User | Update subscription |
| DELETE | `/:id` | User | Delete subscription |
| PATCH | `/:id/status` | User | Update subscription status |
| GET | `/merchant/all` | Merchant | Get customer subscriptions |

---

## 🎁 OFFER/COUPON ROUTES

### Base: `/api/offers`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/flash-sales` | No | Get flash sales |
| GET | `/available` | User | Get available offers |
| POST | `/cart/apply-coupon` | User | Apply coupon |
| DELETE | `/cart/remove-coupon` | User | Remove coupon |
| GET | `/merchant` | Merchant | Get merchant offers |
| POST | `/` | Merchant/Admin | Create offer |
| PUT | `/:id` | Merchant/Admin | Update offer |
| DELETE | `/:id` | Merchant/Admin | Delete offer |
| GET | `/:id/analytics` | Merchant/Admin | Get offer analytics |
| GET | `/admin/all` | Admin | Get all offers |

---

## 🎬 RECIPE ROUTES

### Base: `/api/recipes`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | No | Get all recipes |
| GET | `/search` | No | Search recipes |
| GET | `/:id` | No | Get recipe by ID |
| POST | `/:id/calculate-ingredients` | No | Calculate for servings |
| POST | `/` | Admin | Create recipe |
| PUT | `/:id` | Admin | Update recipe |
| DELETE | `/:id` | Admin | Delete recipe |

---

## 📊 MERCHANT ANALYTICS ROUTES

### Base: `/api/merchants/analytics`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/sales` | Merchant | Sales analytics |
| GET | `/products` | Merchant | Product analytics |
| GET | `/customers` | Merchant | Customer analytics |
| GET | `/inventory` | Merchant | Inventory analytics |
| GET | `/forecast` | Merchant | Revenue forecast |
| GET | `/reviews` | Merchant | Review analytics |

---

## 🚚 DELIVERY ZONE ROUTES

### Base: `/api/merchants/zones`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| PUT | `/location` | Merchant | Set store location |
| GET | `/delivery-zones` | Merchant | Get delivery zones |
| POST | `/delivery-zones` | Merchant | Add delivery zone |
| PUT | `/delivery-zones/:zoneId` | Merchant | Update zone |
| DELETE | `/delivery-zones/:zoneId` | Merchant | Delete zone |
| POST | `/check-delivery` | No | Check if address deliverable |
| POST | `/nearby` | No | Get nearby merchants |

---

## 👑 MEMBERSHIP ROUTES

### Base: `/api/membership`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/plans` | No | Get membership plans |
| GET | `/` | User | Get my membership |
| POST | `/initiate` | User | Initiate membership subscription |
| POST | `/activate` | User | Activate membership after payment |
| POST | `/subscribe` | User | Alias for initiate |
| POST | `/cancel` | User | Cancel membership |
| GET | `/premium-products` | User | Get premium products |
| GET | `/check-benefit` | User | Check benefit eligibility |
| GET | `/history` | User | Get membership history |
| GET | `/admin/all` | Admin | Get all memberships |

---

## 📅 PRE-BOOKING ROUTES

### Base: `/api/prebooking`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/` | User | Create pre-booking |
| GET | `/my-prebookings` | User | Get my pre-bookings |
| DELETE | `/:id` | User | Cancel pre-booking |
| POST | `/:id/convert-to-order` | User | Convert to order |
| PATCH | `/products/:id/mark-available` | Merchant | Mark product available |
| PATCH | `/:id/update-status` | Merchant | Update pre-booking status |
| PATCH | `/merchant/products/:productId/prebooking` | Merchant | Update pre-booking settings |
| GET | `/merchant/all` | Merchant | Get merchant pre-bookings |
| GET | `/admin/all` | Admin | Get all pre-bookings |

---

## 📄 DOCUMENT VERIFICATION ROUTES

### Base: `/api/documents`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/upload` | Merchant | Upload document |
| GET | `/` | Merchant | Get my documents |
| GET | `/history` | Merchant | Get document history |
| DELETE | `/:documentId` | Merchant | Delete document |
| GET | `/admin/pending` | Admin | Get pending documents |
| PUT | `/admin/:merchantId/:documentId/verify` | Admin | Verify document |
| GET | `/admin/expiring-soon` | Admin | Get expiring documents |

---

## ⚠️ DISPUTE ROUTES

### Base: `/api/disputes`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/` | User | Raise dispute |
| GET | `/my-disputes` | User | Get my disputes |
| GET | `/:id` | User/Admin | Get dispute by ID |
| POST | `/:id/message` | User/Admin | Add message |
| PATCH | `/:id/escalate` | User | Escalate dispute |
| GET | `/admin/all` | Admin | Get all disputes |
| PUT | `/admin/:id/resolve` | Admin | Resolve dispute |
| PATCH | `/admin/:id/status` | Admin | Update dispute status |

---

## 💵 FINANCIAL ROUTES

### Base: `/api/financial`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/merchants/earnings` | Merchant | Get earnings |
| GET | `/merchants/payouts` | Merchant | Get payouts |
| POST | `/merchants/request-payout` | Merchant | Request payout |
| GET | `/payouts/:id` | Merchant/Admin | Get payout by ID |
| GET | `/admin/payouts` | Admin | Get all payouts |
| POST | `/admin/payouts/generate` | Admin | Generate payouts |
| POST | `/admin/payouts/:id/process` | Admin | Process payout |
| PATCH | `/admin/payouts/:id/hold` | Admin | Hold/release payout |
| GET | `/admin/reports/financial` | Admin | Financial reports |
| GET | `/admin/reports/gst` | Admin | GST reports |
| PUT | `/admin/settings/commission` | Admin | Update commission |

---

## 📦 BULK OPERATIONS ROUTES

### Base: `/api/bulk`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/products/bulk-upload` | Merchant | Bulk upload products (CSV) |
| PUT | `/products/bulk-update-price` | Merchant | Bulk update prices |
| PUT | `/products/bulk-update-stock` | Merchant | Bulk update stock |
| GET | `/products/export` | Merchant | Export products (CSV) |

---

## 🔍 SEARCH ROUTES

### Base: `/api/search`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/products` | No | Advanced product search |
| GET | `/suggestions` | No | Search suggestions |
| GET | `/trending` | No | Trending searches |

---

## ↩️ RETURN ROUTES

### Base: `/api/returns`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/` | User | Request return |
| GET | `/my-returns` | User | Get my returns |
| GET | `/:id` | User/Admin | Get return by ID |
| DELETE | `/:id` | User | Cancel return request |
| GET | `/admin/all` | Admin | Get all returns |
| PUT | `/admin/:id/process` | Admin | Process return |

---

## 🎁 GIFT CARD ROUTES

### Base: `/api/gift-cards`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/balance/:code` | No | Check gift card balance |
| POST | `/validate` | User | Validate gift card |
| POST | `/redeem` | User | Redeem gift card |
| GET | `/my-cards` | User | Get my gift cards |
| POST | `/purchase/initiate` | User | Initiate gift card purchase |
| POST | `/purchase/verify` | User | Verify gift card purchase |
| POST | `/admin/generate` | Admin | Generate gift card |
| GET | `/admin/all` | Admin | Get all gift cards |
| PATCH | `/admin/:id/cancel` | Admin | Cancel gift card |

---

## 🚴 DELIVERY AGENT ROUTES

### Base: `/api/agents`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/register` | No | Register agent |
| POST | `/login` | No | Agent login |
| GET | `/me` | Agent | Get profile |
| PUT | `/me` | Agent | Update profile |
| PUT | `/me/status` | Agent | Update status (available/offline) |
| POST | `/me/location` | Agent | Update location |
| GET | `/assignments/current` | Agent | Get current assignment |
| GET | `/assignments` | Agent | Get all assignments |
| GET | `/assignments/:id` | Agent | Get assignment by ID |
| PUT | `/assignments/:id/status` | Agent | Update assignment status |
| GET | `/earnings` | Agent | Get earnings |

### Admin Agent Routes: `/api/admin`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/agents` | Admin | Get all agents |
| GET | `/agents/:id` | Admin | Get agent by ID |
| GET | `/agents/:id/assignments` | Admin | Get agent assignments |
| PATCH | `/agents/:id/verify` | Admin | Verify agent |
| PATCH | `/agents/:id/toggle-active` | Admin | Toggle agent active status |
| POST | `/orders/:orderId/assign/:agentId` | Admin | Manually assign order |
| GET | `/orders/unassigned` | Admin | Get unassigned orders |

---

## 📤 UPLOAD ROUTES

### Base: `/api/upload`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/image` | Yes | Upload single image |
| POST | `/images` | Yes | Upload multiple images |
| POST | `/document` | Yes | Upload document |
| GET | `/my-uploads` | Yes | Get my uploads |
| GET | `/:uploadId` | Yes | Get upload by ID |
| DELETE | `/:uploadId` | Yes | Delete upload |
| POST | `/bulk-delete` | Yes | Bulk delete uploads |
| PUT | `/products/:productId/images` | Merchant | Update product images |

---

## Route Summary by Role

### Customer APIs (User)
- Auth: `/api/auth/*`
- User: `/api/users/*`
- Products: `/api/products/*` (GET only)
- Categories: `/api/categories/*` (GET only)
- Cart: `/api/cart/*`
- Orders: `/api/orders/*`
- Payment: `/api/payment/*`
- Wishlist: `/api/wishlist/*`
- Reviews: `/api/reviews/*` (POST, PUT, DELETE)
- Wallet: `/api/wallet/*` (User routes)
- Notifications: `/api/notifications/*` (User routes)
- Subscriptions: `/api/subscriptions/*`
- Offers: `/api/offers/available`, `/api/offers/cart/*`
- Recipes: `/api/recipes/*` (GET only)
- Membership: `/api/membership/*`
- PreBooking: `/api/prebooking/*` (User routes)
- Disputes: `/api/disputes/*` (User routes)
- Returns: `/api/returns/*` (User routes)
- GiftCards: `/api/gift-cards/*` (User routes)
- Upload: `/api/upload/*`

### Merchant APIs
- Auth: `/api/auth/merchant/*`
- Merchant: `/api/merchants/*`
- Products: `/api/products/*` (Merchant routes)
- Orders: `/api/orders/merchant/*`
- Analytics: `/api/merchants/analytics/*`
- DeliveryZones: `/api/merchants/zones/*`
- Offers: `/api/offers/*` (Merchant routes)
- Documents: `/api/documents/*` (Merchant routes)
- Financial: `/api/financial/merchants/*`
- Bulk: `/api/bulk/*`

### Admin APIs
- Auth: `/api/auth/admin/*`
- Admin: `/api/admin/*`
- All resources have admin routes
- Financial: `/api/financial/admin/*`
- GiftCards: `/api/gift-cards/admin/*`
- PreBooking: `/api/prebooking/admin/*`
- Disputes: `/api/disputes/admin/*`
- Returns: `/api/returns/admin/*`
- Wallet: `/api/wallet/admin/*`
- Notifications: `/api/notifications/admin/*`

### Delivery Agent APIs
- Auth: `/api/agents/register`, `/api/agents/login`
- Agent: `/api/agents/*` (Protected)

---

## Total API Count: 221 Endpoints
