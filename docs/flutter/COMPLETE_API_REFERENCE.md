# 📚 GreenBasket Complete API Reference

Comprehensive API documentation based on full backend analysis.

## 🎯 Authentication & Authorization

### Token Format
```
Authorization: Bearer <JWT_TOKEN>
```

### User Roles
- `user` - Customer
- `merchant` - Seller/Merchant
- `admin` - Platform Administrator  
- `delivery_agent` - Delivery Driver

---

## 📱 AUTHENTICATION APIs

### Base: `/api/auth`

#### 1. Unified Login (All Roles)
```http
POST /api/auth/login
Content-Type: application/json
```

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "role": "customer|merchant|admin|delivery_agent",
  "user": {
    "id": "65a1b2c3...",
    "name": "John Doe",
    "email": "user@example.com",
    "phone": "9876543210",
    "profileImage": "https://...",
    "isPremium": false,
    "loyaltyPoints": 150
  }
}
```

#### 2. User Signup
```http
POST /api/auth/user/signup
Content-Type: application/json
```

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "9876543210",
  "password": "password123",
  "dietaryPreferences": ["vegetarian", "organic-only"],
  "allergies": ["peanuts", "gluten"]
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully. Please verify your email.",
  "data": {
    "user": {
      "id": "65a1b2c3...",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "9876543210"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### 3. User Login (Legacy)
```http
POST /api/auth/user/login
Content-Type: application/json
```

#### 4. Merchant Signup
```http
POST /api/auth/merchant/signup
Content-Type: application/json
```

**Request:**
```json
{
  "name": "John Smith",
  "email": "merchant@example.com",
  "phone": "9876543210",
  "password": "password123",
  "businessName": "Green Farms",
  "merchantType": "organic-farmer"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Merchant registered. Waiting for admin approval.",
  "data": {
    "merchant": {
      "id": "65a1b2c3...",
      "name": "John Smith",
      "businessName": "Green Farms",
      "verificationStatus": "pending"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### 5. Merchant Login (Legacy)
```http
POST /api/auth/merchant/login
Content-Type: application/json
```

#### 6. Admin Login
```http
POST /api/auth/admin/login
Content-Type: application/json
```

#### 7. Verify Email
```http
POST /api/auth/user/verify-email
Content-Type: application/json
```

**Request:**
```json
{
  "token": "verification_token_from_email"
}
```

#### 8. Forgot Password
```http
POST /api/auth/user/forgot-password
Content-Type: application/json
```

**Request:**
```json
{
  "email": "user@example.com"
}
```

#### 9. Reset Password
```http
POST /api/auth/user/reset-password
Content-Type: application/json
```

**Request:**
```json
{
  "token": "reset_token_from_email",
  "newPassword": "newpassword123"
}
```

#### 10. Refresh Token
```http
POST /api/auth/refresh-token
Content-Type: application/json
```

**Request:**
```json
{
  "token": "current_jwt_token"
}
```

#### 11. Logout
```http
POST /api/auth/logout
Authorization: Bearer <token>
```

---

## 👤 USER APIs

### Base: `/api/users`

All routes require authentication.

#### 1. Get Profile
```http
GET /api/users/profile
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "65a1b2c3...",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210",
    "profileImage": "https://...",
    "dietaryPreferences": ["vegetarian"],
    "allergies": ["peanuts"],
    "isPremium": false,
    "premiumExpiresAt": null,
    "loyaltyPoints": 250,
    "loyaltyTier": "gold",
    "walletBalance": 1250.50,
    "referral": {
      "code": "JOHN2024",
      "totalEarned": 500
    },
    "notificationPreferences": {
      "email": { "orderUpdates": true, "offers": true },
      "push": { "orderUpdates": true, "offers": true },
      "sms": { "orderUpdates": true, "offers": false }
    },
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

#### 2. Update Profile
```http
PUT /api/users/profile
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "name": "John Updated",
  "phone": "9876543211",
  "dietaryPreferences": ["vegan"],
  "allergies": ["peanuts", "dairy"],
  "notificationSettings": {
    "email": { "orderUpdates": true, "offers": false },
    "push": { "orderUpdates": true, "offers": true },
    "sms": { "orderUpdates": true, "offers": false }
  }
}
```

#### 3. Get Addresses
```http
GET /api/users/addresses
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "addr123",
      "user": "userId",
      "label": "Home",
      "street": "123 Main Street",
      "city": "Mumbai",
      "state": "Maharashtra",
      "pincode": "400001",
      "landmark": "Near City Mall",
      "location": {
        "type": "Point",
        "coordinates": [72.8777, 19.0760]
      },
      "isDefault": true,
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

#### 4. Add Address
```http
POST /api/users/addresses
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "label": "Office",
  "street": "456 Business Park",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400051",
  "landmark": "Next to Metro Station",
  "location": {
    "coordinates": [72.8856, 19.0821]
  },
  "isDefault": false
}
```

**Note:** If location is not provided, backend will auto-geocode from address.

#### 5. Update Address
```http
PUT /api/users/addresses/:id
Authorization: Bearer <token>
Content-Type: application/json
```

#### 6. Delete Address
```http
DELETE /api/users/addresses/:id
Authorization: Bearer <token>
```

#### 7. Get Notification Preferences
```http
GET /api/users/notification-preferences
Authorization: Bearer <token>
```

#### 8. Update Notification Preferences
```http
PUT /api/users/notification-preferences
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "email": { "orderUpdates": true, "offers": true },
  "push": { "orderUpdates": true, "offers": true },
  "sms": { "orderUpdates": true, "offers": false }
}
```

#### 9. Register FCM Token
```http
POST /api/users/fcm-token
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "token": "fcm_device_token",
  "deviceType": "android|ios|web"
}
```

#### 10. Remove FCM Token
```http
DELETE /api/users/fcm-token
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "token": "fcm_device_token"
}
```

---

## 🛍️ PRODUCT APIs

### Base: `/api/products`

#### 1. Get All Products (Public/Optional Auth)
```http
GET /api/products?page=1&limit=20&category=cat123&minPrice=10&maxPrice=100&sort=price_asc&search=tomato&tags=organic,farm-fresh&inStock=true&isOrganic=true
```

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| page | number | Page number (default: 1) |
| limit | number | Items per page (default: 20) |
| category | string | Category ID |
| merchant | string | Merchant ID |
| minPrice | number | Minimum price |
| maxPrice | number | Maximum price |
| sort | string | `price_asc`, `price_desc`, `newest`, `popular`, `rating` |
| search | string | Text search |
| tags | string | Comma-separated tags |
| inStock | boolean | Only in-stock products |
| isOrganic | boolean | Only organic products |

**Response:**
```json
{
  "success": true,
  "count": 20,
  "total": 150,
  "page": 1,
  "pages": 8,
  "data": [
    {
      "_id": "prod123",
      "name": "Organic Tomatoes",
      "description": "Fresh organic tomatoes...",
      "merchant": {
        "_id": "merch123",
        "businessName": "Green Farms",
        "averageRating": 4.5
      },
      "category": {
        "_id": "cat123",
        "name": "Vegetables",
        "icon": "https://..."
      },
      "price": 45.00,
      "comparePrice": 60.00,
      "unit": "kg",
      "stock": 50,
      "lowStockThreshold": 10,
      "images": [{ "url": "https://...", "publicId": "..." }],
      "primaryImage": "https://...",
      "tags": ["organic", "farm-fresh"],
      "averageRating": 4.3,
      "totalReviews": 28,
      "nutritionalInfo": {
        "calories": 18,
        "protein": 0.9,
        "carbohydrates": 3.9,
        "fat": 0.2
      },
      "origin": {
        "farm": "Green Valley Farm",
        "location": "Nashik, Maharashtra",
        "harvestDate": "2024-01-14T00:00:00Z"
      },
      "isSeasonal": true,
      "availableMonths": [1, 2, 3, 10, 11, 12],
      "status": "active",
      "isPremiumExclusive": false,
      "isPreBookable": false,
      "isActive": true,
      "isWishlisted": false
    }
  ]
}
```

#### 2. Search Products (Public)
```http
GET /api/products/search?q=tomato&filters=organic,in_stock
```

#### 3. Get Product by ID (Public/Optional Auth)
```http
GET /api/products/:id
Authorization: Bearer <token> (Optional)
```

**Response:** Includes `isWishlisted` field if authenticated.

#### 4. Get Merchant's Products (Merchant Only)
```http
GET /api/products/merchant/my-products
Authorization: Bearer <token>
```

#### 5. Create Product (Merchant Only)
```http
POST /api/products
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Fields:**
| Field | Type | Required |
|-------|------|----------|
| name | string | Yes |
| description | string | Yes |
| category | string (ID) | Yes |
| price | number | Yes |
| comparePrice | number | No |
| unit | string | Yes (kg, g, piece, dozen, bundle, liter) |
| stock | number | Yes |
| lowStockThreshold | number | No (default: 10) |
| images | files | Yes |
| tags | JSON array | No |
| nutritionalInfo | JSON object | No |
| preparationOptions | JSON array | No |
| isSeasonal | boolean | No |
| availableMonths | JSON array | No |

#### 6. Update Product (Merchant Only)
```http
PUT /api/products/:id
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

#### 7. Delete Product (Merchant Only)
```http
DELETE /api/products/:id
Authorization: Bearer <token>
```

#### 8. Update Stock (Merchant Only)
```http
PATCH /api/products/:id/stock
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "stock": 100
}
```

---

## 📂 CATEGORY APIs

### Base: `/api/categories`

#### 1. Get All Categories (Public)
```http
GET /api/categories
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "cat123",
      "name": "Vegetables",
      "description": "Fresh vegetables",
      "icon": "https://...",
      "image": "https://...",
      "order": 1,
      "isActive": true
    }
  ]
}
```

#### 2. Get Category by ID (Public)
```http
GET /api/categories/:id
```

#### 3. Create Category (Admin Only)
```http
POST /api/categories
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "name": "Fruits",
  "description": "Fresh fruits",
  "icon": "https://...",
  "image": "https://...",
  "order": 2
}
```

#### 4. Update Category (Admin Only)
```http
PUT /api/categories/:id
Authorization: Bearer <token>
Content-Type: application/json
```

#### 5. Delete Category (Admin Only)
```http
DELETE /api/categories/:id
Authorization: Bearer <token>
```

---

## 🛒 CART APIs

### Base: `/api/cart`

All routes require authentication.

#### 1. Get Cart
```http
GET /api/cart
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "cart": {
      "_id": "cart123",
      "user": "userId",
      "items": [
        {
          "product": {
            "_id": "prod123",
            "name": "Organic Tomatoes",
            "primaryImage": "https://...",
            "price": 45.00
          },
          "quantity": 2,
          "preparation": "whole",
          "price": 45.00,
          "addedAt": "2024-01-15T10:30:00Z"
        }
      ],
      "appliedCoupon": {
        "code": "SAVE10",
        "offerId": "offer123",
        "discount": 20.00
      },
      "total": 90.00,
      "discount": 20.00,
      "deliveryCharge": 30.00,
      "finalTotal": 100.00
    }
  }
}
```

#### 2. Add to Cart
```http
POST /api/cart/add
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "productId": "prod123",
  "quantity": 2,
  "preparation": "whole|cut|chopped|diced|sliced"
}
```

#### 3. Update Cart Item
```http
PUT /api/cart/update/:productId
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "quantity": 3,
  "preparation": "chopped"
}
```

#### 4. Remove from Cart
```http
DELETE /api/cart/remove/:productId?preparation=whole
Authorization: Bearer <token>
```

**Note:** Use query param `preparation` to specify which variant to remove.

#### 5. Clear Cart
```http
DELETE /api/cart/clear
Authorization: Bearer <token>
```

#### 6. Add Recipe to Cart
```http
POST /api/cart/recipe-to-cart
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "recipeId": "recipe123",
  "servings": 4
}
```

---

## 📦 ORDER APIs

### Base: `/api/orders`

#### 1. Create Order
```http
POST /api/orders
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "items": [
    {
      "product": "prod123",
      "quantity": 2,
      "preparation": "whole"
    }
  ],
  "deliveryAddress": "addr123",
  "deliveryType": "home-delivery|pickup",
  "paymentMethod": "cod|online|wallet",
  "deliveryTimeSlot": {
    "date": "2024-01-16",
    "startTime": "10:00",
    "endTime": "12:00"
  },
  "specialRequests": "Please ring doorbell twice",
  "couponCode": "SAVE10"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order placed successfully",
  "data": {
    "order": {
      "orderId": "GB1705312800123",
      "_id": "order123",
      "items": [...],
      "itemsTotal": 90.00,
      "deliveryCharges": 30.00,
      "discount": 20.00,
      "totalAmount": 100.00,
      "paymentStatus": "pending",
      "status": "pending",
      "estimatedDeliveryTime": "2024-01-16T11:30:00Z"
    }
  }
}
```

#### 2. Get My Orders (Customer)
```http
GET /api/orders/my-orders?status=pending&page=1&limit=10
Authorization: Bearer <token>
```

**Query Parameters:**
- `status`: Filter by status
- `page`: Page number
- `limit`: Items per page

#### 3. Get Order by ID
```http
GET /api/orders/:id
Authorization: Bearer <token>
```

**Note:** `:id` can be either MongoDB `_id` or `orderId` (e.g., GB1705312800123).

#### 4. Cancel Order
```http
PATCH /api/orders/:id/cancel
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "reason": "Changed my mind"
}
```

#### 5. Track Order (Enhanced)
```http
GET /api/orders/:id/track
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "orderId": "GB1705312800123",
    "status": "out-for-delivery",
    "progress": 75,
    "estimatedDelivery": "2024-01-16T11:30:00Z",
    "currentLocation": { "lat": 19.0760, "lng": 72.8777 },
    "timeline": [
      { "status": "pending", "timestamp": "2024-01-15T10:30:00Z", "note": "Order placed" },
      { "status": "confirmed", "timestamp": "2024-01-15T10:32:00Z", "note": "Merchant confirmed" }
    ],
    "deliveryPersonnel": {
      "name": "Rahul Kumar",
      "phone": "9876543210"
    }
  }
}
```

#### 6. Get Order Tracking (Detailed)
```http
GET /api/orders/:orderId/tracking
Authorization: Bearer <token>
```

#### 7. Update Order Location
```http
PATCH /api/orders/:id/location
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "lat": 19.0760,
  "lng": 72.8777
}
```

#### 8. Get Merchant Orders (Merchant Only)
```http
GET /api/orders/merchant/orders?status=confirmed&page=1&limit=10
Authorization: Bearer <token>
```

#### 9. Update Order Status (Merchant Only)
```http
PATCH /api/orders/merchant/:id/status
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "status": "confirmed|ready|out-for-delivery|delivered|cancelled",
  "note": "Order is being prepared"
}
```

**Note:** Auto-assignment of delivery agent happens when status changes to `confirmed`.

---

## 💳 PAYMENT APIs

### Base: `/api/payment`

All routes require authentication.

#### 1. Create Payment Order
```http
POST /api/payment/create-order
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "orderId": "order123",
  "paymentMethod": "card|upi|netbanking|wallet|emi"
}
```

**Response (Stripe):**
```json
{
  "success": true,
  "data": {
    "gateway": "stripe",
    "paymentIntentId": "pi_3O...",
    "clientSecret": "pi_3O...secret_...",
    "amount": 100.00,
    "currency": "inr"
  }
}
```

#### 2. Verify Payment
```http
POST /api/payment/verify
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "orderId": "order123",
  "paymentIntentId": "pi_3O...",
  "status": "succeeded"
}
```

#### 3. Get Payment Methods
```http
GET /api/payment/methods
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "methods": [
      { "id": "card", "name": "Credit/Debit Card", "enabled": true },
      { "id": "upi", "name": "UPI", "enabled": true },
      { "id": "netbanking", "name": "Net Banking", "enabled": true },
      { "id": "wallet", "name": "Wallet", "enabled": true },
      { "id": "emi", "name": "EMI", "enabled": false },
      { "id": "cod", "name": "Cash on Delivery", "enabled": true }
    ]
  }
}
```

#### 4. Get Payment History
```http
GET /api/payment/history
Authorization: Bearer <token>
```

#### 5. Get Payment Status
```http
GET /api/payment/:orderId/status
Authorization: Bearer <token>
```

#### 6. Retry Payment
```http
POST /api/payment/:orderId/retry
Authorization: Bearer <token>
Content-Type: application/json
```

#### 7. Process Refund
```http
POST /api/payment/refund
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "orderId": "order123",
  "reason": "Customer request"
}
```

### Webhook (No Auth)
```http
POST /api/payment/webhook
Content-Type: application/json
```

**Note:** Raw body, Stripe signature verification.

---

## 🏪 MERCHANT APIs

### Base: `/api/merchants`

#### 1. Get All Merchants (Public)
```http
GET /api/ merchants?page=1&limit=20
```

#### 2. Get Merchant by ID (Public)
```http
GET /api/merchants/:id
```

#### 3. Get Profile (Merchant Only)
```http
GET /api/merchants/profile
Authorization: Bearer <token>
```

#### 4. Update Profile (Merchant Only)
```http
PUT /api/merchants/profile
Authorization: Bearer <token>
Content-Type: application/json
```

#### 5. Upload Image (Merchant Only)
```http
POST /api/merchants/upload-image
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Field:** `image` (file)

#### 6. Toggle Store Status (Merchant Only)
```http
PATCH /api/merchants/toggle-store
Authorization: Bearer <token>
```

#### 7. Get Dashboard Stats (Merchant Only)
```http
GET /api/merchants/dashboard-stats
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalOrders": 156,
    "totalRevenue": 45250.00,
    "todayOrders": 5,
    "todayRevenue": 1250.00,
    "pendingOrders": 3,
    "lowStockProducts": 2,
    "averageRating": 4.5,
    "recentOrders": [...],
    "topProducts": [...]
  }
}
```

#### 8. Update Password (Merchant Only)
```http
PATCH /api/merchants/update-password
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "currentPassword": "oldpass",
  "newPassword": "newpass"
}
```

#### 9. Update Notification Settings (Merchant Only)
```http
PATCH /api/merchants/notification-settings
Authorization: Bearer <token>
Content-Type: application/json
```

---

## 👨‍💼 ADMIN APIs

### Base: `/api/admin`

All routes require admin authentication.

#### 1. Get Pending Merchants
```http
GET /api/admin/merchants/pending
Authorization: Bearer <token>
```

#### 2. Verify Merchant
```http
PATCH /api/admin/merchants/:id/verify
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "status": "approved|rejected",
  "rejectionReason": "Documents not clear"
}
```

#### 3. Get All Merchants
```http
GET /api/admin/merchants/all
Authorization: Bearer <token>
```

#### 4. Get Users
```http
GET /api/admin/users?page=1&limit=20&search=john
Authorization: Bearer <token>
```

#### 5. Toggle User Block
```http
PATCH /api/admin/users/:id/block
Authorization: Bearer <token>
```

#### 6. Get Platform Stats
```http
GET /api/admin/stats
Authorization: Bearer <token>
```

#### 7. Get All Subscriptions
```http
GET /api/admin/subscriptions/all
Authorization: Bearer <token>
```

#### 8. Get All Agents
```http
GET /api/admin/agents
Authorization: Bearer <token>
```

#### 9. Get Agent by ID
```http
GET /api/admin/agents/:id
Authorization: Bearer <token>
```

#### 10. Get Agent Assignments
```http
GET /api/admin/agents/:id/assignments
Authorization: Bearer <token>
```

#### 11. Verify Agent
```http
PATCH /api/admin/agents/:id/verify
Authorization: Bearer <token>
```

#### 12. Toggle Agent Active
```http
PATCH /api/admin/agents/:id/toggle-active
Authorization: Bearer <token>
```

#### 13. Get Delivery Analytics
```http
GET /api/admin/agents/analytics
Authorization: Bearer <token>
```

#### 14. Manually Assign Order
```http
POST /api/admin/orders/:orderId/assign/:agentId
Authorization: Bearer <token>
```

#### 15. Get Unassigned Orders
```http
GET /api/admin/orders/unassigned
Authorization: Bearer <token>
```

#### 16. Get All Assignments
```http
GET /api/admin/assignments
Authorization: Bearer <token>
```

---

## 🔔 NOTIFICATION APIs

### Base: `/api/notifications`

All routes require authentication.

#### 1. Get Notifications
```http
GET /api/notifications?page=1&limit=20
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "count": 10,
  "total": 25,
  "unreadCount": 3,
  "data": [
    {
      "_id": "notif123",
      "type": "order",
      "title": "Order Confirmed",
      "message": "Your order GB1705312800123 has been confirmed",
      "data": {
        "orderId": "order123",
        "orderNumber": "GB1705312800123"
      },
      "isRead": false,
      "createdAt": "2024-01-15T10:32:00Z"
    }
  ]
}
```

#### 2. Get Unread Count
```http
GET /api/notifications/unread-count
Authorization: Bearer <token>
```

#### 3. Mark as Read
```http
PATCH /api/notifications/:id/read
Authorization: Bearer <token>
```

#### 4. Mark All as Read
```http
PATCH /api/notifications/read-all
Authorization: Bearer <token>
```

#### 5. Delete Notification
```http
DELETE /api/notifications/:id
Authorization: Bearer <token>
```

#### 6. Clear All Notifications
```http
DELETE /api/notifications/clear-all
Authorization: Bearer <token>
```

#### 7. Send Test Notification (Admin)
```http
POST /api/notifications/admin/test
Authorization: Bearer <token>
Content-Type: application/json
```

#### 8. Bulk Send Notifications (Admin)
```http
POST /api/notifications/admin/bulk-send
Authorization: Bearer <token>
Content-Type: application/json
```

---

## ❤️ WISHLIST APIs

### Base: `/api/wishlist`

All routes require authentication.

#### 1. Get Wishlist
```http
GET /api/wishlist
Authorization: Bearer <token>
```

#### 2. Add to Wishlist
```http
POST /api/wishlist/add
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "productId": "prod123"
}
```

#### 3. Remove from Wishlist
```http
DELETE /api/wishlist/remove/:productId
Authorization: Bearer <token>
```

#### 4. Move to Cart
```http
POST /api/wishlist/move-to-cart/:productId
Authorization: Bearer <token>
```

#### 5. Check if Wishlisted
```http
GET /api/wishlist/check/:productId
Authorization: Bearer <token>
```

---

## ⭐ REVIEW APIs

### Base: `/api/reviews`

#### 1. Get Product Reviews (Public)
```http
GET /api/reviews/product/:productId
```

#### 2. Get Merchant Reviews (Public)
```http
GET /api/reviews/merchant/:merchantId
```

#### 3. Add Review (User Only)
```http
POST /api/reviews
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "orderId": "order123",
  "productId": "prod123",
  "rating": 5,
  "comment": "Great quality!",
  "images": ["https://..."]
}
```

#### 4. Get My Reviews (User Only)
```http
GET /api/reviews/my-reviews
Authorization: Bearer <token>
```

#### 5. Update Review (User Only)
```http
PUT /api/reviews/:id
Authorization: Bearer <token>
Content-Type: application/json
```

#### 6. Delete Review (User/Admin)
```http
DELETE /api/reviews/:id
Authorization: Bearer <token>
```

#### 7. Reply to Review (Merchant Only)
```http
POST /api/reviews/:id/reply
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "reply": "Thank you for your feedback!"
}
```

---

## 🔄 SUBSCRIPTION APIs

### Base: `/api/subscriptions`

All routes require authentication.

#### 1. Create Subscription
```http
POST /api/subscriptions
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "productId": "prod123",
  "frequency": "weekly|biweekly|monthly",
  "quantity": 2,
  "deliveryDay": "monday",
  "deliveryAddress": "addr123",
  "startDate": "2024-01-20"
}
```

#### 2. Get My Subscriptions
```http
GET /api/subscriptions
Authorization: Bearer <token>
```

#### 3. Get Subscription by ID
```http
GET /api/subscriptions/:id
Authorization: Bearer <token>
```

#### 4. Update Subscription
```http
PUT /api/subscriptions/:id
Authorization: Bearer <token>
Content-Type: application/json
```

#### 5. Delete Subscription
```http
DELETE /api/subscriptions/:id
Authorization: Bearer <token>
```

#### 6. Update Subscription Status
```http
PATCH /api/subscriptions/:id/status
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "status": "active|paused|cancelled"
}
```

#### 7. Get Merchant Subscriptions (Merchant Only)
```http
GET /api/subscriptions/merchant/all
Authorization: Bearer <token>
```

---

## 🎁 OFFER/COUPON APIs

### Base: `/api/offers`

#### 1. Get Flash Sales (Public)
```http
GET /api/offers/flash-sales
```

#### 2. Get Available Offers (User)
```http
GET /api/offers/available
Authorization: Bearer <token>
```

#### 3. Apply Coupon (User)
```http
POST /api/offers/cart/apply-coupon
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "code": "SAVE10"
}
```

#### 4. Remove Coupon (User)
```http
DELETE /api/offers/cart/remove-coupon
Authorization: Bearer <token>
```

#### 5. Get Merchant Offers (Merchant)
```http
GET /api/offers/merchant
Authorization: Bearer <token>
```

#### 6. Create Offer (Merchant/Admin)
```http
POST /api/offers
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "name": "Summer Sale",
  "code": "SUMMER20",
  "type": "percentage|fixed|free_delivery",
  "value": 20,
  "minOrderValue": 500,
  "maxDiscount": 200,
  "startDate": "2024-01-01",
  "endDate": "2024-01-31",
  "applicableProducts": ["prod123"],
  "applicableCategories": ["cat123"]
}
```

#### 7. Update Offer (Merchant/Admin)
```http
PUT /api/offers/:id
Authorization: Bearer <token>
Content-Type: application/json
```

#### 8. Delete Offer (Merchant/Admin)
```http
DELETE /api/offers/:id
Authorization: Bearer <token>
```

#### 9. Get Offer Analytics (Merchant/Admin)
```http
GET /api/offers/:id/analytics
Authorization: Bearer <token>
```

#### 10. Get All Offers (Admin)
```http
GET /api/offers/admin/all
Authorization: Bearer <token>
```

---

## 🎬 RECIPE APIs

### Base: `/api/recipes`

#### 1. Get All Recipes (Public)
```http
GET /api/recipes?page=1&limit=20
```

#### 2. Search Recipes (Public)
```http
GET /api/recipes/search?q=salad&dietary=vegetarian
```

#### 3. Get Recipe by ID (Public)
```http
GET /api/recipes/:id
```

#### 4. Calculate Ingredients (Public)
```http
POST /api/recipes/:id/calculate-ingredients
Content-Type: application/json
```

**Request:**
```json
{
  "servings": 6
}
```

#### 5. Create Recipe (Admin)
```http
POST /api/recipes
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Fields:**
| Field | Type |
|-------|------|
| name | string |
| description | string |
| servings | number |
| prepTime | number (minutes) |
| cookTime | number (minutes) |
| ingredients | JSON array |
| instructions | JSON array |
| dietaryTags | JSON array |
| image | file |

