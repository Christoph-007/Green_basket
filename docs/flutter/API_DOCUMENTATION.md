# 📚 GreenBasket API Documentation

Complete API reference for Flutter frontend development.

## Table of Contents
1. [Authentication](#1-authentication)
2. [User Management](#2-user-management)
3. [Products](#3-products)
4. [Cart](#4-cart)
5. [Orders](#5-orders)
6. [Payments](#6-payments)
7. [Merchant](#7-merchant)
8. [Wishlist](#8-wishlist)
9. [Wallet](#9-wallet)
10. [Notifications](#10-notifications)

---

## 1. AUTHENTICATION

### Unified Login
Login for all roles (User, Merchant, Admin) with a single endpoint.

```http
POST /api/auth/login
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Success Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "role": "user",
    "user": {
      "_id": "65a1b2c3d4e5f6g7h8i9j0k1",
      "name": "John Doe",
      "email": "user@example.com",
      "phone": "9876543210",
      "profileImage": "https://...",
      "isPremium": false,
      "loyaltyPoints": 150,
      "loyaltyTier": "silver",
      "walletBalance": 500.00
    }
  }
}
```

### User Signup
```http
POST /api/auth/user/signup
Content-Type: application/json
```

**Request Body:**
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

**Success Response:**
```json
{
  "success": true,
  "message": "Account created successfully. Please verify your email.",
  "data": {
    "userId": "65a1b2c3d4e5f6g7h8i9j0k1",
    "email": "john@example.com",
    "requiresEmailVerification": true
  }
}
```

### Verify Email
```http
POST /api/auth/user/verify-email
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "john@example.com",
  "otp": "123456"
}
```

### Forgot Password
```http
POST /api/auth/user/forgot-password
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

### Refresh Token
```http
POST /api/auth/refresh-token
Content-Type: application/json
```

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## 2. USER MANAGEMENT

### Get Profile
```http
GET /api/users/profile
Authorization: Bearer <token>
```

**Success Response:**
```json
{
  "success": true,
  "data": {
    "_id": "65a1b2c3d4e5f6g7h8i9j0k1",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210",
    "profileImage": "https://cloudinary.com/...",
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

### Update Profile
```http
PUT /api/users/profile
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "John Updated",
  "phone": "9876543211",
  "dietaryPreferences": ["vegan"],
  "allergies": ["peanuts", "dairy"]
}
```

### Get Addresses
```http
GET /api/users/addresses
Authorization: Bearer <token>
```

**Success Response:**
```json
{
  "success": true,
  "count": 2,
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

### Add Address
```http
POST /api/users/addresses
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
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

### Register FCM Token
```http
POST /api/users/fcm-token
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "token": "fcm_token_string",
  "deviceType": "android"
}
```

---

## 3. PRODUCTS

### Get All Products
```http
GET /api/products?page=1&limit=20&category=cat123&minPrice=10&maxPrice=100&sort=price_asc
```

**Query Parameters:**
- `page` (number): Page number (default: 1)
- `limit` (number): Items per page (default: 20)
- `category` (string): Category ID
- `merchant` (string): Merchant ID
- `minPrice` (number): Minimum price filter
- `maxPrice` (number): Maximum price filter
- `sort` (string): Sort options - `price_asc`, `price_desc`, `newest`, `popular`, `rating`
- `search` (string): Text search
- `tags` (string): Comma-separated tags (organic, farm-fresh, seasonal)
- `inStock` (boolean): Only in-stock products
- `isOrganic` (boolean): Only organic products

**Success Response:**
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
      "description": "Fresh organic tomatoes from local farms",
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
      "images": [
        { "url": "https://...", "publicId": "..." }
      ],
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
      "isPreBookable": false
    }
  ]
}
```

### Get Product by ID
```http
GET /api/products/:id
Authorization: Bearer <token> (Optional)
```

**Success Response:**
```json
{
  "success": true,
  "data": {
    "_id": "prod123",
    "name": "Organic Tomatoes",
    "description": "Fresh organic tomatoes...",
    "merchant": { ... },
    "category": { ... },
    "price": 45.00,
    "stock": 50,
    "images": [...],
    "preparationOptions": [
      { "type": "whole", "additionalPrice": 0 },
      { "type": "chopped", "additionalPrice": 5 }
    ],
    "averageRating": 4.3,
    "totalReviews": 28,
    "relatedProducts": [...],
    "isWishlisted": false
  }
}
```

### Search Products
```http
GET /api/products/search?q=tomato&filters=organic,in_stock
```

---

## 4. CART

### Get Cart
```http
GET /api/cart
Authorization: Bearer <token>
```

**Success Response:**
```json
{
  "success": true,
  "data": {
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
    "finalTotal": 100.00,
    "itemCount": 2
  }
}
```

### Add to Cart
```http
POST /api/cart/add
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "productId": "prod123",
  "quantity": 2,
  "preparation": "whole"
}
```

### Update Cart Item
```http
PUT /api/cart/update/:productId
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "quantity": 3,
  "preparation": "chopped"
}
```

### Remove from Cart
```http
DELETE /api/cart/remove/:productId
Authorization: Bearer <token>
```

### Add Recipe to Cart
```http
POST /api/cart/recipe-to-cart
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "recipeId": "recipe123",
  "servings": 4,
  "ingredients": ["ing1", "ing2"]  // Optional: specific ingredients
}
```

---

## 5. ORDERS

### Create Order
```http
POST /api/orders
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "deliveryAddress": "addr123",
  "deliveryType": "home-delivery",
  "deliveryTimeSlot": {
    "date": "2024-01-16",
    "startTime": "10:00",
    "endTime": "12:00"
  },
  "paymentMethod": "online",
  "specialRequests": "Please ring doorbell twice",
  "useWallet": true,
  "walletAmount": 50.00
}
```

**Success Response:**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "orderId": "GB1705312800123",
    "_id": "order123",
    "items": [...],
    "itemsTotal": 90.00,
    "deliveryCharges": 30.00,
    "discount": 20.00,
    "totalAmount": 100.00,
    "paymentStatus": "pending",
    "status": "pending",
    "estimatedDeliveryTime": "2024-01-16T11:30:00Z",
    "paymentDetails": {
      "gateway": "stripe",
      "clientSecret": "pi_3O...secret_..."
    }
  }
}
```

### Get My Orders
```http
GET /api/orders/my-orders?status=active&page=1&limit=10
Authorization: Bearer <token>
```

**Query Parameters:**
- `status`: `active` (pending, confirmed, ready, out-for-delivery), `completed`, `cancelled`, `all`
- `page`: Page number
- `limit`: Items per page

**Success Response:**
```json
{
  "success": true,
  "count": 5,
  "total": 12,
  "data": [
    {
      "_id": "order123",
      "orderId": "GB1705312800123",
      "items": [
        {
          "product": { "name": "Organic Tomatoes", "primaryImage": "..." },
          "name": "Organic Tomatoes",
          "price": 45.00,
          "quantity": 2,
          "subtotal": 90.00
        }
      ],
      "totalAmount": 100.00,
      "status": "confirmed",
      "paymentStatus": "completed",
      "deliveryType": "home-delivery",
      "deliveryAddress": { ... },
      "merchant": { "businessName": "Green Farms" },
      "orderedAt": "2024-01-15T10:30:00Z",
      "estimatedDeliveryTime": "2024-01-16T11:30:00Z",
      "canCancel": true,
      "canReturn": false
    }
  ]
}
```

### Get Order by ID
```http
GET /api/orders/:id
Authorization: Bearer <token>
```

### Cancel Order
```http
PATCH /api/orders/:id/cancel
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "reason": "Changed my mind"
}
```

### Track Order
```http
GET /api/orders/:id/track
Authorization: Bearer <token>
```

**Success Response:**
```json
{
  "success": true,
  "data": {
    "orderId": "GB1705312800123",
    "status": "out-for-delivery",
    "statusHistory": [
      { "status": "pending", "timestamp": "2024-01-15T10:30:00Z", "note": "Order placed" },
      { "status": "confirmed", "timestamp": "2024-01-15T10:32:00Z", "note": "Merchant confirmed" },
      { "status": "ready", "timestamp": "2024-01-15T11:00:00Z", "note": "Ready for pickup" },
      { "status": "out-for-delivery", "timestamp": "2024-01-15T11:30:00Z", "note": "Agent assigned" }
    ],
    "deliveryPersonnel": {
      "name": "Rahul Kumar",
      "phone": "9876543210",
      "currentLocation": {
        "lat": 19.0760,
        "lng": 72.8777,
        "updatedAt": "2024-01-15T11:45:00Z"
      }
    },
    "estimatedDeliveryTime": "2024-01-15T12:00:00Z"
  }
}
```

---

## 6. PAYMENTS

### Create Payment Order
```http
POST /api/payment/create-order
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "orderId": "order123",
  "paymentMethod": "card"
}
```

**Success Response (Stripe):**
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

### Verify Payment
```http
POST /api/payment/verify
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body (Stripe):**
```json
{
  "orderId": "order123",
  "paymentIntentId": "pi_3O...",
  "status": "succeeded"
}
```

### Get Payment Methods
```http
GET /api/payment/methods
Authorization: Bearer <token>
```

**Success Response:**
```json
{
  "success": true,
  "data": {
    "methods": [
      { "id": "card", "name": "Credit/Debit Card", "enabled": true },
      { "id": "upi", "name": "UPI", "enabled": true },
      { "id": "netbanking", "name": "Net Banking", "enabled": true },
      { "id": "wallet", "name": "Wallet", "enabled": true },
      { "id": "cod", "name": "Cash on Delivery", "enabled": true }
    ]
  }
}
```

---

## 7. MERCHANT

### Get Merchant Dashboard Stats
```http
GET /api/merchants/dashboard-stats
Authorization: Bearer <token>
```

**Success Response:**
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

### Create Product (Merchant)
```http
POST /api/products
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Data:**
- `name`: Product name
- `description`: Product description
- `category`: Category ID
- `price`: Price
- `comparePrice`: Original price (optional)
- `unit`: kg, g, piece, dozen, bundle, liter
- `stock`: Stock quantity
- `lowStockThreshold`: Alert threshold (default: 10)
- `images`: Image files (multipart)
- `tags`: JSON array ["organic", "farm-fresh"]
- `nutritionalInfo`: JSON object
- `preparationOptions`: JSON array
- `isSeasonal`: boolean
- `availableMonths`: JSON array [1,2,3]

---

## 8. WISHLIST

### Get Wishlist
```http
GET /api/wishlist
Authorization: Bearer <token>
```

### Add to Wishlist
```http
POST /api/wishlist/add
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "productId": "prod123"
}
```

### Move to Cart
```http
POST /api/wishlist/move-to-cart/:productId
Authorization: Bearer <token>
```

---

## 9. WALLET

### Get Wallet
```http
GET /api/wallet
Authorization: Bearer <token>
```

**Success Response:**
```json
{
  "success": true,
  "data": {
    "balance": 1250.50,
    "currency": "INR",
    "isLocked": false,
    "totalCredited": 5000.00,
    "totalDebited": 3749.50
  }
}
```

### Add Money
```http
POST /api/wallet/add-money
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 500.00,
  "paymentMethod": "card"
}
```

### Get Transactions
```http
GET /api/wallet/transactions?page=1&limit=20
Authorization: Bearer <token>
```

**Success Response:**
```json
{
  "success": true,
  "count": 20,
  "total": 45,
  "data": [
    {
      "_id": "trans123",
      "type": "credit",
      "amount": 500.00,
      "balance": 1250.50,
      "description": "Added money via card",
      "source": "topup",
      "createdAt": "2024-01-15T10:30:00Z"
    },
    {
      "_id": "trans124",
      "type": "debit",
      "amount": 100.00,
      "balance": 750.50,
      "description": "Payment for order GB1705312800123",
      "source": "order",
      "orderId": "order123",
      "createdAt": "2024-01-14T15:20:00Z"
    }
  ]
}
```

---

## 10. NOTIFICATIONS

### Get Notifications
```http
GET /api/notifications?page=1&limit=20
Authorization: Bearer <token>
```

**Success Response:**
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

### Mark as Read
```http
PATCH /api/notifications/:id/read
Authorization: Bearer <token>
```

### Get Unread Count
```http
GET /api/notifications/unread-count
Authorization: Bearer <token>
```

---

## Error Response Format

All errors follow this format:

```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "VALIDATION_ERROR",
    "details": [
      { "field": "email", "message": "Please enter a valid email" }
    ]
  }
}
```

### Common Error Codes
| Code | HTTP Status | Description |
|------|-------------|-------------|
| BAD_REQUEST | 400 | Invalid request format |
| UNAUTHORIZED | 401 | Not authenticated |
| FORBIDDEN | 403 | No permission |
| NOT_FOUND | 404 | Resource not found |
| VALIDATION_ERROR | 422 | Validation failed |
| RATE_LIMIT | 429 | Too many requests |
| SERVER_ERROR | 500 | Internal server error |

---

## Pagination Format

List endpoints support pagination with these query params:
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)

Response includes:
```json
{
  "count": 20,      // Items in current page
  "total": 150,     // Total items
  "page": 1,        // Current page
  "pages": 8,       // Total pages
  "hasNextPage": true,
  "hasPrevPage": false
}
```

---

## WebSocket Events (Socket.IO)

Connection: `wss://api.greenbasket.com`

### Order Events
| Event | Direction | Data |
|-------|-----------|------|
| `order:status_update` | Receive | `{ orderId, status, timestamp }` |
| `order:location_update` | Receive | `{ orderId, location: { lat, lng } }` |
| `order:new` | Receive (Merchant) | `{ order }` |

### Agent Events
| Event | Direction | Data |
|-------|-----------|------|
| `agent:location` | Send | `{ lat, lng, agentId }` |
| `agent:assigned` | Receive | `{ assignment }` |

### Notification Events
| Event | Direction | Data |
|-------|-----------|------|
| `notification:new` | Receive | `{ notification }` |

---

## Rate Limiting

API endpoints are rate-limited:
- General: 100 requests per minute per IP
- Auth: 5 requests per minute per IP
- Sensitive: 10 requests per minute per user

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705312800
```
