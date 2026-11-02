# 🎉 Green Basket Backend - ALL 103 APIs Listed!

## ✅ Complete API Breakdown

Now when you visit **http://localhost:5001/api**, you'll see **ALL 103 APIs** explicitly listed!

---

## 📊 API Count by Category

| # | Category | APIs | Description |
|---|----------|------|-------------|
| 1 | **Authentication** | 10 | User/Merchant/Admin auth, email verification, password reset |
| 2 | **Products** | 8 | CRUD, search, stock management |
| 3 | **Categories** | 5 | CRUD operations |
| 4 | **Cart** | 6 | Add, update, remove, clear, recipe-to-cart |
| 5 | **Orders** | 6 | Create, view, cancel, merchant management |
| 6 | **Recipes** | 7 | CRUD, search, ingredient calculation |
| 7 | **Reviews** | 3 | Product/merchant reviews, delete |
| 8 | **Subscriptions** | 3 | Create, view, update status |
| 9 | **Users** | 10 | Profile, addresses (CRUD), notification preferences, FCM tokens |
| 10 | **Merchants** | 4 | Profile, store toggle, dashboard |
| 11 | **Admin** | 5 | Merchant verification, user management, stats |
| 12 | **Upload** ✨ | 8 | Image/document upload, bulk operations |
| 13 | **Payment** ✨ | 3 | Razorpay integration |
| 14 | **Notifications** ✨ | 8 | Multi-channel notifications |
| 15 | **Wishlist** ✨ | 5 | Wishlist management |
| 16 | **Wallet** ✨ | 8 | Wallet topup, transactions |
| 17 | **Loyalty** ✨ | 4 | Points redemption, tiers |
| **TOTAL** | | **103** | **All APIs Active** |

---

## 📋 Complete API List

### 1. AUTHENTICATION (10 APIs)
1. `POST /api/auth/user/signup` - User signup
2. `POST /api/auth/user/login` - User login
3. `POST /api/auth/user/verify-email` - Verify email ✨
4. `POST /api/auth/user/forgot-password` - Forgot password ✨
5. `POST /api/auth/user/reset-password` - Reset password ✨
6. `POST /api/auth/merchant/signup` - Merchant signup
7. `POST /api/auth/merchant/login` - Merchant login
8. `POST /api/auth/admin/login` - Admin login
9. `POST /api/auth/refresh-token` - Refresh JWT token ✨
10. `POST /api/auth/logout` - Logout ✨

### 2. PRODUCTS (8 APIs)
11. `GET /api/products` - Get all products
12. `GET /api/products/search` - Search products ✨
13. `GET /api/products/:id` - Get product by ID
14. `POST /api/products` - Create product (Merchant)
15. `PUT /api/products/:id` - Update product (Merchant)
16. `DELETE /api/products/:id` - Delete product (Merchant)
17. `PATCH /api/products/:id/stock` - Update stock (Merchant) ✨
18. `GET /api/products/merchant/my-products` - Get my products (Merchant) ✨

### 3. CATEGORIES (5 APIs)
19. `GET /api/categories` - Get all categories
20. `GET /api/categories/:id` - Get category by ID
21. `POST /api/categories` - Create category (Admin)
22. `PUT /api/categories/:id` - Update category (Admin)
23. `DELETE /api/categories/:id` - Delete category (Admin)

### 4. CART (6 APIs)
24. `GET /api/cart` - Get cart
25. `POST /api/cart/add` - Add to cart
26. `PUT /api/cart/update/:productId` - Update cart item
27. `DELETE /api/cart/remove/:productId` - Remove from cart
28. `DELETE /api/cart/clear` - Clear cart
29. `POST /api/cart/recipe-to-cart` - Add recipe to cart

### 5. ORDERS (6 APIs)
30. `POST /api/orders` - Create order
31. `GET /api/orders/my-orders` - Get my orders
32. `GET /api/orders/:id` - Get order by ID
33. `PATCH /api/orders/:id/cancel` - Cancel order
34. `GET /api/orders/merchant/orders` - Get merchant orders (Merchant) ✨
35. `PATCH /api/orders/merchant/:id/status` - Update order status (Merchant) ✨

### 6. RECIPES (7 APIs)
36. `GET /api/recipes` - Get all recipes
37. `GET /api/recipes/search` - Search recipes ✨
38. `GET /api/recipes/:id` - Get recipe by ID
39. `POST /api/recipes/:id/calculate-ingredients` - Calculate ingredients
40. `POST /api/recipes` - Create recipe (Admin) ✨
41. `PUT /api/recipes/:id` - Update recipe (Admin) ✨
42. `DELETE /api/recipes/:id` - Delete recipe (Admin) ✨

### 7. REVIEWS (3 APIs)
43. `GET /api/reviews/product/:productId` - Get product reviews
44. `GET /api/reviews/merchant/:merchantId` - Get merchant reviews
45. `DELETE /api/reviews/:id` - Delete review

