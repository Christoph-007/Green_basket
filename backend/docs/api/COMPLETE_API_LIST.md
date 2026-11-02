# Complete API List - GreenBasket Backend

**Total APIs: 221**  
**Total Features: 31**

---

## 1. Authentication (10 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/auth/user/signup` | User registration | Public |
| POST | `/api/auth/user/login` | User login | Public |
| POST | `/api/auth/user/verify-email` | Verify email with OTP | Public |
| POST | `/api/auth/user/forgot-password` | Request password reset | Public |
| POST | `/api/auth/user/reset-password` | Reset password with token | Public |
| POST | `/api/auth/merchant/signup` | Merchant registration | Public |
| POST | `/api/auth/merchant/login` | Merchant login | Public |
| POST | `/api/auth/admin/login` | Admin login | Public |
| POST | `/api/auth/refresh-token` | Refresh access token | Public |
| POST | `/api/auth/logout` | Logout user | Auth |

---

## 2. Products (8 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/products` | Get all products | Public |
| GET | `/api/products/search` | Search products | Public |
| GET | `/api/products/:id` | Get product by ID | Public |
| POST | `/api/products` | Create product | Merchant |
| PUT | `/api/products/:id` | Update product | Merchant |
| DELETE | `/api/products/:id` | Delete product | Merchant |
| PATCH | `/api/products/:id/stock` | Update stock | Merchant |
| GET | `/api/products/merchant/my-products` | Get merchant products | Merchant |

---

## 3. Categories (5 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/categories` | Get all categories | Public |
| GET | `/api/categories/:id` | Get category by ID | Public |
| POST | `/api/categories` | Create category | Admin |
| PUT | `/api/categories/:id` | Update category | Admin |
| DELETE | `/api/categories/:id` | Delete category | Admin |

---

## 4. Cart (6 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/cart` | Get user cart | User |
| POST | `/api/cart/add` | Add item to cart | User |
| PUT | `/api/cart/update/:productId` | Update cart item | User |
| DELETE | `/api/cart/remove/:productId` | Remove from cart | User |
| DELETE | `/api/cart/clear` | Clear cart | User |
| POST | `/api/cart/recipe-to-cart` | Add recipe to cart | User |

---

## 5. Orders (7 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/orders` | Create order | User |
| GET | `/api/orders/my-orders` | Get user orders | User |
| GET | `/api/orders/:id` | Get order details | User |
| PATCH | `/api/orders/:id/cancel` | Cancel order | User |
| PATCH | `/api/orders/:id/location` | Update order location | User/Merchant |
| GET | `/api/orders/merchant/orders` | Get merchant orders | Merchant |
| PATCH | `/api/orders/merchant/:id/status` | Update order status | Merchant |

---

## 6. Recipes (7 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/recipes` | Get all recipes | Public |
| GET | `/api/recipes/search` | Search recipes | Public |
| GET | `/api/recipes/:id` | Get recipe by ID | Public |
| POST | `/api/recipes/:id/calculate-ingredients` | Calculate ingredients | Public |
| POST | `/api/recipes` | Create recipe | Admin |
| PUT | `/api/recipes/:id` | Update recipe | Admin |
| DELETE | `/api/recipes/:id` | Delete recipe | Admin |

---

## 7. Reviews (3 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/reviews/product/:productId` | Get product reviews | Public |
| GET | `/api/reviews/merchant/:merchantId` | Get merchant reviews | Public |
| DELETE | `/api/reviews/:id` | Delete review | User/Admin |

---

## 8. Subscriptions (3 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/subscriptions` | Create subscription | User |
| GET | `/api/subscriptions` | Get user subscriptions | User |
| PATCH | `/api/subscriptions/:id/status` | Update subscription | User |

---

## 9. Users (10 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/users/profile` | Get user profile | User |
| PUT | `/api/users/profile` | Update profile | User |
| GET | `/api/users/addresses` | Get addresses | User |
| POST | `/api/users/addresses` | Add address | User |
| PUT | `/api/users/addresses/:id` | Update address | User |
| DELETE | `/api/users/addresses/:id` | Delete address | User |
| GET | `/api/users/notification-preferences` | Get notification prefs | User |
| PUT | `/api/users/notification-preferences` | Update notification prefs | User |
| POST | `/api/users/fcm-token` | Register FCM token | User |
| DELETE | `/api/users/fcm-token` | Remove FCM token | User |

---

## 10. Merchants (4 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/merchants/profile` | Get merchant profile | Merchant |
| PUT | `/api/merchants/profile` | Update profile | Merchant |
| PATCH | `/api/merchants/toggle-store` | Toggle store status | Merchant |
| GET | `/api/merchants/dashboard-stats` | Get dashboard stats | Merchant |

---