#### 6. Update Recipe (Admin)
```http
PUT /api/recipes/:id
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

#### 7. Delete Recipe (Admin)
```http
DELETE /api/recipes/:id
Authorization: Bearer <token>
```

---

## 📊 MERCHANT ANALYTICS APIs

### Base: `/api/merchants/analytics`

All routes require merchant authentication.

#### 1. Sales Analytics
```http
GET /api/merchants/analytics/sales?period=7d
Authorization: Bearer <token>
```

#### 2. Product Analytics
```http
GET /api/merchants/analytics/products
Authorization: Bearer <token>
```

#### 3. Customer Analytics
```http
GET /api/merchants/analytics/customers
Authorization: Bearer <token>
```

#### 4. Inventory Analytics
```http
GET /api/merchants/analytics/inventory
Authorization: Bearer <token>
```

#### 5. Revenue Forecast
```http
GET /api/merchants/analytics/forecast
Authorization: Bearer <token>
```

#### 6. Review Analytics
```http
GET /api/merchants/analytics/reviews
Authorization: Bearer <token>
```

---

## 🚚 DELIVERY ZONE APIs

### Base: `/api/merchants/zones`

#### 1. Check Delivery Availability (Public)
```http
POST /api/merchants/zones/check-delivery
Content-Type: application/json
```

**Request:**
```json
{
  "merchantId": "merch123",
  "coordinates": [72.8777, 19.0760]
}
```

#### 2. Get Nearby Merchants (Public)
```http
POST /api/merchants/zones/nearby
Content-Type: application/json
```

**Request:**
```json
{
  "coordinates": [72.8777, 19.0760],
  "radius": 5
}
```

#### 3. Set Merchant Location (Merchant)
```http
PUT /api/merchants/zones/location
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "coordinates": [72.8777, 19.0760],
  "address": "123 Main St, Mumbai"
}
```

#### 4. Get Delivery Zones (Merchant)
```http
GET /api/merchants/zones/delivery-zones
Authorization: Bearer <token>
```

#### 5. Add Delivery Zone (Merchant)
```http
POST /api/merchants/zones/delivery-zones
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "name": "Zone 1",
  "radiusKm": 5,
  "deliveryCharge": 30,
  "minimumOrder": 200,
  "freeDeliveryAbove": 500,
  "estimatedDeliveryTime": "30-45 mins"
}
```

#### 6. Update Delivery Zone (Merchant)
```http
PUT /api/merchants/zones/delivery-zones/:zoneId
Authorization: Bearer <token>
Content-Type: application/json
```

#### 7. Delete Delivery Zone (Merchant)
```http
DELETE /api/merchants/zones/delivery-zones/:zoneId
Authorization: Bearer <token>
```

---

## 👑 MEMBERSHIP APIs

### Base: `/api/membership`

#### 1. Get Plans (Public)
```http
GET /api/membership/plans
```

#### 2. Get My Membership (User)
```http
GET /api/membership
Authorization: Bearer <token>
```

#### 3. Initiate Membership Subscription (User)
```http
POST /api/membership/initiate
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "planId": "plan123"
}
```

#### 4. Activate Membership (User)
```http
POST /api/membership/activate
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "paymentIntentId": "pi_3O..."
}
```

#### 5. Cancel Membership (User)
```http
POST /api/membership/cancel
Authorization: Bearer <token>
```

#### 6. Get Premium Products (User)
```http
GET /api/membership/premium-products
Authorization: Bearer <token>
```

#### 7. Check Benefit Eligibility (User)
```http
GET /api/membership/check-benefit?benefit=free_delivery
Authorization: Bearer <token>
```

#### 8. Get Membership History (User)
```http
GET /api/membership/history
Authorization: Bearer <token>
```

#### 9. Get All Memberships (Admin)
```http
GET /api/membership/admin/all
Authorization: Bearer <token>
```

---

## 📅 PRE-BOOKING APIs

### Base: `/api/prebooking`

All routes require authentication.

#### 1. Create Pre-Booking (User)
```http
POST /api/prebooking
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "productId": "prod123",
  "quantity": 2
}
```

#### 2. Get My Pre-Bookings (User)
```http
GET /api/prebooking/my-prebookings
Authorization: Bearer <token>
```

#### 3. Cancel Pre-Booking (User)
```http
DELETE /api/prebooking/:id
Authorization: Bearer <token>
```

#### 4. Convert to Order (User)
```http
POST /api/prebooking/:id/convert-to-order
Authorization: Bearer <token>
```

#### 5. Mark Product Available (Merchant)
```http
PATCH /api/prebooking/products/:id/mark-available
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "availableDate": "2024-01-20"
}
```

#### 6. Update Pre-Booking Status (Merchant)
```http
PATCH /api/prebooking/:id/update-status
Authorization: Bearer <token>
Content-Type: application/json
```

#### 7. Update Pre-Booking Settings (Merchant)
```http
PATCH /api/prebooking/merchant/products/:productId/prebooking
Authorization: Bearer <token>
Content-Type: application/json
```

#### 8. Get Merchant Pre-Bookings (Merchant)
```http
GET /api/prebooking/merchant/all
Authorization: Bearer <token>
```

#### 9. Get All Pre-Bookings (Admin)
```http
GET /api/prebooking/admin/all
Authorization: Bearer <token>
```

---

## 📄 DOCUMENT APIs

### Base: `/api/documents`

#### 1. Upload Document (Merchant)
```http
POST /api/documents/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Fields:**
| Field | Type | Description |
|-------|------|-------------|
| type | string | fssai, gst, pan, aadhaar, bank_details, organic_certificate, farm_ownership, other |
| documentNumber | string | Document number |
| document | file | File to upload |
| expiryDate | date | Expiry date |
| notes | string | Additional notes |