### 8. SUBSCRIPTIONS (3 APIs)
46. `POST /api/subscriptions` - Create subscription
47. `GET /api/subscriptions` - Get my subscriptions
48. `PATCH /api/subscriptions/:id/status` - Update subscription status

### 9. USERS (10 APIs)
49. `GET /api/users/profile` - Get profile
50. `PUT /api/users/profile` - Update profile
51. `GET /api/users/addresses` - Get addresses
52. `POST /api/users/addresses` - Add address
53. `PUT /api/users/addresses/:id` - Update address ✨
54. `DELETE /api/users/addresses/:id` - Delete address ✨
55. `GET /api/users/notification-preferences` - Get notification preferences ✨
56. `PUT /api/users/notification-preferences` - Update notification preferences ✨
57. `POST /api/users/fcm-token` - Register FCM token ✨
58. `DELETE /api/users/fcm-token` - Remove FCM token ✨

### 10. MERCHANTS (4 APIs)
59. `GET /api/merchants/profile` - Get profile
60. `PUT /api/merchants/profile` - Update profile
61. `PATCH /api/merchants/toggle-store` - Toggle store status
62. `GET /api/merchants/dashboard-stats` - Get dashboard stats

### 11. ADMIN (5 APIs)
63. `GET /api/admin/merchants/pending` - Get pending merchants
64. `PATCH /api/admin/merchants/:id/verify` - Verify merchant
65. `GET /api/admin/users` - Get all users
66. `PATCH /api/admin/users/:id/block` - Toggle user block ✨
67. `GET /api/admin/stats` - Get platform stats

### 12. FILE UPLOAD (8 APIs) ✨ Feature 1
68. `POST /api/upload/image` - Upload single image
69. `POST /api/upload/images` - Upload multiple images
70. `POST /api/upload/document` - Upload document
71. `GET /api/upload/my-uploads` - Get my uploads
72. `GET /api/upload/:uploadId` - Get upload by ID
73. `DELETE /api/upload/:uploadId` - Delete upload
74. `POST /api/upload/bulk-delete` - Bulk delete uploads
75. `PUT /api/upload/products/:productId/images` - Update product images

### 13. PAYMENT GATEWAY (3 APIs) ✨ Feature 2
76. `POST /api/payment/create-order` - Create Razorpay order
77. `POST /api/payment/verify` - Verify payment
78. `POST /api/payment/refund` - Process refund

### 14. NOTIFICATIONS (8 APIs) ✨ Feature 3
79. `GET /api/notifications` - Get notifications
80. `GET /api/notifications/unread-count` - Get unread count
81. `PATCH /api/notifications/:id/read` - Mark as read
82. `PATCH /api/notifications/read-all` - Mark all as read
83. `DELETE /api/notifications/:id` - Delete notification
84. `DELETE /api/notifications/clear-all` - Clear all notifications
85. `POST /api/notifications/admin/test` - Send test notification (Admin)
86. `POST /api/notifications/admin/bulk-send` - Bulk send notifications (Admin)

### 15. WISHLIST (5 APIs) ✨ Feature 4
87. `GET /api/wishlist` - Get wishlist
88. `POST /api/wishlist/add` - Add to wishlist
89. `DELETE /api/wishlist/remove/:productId` - Remove from wishlist
90. `POST /api/wishlist/move-to-cart/:productId` - Move to cart
91. `GET /api/wishlist/check/:productId` - Check if wishlisted

### 16. WALLET & CREDITS (8 APIs) ✨ Feature 5
92. `GET /api/wallet` - Get wallet balance
93. `GET /api/wallet/transactions` - Get transaction history
94. `POST /api/wallet/add-money` - Initiate wallet topup
95. `POST /api/wallet/verify-topup` - Verify topup payment
96. `POST /api/wallet/use-for-payment` - Pay with wallet
97. `POST /api/wallet/admin/credit` - Admin credit to wallet (Admin)
98. `PATCH /api/wallet/admin/:userId/lock` - Lock/unlock wallet (Admin)
99. `POST /api/wallet/credit-refund` - Credit refund (Admin)

### 17. LOYALTY POINTS (4 APIs) ✨ Feature 6
100. `POST /api/loyalty/redeem` - Redeem points
101. `GET /api/loyalty/history` - Get points history
102. `GET /api/loyalty/benefits` - Get tier benefits
103. `POST /api/loyalty/award` - Award points (Admin)

---

## 🎯 Summary

**Total APIs:** 103
**New Features:** 6 (Features 1-6)
**New APIs Added:** 40
**Server:** ✅ Running on http://localhost:5001
**Status:** ✅ ALL 103 APIs ACTIVE

---

**Visit http://localhost:5001/api to see the complete API documentation!**

**Last Updated:** February 9, 2026, 10:45 PM IST