## 11. Admin (5 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/admin/merchants/pending` | Get pending merchants | Admin |
| PATCH | `/api/admin/merchants/:id/verify` | Verify merchant | Admin |
| GET | `/api/admin/users` | Get all users | Admin |
| PATCH | `/api/admin/users/:id/block` | Block/unblock user | Admin |
| GET | `/api/admin/stats` | Get platform stats | Admin |

---

## 12. Upload (8 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/upload/image` | Upload single image | Auth |
| POST | `/api/upload/images` | Upload multiple images | Auth |
| POST | `/api/upload/document` | Upload document | Auth |
| GET | `/api/upload/my-uploads` | Get user uploads | Auth |
| GET | `/api/upload/:uploadId` | Get upload by ID | Auth |
| DELETE | `/api/upload/:uploadId` | Delete upload | Auth |
| POST | `/api/upload/bulk-delete` | Bulk delete uploads | Auth |
| PUT | `/api/upload/products/:productId/images` | Update product images | Merchant |

---

## 13. Payment (3 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/payment/create-order` | Create Razorpay order | User |
| POST | `/api/payment/verify` | Verify payment | User |
| POST | `/api/payment/refund` | Process refund | Admin |

---

## 14. Notifications (8 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/notifications` | Get notifications | Auth |
| GET | `/api/notifications/unread-count` | Get unread count | Auth |
| PATCH | `/api/notifications/:id/read` | Mark as read | Auth |
| PATCH | `/api/notifications/read-all` | Mark all as read | Auth |
| DELETE | `/api/notifications/:id` | Delete notification | Auth |
| DELETE | `/api/notifications/clear-all` | Clear all | Auth |
| POST | `/api/notifications/admin/test` | Send test notification | Admin |
| POST | `/api/notifications/admin/bulk-send` | Bulk send | Admin |

---

## 15. Wishlist (5 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/wishlist` | Get wishlist | User |
| POST | `/api/wishlist/add` | Add to wishlist | User |
| DELETE | `/api/wishlist/remove/:productId` | Remove from wishlist | User |
| POST | `/api/wishlist/move-to-cart/:productId` | Move to cart | User |
| GET | `/api/wishlist/check/:productId` | Check if wishlisted | User |

---

## 16. Wallet (8 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/wallet` | Get wallet balance | User |
| GET | `/api/wallet/transactions` | Get transactions | User |
| POST | `/api/wallet/add-money` | Add money to wallet | User |
| POST | `/api/wallet/verify-topup` | Verify topup payment | User |
| POST | `/api/wallet/use-for-payment` | Use wallet for payment | User |
| POST | `/api/wallet/admin/credit` | Admin credit wallet | Admin |
| PATCH | `/api/wallet/admin/:userId/lock` | Lock/unlock wallet | Admin |
| POST | `/api/wallet/credit-refund` | Credit refund | Admin |

---

## 17. Loyalty (4 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/loyalty/redeem` | Redeem loyalty points | User |
| GET | `/api/loyalty/history` | Get points history | User |
| GET | `/api/loyalty/benefits` | Get tier benefits | User |
| POST | `/api/loyalty/award` | Award points | Admin |

---

## 18. Referral System (5 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/referral/generate` | Generate referral code | User |
| GET | `/api/referral/stats` | Get referral stats | User |
| POST | `/api/referral/apply` | Apply referral code | User |
| GET | `/api/referral/validate/:code` | Validate code | Public |
| POST | `/api/referral/process-reward` | Process reward | Admin |

---

## 19. Offers & Promotions (10 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/offers` | Create offer | Merchant/Admin |
| GET | `/api/offers/merchant` | Get merchant offers | Merchant |
| GET | `/api/offers/available` | Get available offers | User |
| POST | `/api/offers/cart/apply-coupon` | Apply coupon | User |
| DELETE | `/api/offers/cart/remove-coupon` | Remove coupon | User |
| PUT | `/api/offers/:id` | Update offer | Merchant/Admin |
| DELETE | `/api/offers/:id` | Delete offer | Merchant/Admin |
| GET | `/api/offers/:id/analytics` | Get offer analytics | Merchant/Admin |
| GET | `/api/offers/flash-sales` | Get flash sales | Public |
| GET | `/api/offers/admin/all` | Get all offers | Admin |

---

## 20. Merchant Analytics (6 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/merchants/analytics/sales` | Sales analytics | Merchant |
| GET | `/api/merchants/analytics/products` | Product performance | Merchant |
| GET | `/api/merchants/analytics/customers` | Customer insights | Merchant |
| GET | `/api/merchants/analytics/inventory` | Inventory analysis | Merchant |
| GET | `/api/merchants/analytics/forecast` | Revenue forecast | Merchant |
| GET | `/api/merchants/analytics/reviews` | Review analytics | Merchant |