#### 2. Get Merchant Documents (Merchant)
```http
GET /api/documents
Authorization: Bearer <token>
```

#### 3. Get Document History (Merchant)
```http
GET /api/documents/history
Authorization: Bearer <token>
```

#### 4. Delete Document (Merchant)
```http
DELETE /api/documents/:documentId
Authorization: Bearer <token>
```

#### 5. Get Pending Documents (Admin)
```http
GET /api/documents/admin/pending
Authorization: Bearer <token>
```

#### 6. Verify Document (Admin)
```http
PUT /api/documents/admin/:merchantId/:documentId/verify
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "status": "verified|rejected",
  "rejectionReason": "Document unclear"
}
```

#### 7. Get Expiring Documents (Admin)
```http
GET /api/documents/admin/expiring-soon
Authorization: Bearer <token>
```

---

## ⚠️ DISPUTE APIs

### Base: `/api/disputes`

All routes require authentication.

#### 1. Raise Dispute (User)
```http
POST /api/disputes
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "orderId": "order123",
  "type": "missing_items|damaged_items|wrong_items|quality_issue|late_delivery|other",
  "description": "Items were damaged",
  "images": ["https://..."]
}
```

#### 2. Get My Disputes (User)
```http
GET /api/disputes/my-disputes
Authorization: Bearer <token>
```

#### 3. Get Dispute by ID
```http
GET /api/disputes/:id
Authorization: Bearer <token>
```

#### 4. Add Message
```http
POST /api/disputes/:id/message
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "message": "I have attached photos"
}
```

#### 5. Escalate Dispute (User)
```http
PATCH /api/disputes/:id/escalate
Authorization: Bearer <token>
```

#### 6. Get All Disputes (Admin)
```http
GET /api/disputes/admin/all
Authorization: Bearer <token>
```

#### 7. Resolve Dispute (Admin)
```http
PUT /api/disputes/admin/:id/resolve
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "resolution": "refund|replacement|partial_refund|rejected",
  "refundAmount": 100,
  "notes": "Approved full refund"
}
```

#### 8. Update Dispute Status (Admin)
```http
PATCH /api/disputes/admin/:id/status
Authorization: Bearer <token>
Content-Type: application/json
```

---

## 💵 FINANCIAL APIs

### Base: `/api/financial`

All routes require authentication.

#### 1. Get Merchant Earnings (Merchant)
```http
GET /api/financial/merchants/earnings?startDate=2024-01-01&endDate=2024-01-31
Authorization: Bearer <token>
```

#### 2. Get Merchant Payouts (Merchant)
```http
GET /api/financial/merchants/payouts
Authorization: Bearer <token>
```