---

## 21. Delivery Zone Management (7 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| PUT | `/api/merchants/zones/location` | Set merchant location | Merchant |
| GET | `/api/merchants/zones/delivery-zones` | Get all zones | Merchant |
| POST | `/api/merchants/zones/delivery-zones` | Add delivery zone | Merchant |
| PUT | `/api/merchants/zones/delivery-zones/:zoneId` | Update zone | Merchant |
| DELETE | `/api/merchants/zones/delivery-zones/:zoneId` | Delete zone | Merchant |
| POST | `/api/merchants/zones/check-delivery` | Check delivery | Public |
| POST | `/api/merchants/zones/nearby` | Get nearby merchants | Public |

---

## 22. Membership (6 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/membership/plans` | Get membership plans | Public |
| GET | `/api/membership` | Get my membership | User |
| POST | `/api/membership/subscribe` | Subscribe to membership | User |
| POST | `/api/membership/cancel` | Cancel membership | User |
| GET | `/api/membership/premium-products` | Get premium products | User |
| GET | `/api/membership/check-benefit` | Check benefit eligibility | User |

---

## 23. Pre-Booking (6 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/prebooking` | Create pre-booking | User |
| GET | `/api/prebooking/my-prebookings` | Get user pre-bookings | User |
| DELETE | `/api/prebooking/:id` | Cancel pre-booking | User |
| POST | `/api/prebooking/:id/convert-to-order` | Convert to order | User |
| PATCH | `/api/prebooking/products/:id/mark-available` | Mark product available | Merchant |
| GET | `/api/prebooking/admin/all` | Get all pre-bookings | Admin |

---

## 24. Document Verification (6 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/documents/upload` | Upload document | Merchant |
| GET | `/api/documents` | Get merchant documents | Merchant |
| DELETE | `/api/documents/:documentId` | Delete document | Merchant |
| GET | `/api/documents/admin/pending` | Get pending documents | Admin |
| PUT | `/api/documents/admin/:merchantId/:documentId/verify` | Verify document | Admin |
| GET | `/api/documents/admin/expiring-soon` | Get expiring documents | Admin |

---

## 25. Disputes (8 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/disputes` | Raise dispute | User |
| GET | `/api/disputes/my-disputes` | Get my disputes | User |
| GET | `/api/disputes/:id` | Get dispute by ID | User/Admin |
| POST | `/api/disputes/:id/message` | Add message to dispute | User/Admin |
| PATCH | `/api/disputes/:id/escalate` | Escalate dispute | User |
| GET | `/api/disputes/admin/all` | Get all disputes | Admin |
| PUT | `/api/disputes/admin/:id/resolve` | Resolve dispute | Admin |
| PATCH | `/api/disputes/admin/:id/status` | Update dispute status | Admin |

---

## 26. Financial Management (10 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/financial/merchants/earnings` | Get merchant earnings | Merchant |
| GET | `/api/financial/merchants/payouts` | Get merchant payouts | Merchant |
| GET | `/api/financial/payouts/:id` | Get payout by ID | Merchant/Admin |
| GET | `/api/financial/admin/payouts` | Get all payouts | Admin |
| POST | `/api/financial/admin/payouts/generate` | Generate payouts | Admin |
| POST | `/api/financial/admin/payouts/:id/process` | Process payout | Admin |
| PATCH | `/api/financial/admin/payouts/:id/hold` | Hold/Release payout | Admin |
| GET | `/api/financial/admin/reports/financial` | Get financial reports | Admin |
| GET | `/api/financial/admin/reports/gst` | Get GST report | Admin |
| PUT | `/api/financial/admin/settings/commission` | Update commission settings | Admin |

---

## 27. Bulk Operations (4 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/bulk/products/bulk-upload` | Bulk upload products | Merchant |
| PUT | `/api/bulk/products/bulk-update-price` | Bulk update prices | Merchant |
| PUT | `/api/bulk/products/bulk-update-stock` | Bulk update stock | Merchant |
| GET | `/api/bulk/products/export` | Export products | Merchant |

---

## 28. Advanced Search (3 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/search/products` | Advanced product search | Public |
| GET | `/api/search/suggestions` | Search suggestions | Public |
| GET | `/api/search/trending` | Trending products | Public |

---

## 29. Returns & Exchanges (6 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/returns` | Request return | User |
| GET | `/api/returns/my-returns` | Get my returns | User |
| GET | `/api/returns/:id` | Get return by ID | User/Admin |
| DELETE | `/api/returns/:id` | Cancel return request | User |
| GET | `/api/returns/admin/all` | Get all returns | Admin |
| PUT | `/api/returns/admin/:id/process` | Process return | Admin |

---