#### 3. Request Payout (Merchant)
```http
POST /api/financial/merchants/request-payout
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "amount": 5000
}
```

#### 4. Get Payout by ID
```http
GET /api/financial/payouts/:id
Authorization: Bearer <token>
```

#### 5. Get All Payouts (Admin)
```http
GET /api/financial/admin/payouts
Authorization: Bearer <token>
```

#### 6. Generate Payouts (Admin)
```http
POST /api/financial/admin/payouts/generate
Authorization: Bearer <token>
```

#### 7. Process Payout (Admin)
```http
POST /api/financial/admin/payouts/:id/process
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "transactionId": "TXN123456",
  "notes": "Processed via NEFT"
}
```

#### 8. Hold/Release Payout (Admin)
```http
PATCH /api/financial/admin/payouts/:id/hold
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "hold": true,
  "reason": "Dispute pending"
}
```

#### 9. Get Financial Reports (Admin)
```http
GET /api/financial/admin/reports/financial?startDate=2024-01-01&endDate=2024-01-31
Authorization: Bearer <token>
```

#### 10. Get GST Report (Admin)
```http
GET /api/financial/admin/reports/gst?month=1&year=2024
Authorization: Bearer <token>
```

#### 11. Update Commission Settings (Admin)
```http
PUT /api/financial/admin/settings/commission
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "commissionPercentage": 10
}
```

---

## 📦 BULK OPERATIONS APIs

### Base: `/api/bulk`

All routes require merchant authentication.

#### 1. Bulk Upload Products
```http
POST /api/bulk/products/bulk-upload
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Field:** `file` (CSV file, max 5MB)

**CSV Format:**
```
name,description,category,price,stock,unit
tomato,Fresh tomato,cat123,45,100,kg
```

#### 2. Bulk Update Price
```http
PUT /api/bulk/products/bulk-update-price
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "updates": [
    { "productId": "prod123", "price": 50 },
    { "productId": "prod124", "price": 60 }
  ]
}
```

#### 3. Bulk Update Stock
```http
PUT /api/bulk/products/bulk-update-stock
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "updates": [
    { "productId": "prod123", "stock": 100 },
    { "productId": "prod124", "stock": 50 }
  ]
}
```

#### 4. Export Products
```http
GET /api/bulk/products/export
Authorization: Bearer <token>
```

**Response:** CSV file download.

---

## 🔍 SEARCH APIs

### Base: `/api/search`

All routes are public.

#### 1. Advanced Product Search
```http
GET /api/search/products?q=tomato&category=cat123&minPrice=10&maxPrice=100&sort=relevance&page=1
```

#### 2. Get Search Suggestions
```http
GET /api/search/suggestions?q=tom
```

**Response:**
```json
{
  "success": true,
  "data": {
    "suggestions": ["tomato", "tomato sauce", "tomato soup"]
  }
}
```

#### 3. Get Trending Products
```http
GET /api/search/trending
```

---

## ↩️ RETURN APIs

### Base: `/api/returns`

All routes require authentication.

#### 1. Request Return (User)
```http
POST /api/returns
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "orderId": "order123",
  "items": [
    { "productId": "prod123", "quantity": 1, "reason": "damaged" }
  ],
  "reason": "Items were damaged",
  "images": ["https://..."]
}
```

#### 2. Get My Returns (User)
```http
GET /api/returns/my-returns
Authorization: Bearer <token>
```

#### 3. Get Return by ID
```http
GET /api/returns/:id
Authorization: Bearer <token>
```

#### 4. Cancel Return (User)
```http
DELETE /api/returns/:id
Authorization: Bearer <token>
```

#### 5. Get All Returns (Admin)
```http
GET /api/returns/admin/all
Authorization: Bearer <token>
```

#### 6. Process Return (Admin)
```http
PUT /api/returns/admin/:id/process
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "status": "approved|rejected",
  "refundAmount": 100,
  "notes": "Approved for refund"
}
```

---

## 🎁 GIFT CARD APIs

### Base: `/api/gift-cards`

#### 1. Check Balance (Public)
```http
GET /api/gift-cards/balance/:code
```

**Response:**
```json
{
  "success": true,
  "data": {
    "code": "GBGIFT123",
    "balance": 500,
    "expiryDate": "2024-12-31",
    "isActive": true
  }
}
```

#### 2. Validate Gift Card (User)
```http
POST /api/gift-cards/validate
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "code": "GBGIFT123"
}
```

#### 3. Redeem Gift Card (User)
```http
POST /api/gift-cards/redeem
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "code": "GBGIFT123"
}
```

#### 4. Get My Gift Cards (User)
```http
GET /api/gift-cards/my-cards
Authorization: Bearer <token>
```

#### 5. Initiate Gift Card Purchase (User)
```http
POST /api/gift-cards/purchase/initiate
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "amount": 500,
  "recipientEmail": "friend@example.com",
  "message": "Happy Birthday!"
}
```

#### 6. Verify Gift Card Purchase (User)
```http
POST /api/gift-cards/purchase/verify
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "paymentIntentId": "pi_3O..."
}
```

#### 7. Generate Gift Card (Admin)
```http
POST /api/gift-cards/admin/generate
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "amount": 500,
  "quantity": 10,
  "expiryMonths": 12
}
```

#### 8. Get All Gift Cards (Admin)
```http
GET /api/gift-cards/admin/all
Authorization: Bearer <token>
```

#### 9. Cancel Gift Card (Admin)
```http
PATCH /api/gift-cards/admin/:id/cancel
Authorization: Bearer <token>
```

---

## 🚴 DELIVERY AGENT APIs

### Base: `/api/agents`

#### 1. Register (Public)
```http
POST /api/agents/register
Content-Type: application/json
```

**Request:**
```json
{
  "name": "Rahul Kumar",
  "email": "rahul@example.com",
  "phone": "9876543210",
  "password": "password123",
  "vehicleType": "bike|scooter|bicycle|car",
  "vehicleNumber": "MH12AB1234",
  "licenseNumber": "DL123456",
  "address": {
    "street": "123 Street",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001"
  }
}
```

#### 2. Login (Public)
```http
POST /api/agents/login
Content-Type: application/json
```

**Request:**
```json
{
  "email": "rahul@example.com",
  "password": "password123"
}
```

#### 3. Get Profile (Agent)
```http
GET /api/agents/me
Authorization: Bearer <token>
```

#### 4. Update Profile (Agent)
```http
PUT /api/agents/me
Authorization: Bearer <token>
Content-Type: application/json
```

#### 5. Update Status (Agent)
```http
PUT /api/agents/me/status
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "status": "available|busy|offline"
}
```

#### 6. Update Location (Agent)
```http
POST /api/agents/me/location
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "lat": 19.0760,
  "lng": 72.8777
}
```

#### 7. Get Current Assignment (Agent)
```http
GET /api/agents/assignments/current
Authorization: Bearer <token>
```

#### 8. Get My Assignments (Agent)
```http
GET /api/agents/assignments
Authorization: Bearer <token>
```

#### 9. Get Assignment by ID (Agent)
```http
GET /api/agents/assignments/:id
Authorization: Bearer <token>
```

#### 10. Update Assignment Status (Agent)
```http
PUT /api/agents/assignments/:id/status
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "status": "picked_up|in_transit|delivered|failed",
  "note": "Customer not available"
}
```

#### 11. Get Earnings (Agent)
```http
GET /api/agents/earnings?period=weekly
Authorization: Bearer <token>
```

---

## 📤 UPLOAD APIs

### Base: `/api/upload`

All routes require authentication.

#### 1. Upload Image
```http
POST /api/upload/image
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Field:** `image` (file)