## 30. Gift Cards (7 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/gift-cards/balance/:code` | Check balance | Public |
| POST | `/api/gift-cards/validate` | Validate gift card | User |
| POST | `/api/gift-cards/redeem` | Redeem gift card | User |
| GET | `/api/gift-cards/my-cards` | Get my gift cards | User |
| POST | `/api/gift-cards/admin/generate` | Generate gift card | Admin |
| GET | `/api/gift-cards/admin/all` | Get all gift cards | Admin |
| PATCH | `/api/gift-cards/admin/:id/cancel` | Cancel gift card | Admin |

---

## Summary by Feature

| # | Feature | APIs | Status |
|---|---------|------|--------|
| 1 | Authentication | 10 | ✅ |
| 2 | Products | 8 | ✅ |
| 3 | Categories | 5 | ✅ |
| 4 | Cart | 6 | ✅ |
| 5 | Orders | 7 | ✅ |
| 6 | Recipes | 7 | ✅ |
| 7 | Reviews | 3 | ✅ |
| 8 | Subscriptions | 3 | ✅ |
| 9 | Users | 10 | ✅ |
| 10 | Merchants | 4 | ✅ |
| 11 | Admin | 5 | ✅ |
| 12 | Upload | 8 | ✅ |
| 13 | Payment | 3 | ✅ |
| 14 | Notifications | 8 | ✅ |
| 15 | Wishlist | 5 | ✅ |
| 16 | Wallet | 8 | ✅ |
| 17 | Loyalty | 4 | ✅ |
| 18 | Referral | 5 | ✅ |
| 19 | Offers | 10 | ✅ |
| 20 | Merchant Analytics | 6 | ✅ |
| 21 | Delivery Zones | 7 | ✅ |
| 22 | **Membership** | **6** | **✅ NEW** |
| 23 | **Pre-Booking** | **6** | **✅ NEW** |
| 24 | **Document Verification** | **6** | **✅ NEW** |
| 25 | **Disputes** | **8** | **✅ NEW** |
| 26 | **Financial** | **10** | **✅ NEW** |
| 27 | **Bulk Operations** | **4** | **✅ NEW** |
| 28 | **Advanced Search** | **3** | **✅ NEW** |
| 29 | **Returns** | **6** | **✅ NEW** |
| 30 | **Gift Cards** | **7** | **✅ NEW** |
| 31 | **Delivery Agent System** | **17** | **✅ NEW** |
| **TOTAL** | **31 Features** | **221 APIs** | **✅** |

---

## 31. Delivery Agent System (17 APIs)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/agents/register` | Register new delivery agent | Public |
| POST | `/api/agents/login` | Agent login | Public |
| GET | `/api/agents/me` | Get agent profile | Agent |
| PUT | `/api/agents/me` | Update agent profile | Agent |
| PUT | `/api/agents/me/status` | Update status (available/offline) | Agent |
| POST | `/api/agents/me/location` | Update GPS location | Agent |
| GET | `/api/agents/assignments/current` | Get current active assignment | Agent |
| GET | `/api/agents/assignments` | Get assignment history | Agent |
| GET | `/api/agents/assignments/:id` | Get assignment details | Agent |
| PUT | `/api/agents/assignments/:id/status` | Update delivery status | Agent |
| GET | `/api/agents/earnings` | Get earnings summary | Agent |
| GET | `/api/admin/agents` | List all delivery agents | Admin |
| GET | `/api/admin/agents/analytics` | Get delivery analytics | Admin |
| GET | `/api/admin/agents/:id` | Get agent details | Admin |
| GET | `/api/admin/agents/:id/assignments` | Get agent assignment history | Admin |
| PATCH | `/api/admin/agents/:id/verify` | Verify/approve agent | Admin |
| PATCH | `/api/admin/agents/:id/toggle-active` | Activate/deactivate agent | Admin |
| POST | `/api/admin/orders/:orderId/assign/:agentId` | Manually assign order to agent | Admin |
| GET | `/api/admin/orders/unassigned` | Get unassigned orders | Admin |
| GET | `/api/admin/assignments` | Get all delivery assignments | Admin |

**Features:**
- Separate agent authentication (role: 'agent')
- Auto-assignment based on proximity (Haversine formula)
- Real-time status tracking
- Earnings calculation
- Admin oversight and manual assignment
- Graceful fallback for failed auto-assignments

---

## Quick Start

```bash
# Start server
npm run dev

# Test all endpoints
npm test

# View API documentation
curl http://localhost:6000/api
```

---

## Documentation

- **Comprehensive Guide:** `FEATURES_7_10_GUIDE.md`
- **Implementation Summary:** `IMPLEMENTATION_SUMMARY.md`
- **API Docs:** `/backend/docs/`

---

**Last Updated:** February 17, 2026  
**Version:** 1.2.0  
**Status:** Production Ready ✅