#### 2. Upload Multiple Images
```http
POST /api/upload/images
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Field:** `images` (multiple files)

#### 3. Upload Document
```http
POST /api/upload/document
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Field:** `document` (file) - Merchant/Admin only

#### 4. Get My Uploads
```http
GET /api/upload/my-uploads
Authorization: Bearer <token>
```

#### 5. Get Upload by ID
```http
GET /api/upload/:uploadId
Authorization: Bearer <token>
```

#### 6. Delete Upload
```http
DELETE /api/upload/:uploadId
Authorization: Bearer <token>
```

#### 7. Bulk Delete Uploads (Merchant/Admin)
```http
POST /api/upload/bulk-delete
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "uploadIds": ["upload1", "upload2"]
}
```

#### 8. Update Product Images (Merchant/Admin)
```http
PUT /api/upload/products/:productId/images
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "images": [
    { "url": "https://...", "publicId": "..." }
  ],
  "primaryImage": "https://..."
}
```

---

## 📊 API Summary

### Total Endpoints: 221+

| Module | Endpoints | Auth |
|--------|-----------|------|
| Auth | 11 | Mixed |
| Users | 10 | User |
| Products | 8 | Mixed |
| Categories | 5 | Mixed |
| Cart | 6 | User |
| Orders | 9 | Mixed |
| Payments | 8 | Mixed |
| Merchants | 9 | Mixed |
| Admin | 16 | Admin |
| Notifications | 8 | Mixed |
| Wishlist | 5 | User |
| Reviews | 7 | Mixed |
| Subscriptions | 7 | Mixed |
| Offers | 10 | Mixed |
| Recipes | 7 | Mixed |
| Analytics | 6 | Merchant |
| Delivery Zones | 7 | Mixed |
| Membership | 9 | Mixed |
| Pre-booking | 9 | Mixed |
| Documents | 7 | Mixed |
| Disputes | 8 | Mixed |
| Financial | 11 | Mixed |
| Bulk Ops | 4 | Merchant |
| Search | 3 | Public |
| Returns | 6 | Mixed |
| Gift Cards | 9 | Mixed |
| Delivery Agents | 17 | Mixed |
| Uploads | 8 | Mixed |

---

## 🔌 WebSocket Events

### Connection: `wss://api.greenbasket.com`

#### Order Events
| Event | Direction | Data |
|-------|-----------|------|
| `join_order` | Send | `{ orderId }` |
| `order:status_update` | Receive | `{ orderId, status, timestamp }` |
| `order:location_update` | Receive | `{ orderId, location: { lat, lng } }` |
| `order:new` | Receive | `{ order }` - Merchant only |

#### Agent Events
| Event | Direction | Data |
|-------|-----------|------|
| `agent:location` | Send | `{ lat, lng }` |
| `agent:assigned` | Receive | `{ assignment }` |

#### Notification Events
| Event | Direction | Data |
|-------|-----------|------|
| `notification:new` | Receive | `{ notification }` |

---

## ⚠️ Error Responses

### Standard Error Format
```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "VALIDATION_ERROR",
    "details": [...]
  }
}
```

### HTTP Status Codes
| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Validation Error |
| 429 | Rate Limited |
| 500 | Server Error |

### Common Error Codes
| Code | Description |
|------|-------------|
| `INVALID_CREDENTIALS` | Wrong email/password |
| `TOKEN_EXPIRED` | JWT token expired |
| `INSUFFICIENT_STOCK` | Product out of stock |
| `INVALID_COUPON` | Coupon code invalid |
| `PAYMENT_FAILED` | Payment processing failed |

---

## 📱 Rate Limiting

| Endpoint Type | Limit |
|---------------|-------|
| General | 100 req/min |
| Auth | 5 req/min |
| Payment | 10 req/min |

---

## 🔗 Deep Links

| URL | Screen |
|-----|--------|
| `greenbasket://product/:id` | Product Detail |
| `greenbasket://order/:id` | Order Detail |
| `greenbasket://category/:id` | Category |
| `greenbasket://referral/:code` | Signup with Referral |

---

**Documentation generated from complete backend analysis**
