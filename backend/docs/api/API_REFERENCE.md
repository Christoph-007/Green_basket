# Green Basket Backend - Complete API Reference

## 🚀 Base URL
```
http://localhost:5001/api
```

---

## 📑 Table of Contents

1. [Authentication APIs](#authentication-apis)
2. [User APIs](#user-apis)
3. [Merchant APIs](#merchant-apis)
4. [Admin APIs](#admin-apis)
5. [Product APIs](#product-apis)
6. [Category APIs](#category-apis)
7. [Cart APIs](#cart-apis)
8. [Order APIs](#order-apis)
9. [Recipe APIs](#recipe-apis)
10. [Review APIs](#review-apis)
11. [Subscription APIs](#subscription-apis)

---

## 🔐 Authentication APIs

### 1. User Signup
**POST** `/api/auth/user/signup`

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "9876543210"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully. Please verify your email.",
  "data": {
    "user": { ... },
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}
```

---

### 2. User Login
**POST** `/api/auth/user/login`

**Request Body:**
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
  "data": {
    "user": { ... },
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}
```

**Test Credentials:**
- Email: `user@example.com`
- Password: `password123`

---

### 3. Merchant Signup
**POST** `/api/auth/merchant/signup`

**Request Body:**
```json
{
  "name": "Farmer Joe",
  "email": "farmer@example.com",
  "password": "password123",
  "phone": "9123456789",
  "businessName": "Green Valley Farms",
  "merchantType": "organic-farmer"
}
```

---

### 4. Merchant Login
**POST** `/api/auth/merchant/login`

**Request Body:**
```json
{
  "email": "merchant@example.com",
  "password": "password123"
}
```

**Test Credentials:**
- Email: `merchant@example.com`
- Password: `password123`

---

### 5. Admin Login
**POST** `/api/auth/admin/login`

**Request Body:**
```json
{
  "email": "admin@greenbasket.com",
  "password": "admin123"
}
```

**Test Credentials:**
- Email: `admin@greenbasket.com`
- Password: `admin123`

---

### 6. Verify Email
**POST** `/api/auth/user/verify-email`

**Request Body:**
```json
{
  "token": "verification_token_from_email"
}
```

---

### 7. Forgot Password
**POST** `/api/auth/user/forgot-password`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

---

### 8. Reset Password
**POST** `/api/auth/user/reset-password`

**Request Body:**
```json
{
  "token": "reset_token_from_email",
  "newPassword": "newPassword123"
}
```

---

### 9. Refresh Token
**POST** `/api/auth/refresh-token`

**Request Body:**
```json
{
  "refreshToken": "eyJhbGc..."
}
```

---

### 10. Logout
**POST** `/api/auth/logout`

**Headers:**
```
Authorization: Bearer <access_token>
```

---

## 👤 User APIs

### 1. Get User Profile
**GET** `/api/users/profile`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "...",
    "name": "John Doe",
    "email": "user@example.com",
    "phone": "9876543210",
    "loyaltyPoints": 250,
    "loyaltyTier": "silver"
  }
}
```

---

### 2. Update User Profile
**PUT** `/api/users/profile`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Request Body:**
```json
{
  "name": "John Updated",
  "phone": "9876543211",
  "dietaryPreferences": ["vegetarian", "organic-only"]
}
```

---

### 3. Get User Addresses
**GET** `/api/users/addresses`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

---

### 4. Add Address
**POST** `/api/users/addresses`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Request Body:**
```json
{
  "label": "home",
  "name": "John Doe",
  "phone": "9876543210",
  "addressLine1": "123 Main Street",
  "city": "Bangalore",
  "state": "Karnataka",
  "pincode": "560001",
  "isDefault": true
}
```

---

### 5. Update Address
**PUT** `/api/users/addresses/:addressId`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

---

### 6. Delete Address
**DELETE** `/api/users/addresses/:addressId`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

---

## 🏪 Merchant APIs

### 1. Get Merchant Profile
**GET** `/api/merchants/profile`

**Headers:**
```
Authorization: Bearer <merchant_access_token>
```

---

### 2. Update Merchant Profile
**PUT** `/api/merchants/profile`

**Headers:**
```
Authorization: Bearer <merchant_access_token>
```

**Request Body:**
```json
{
  "businessName": "Updated Farm Name",
  "businessDescription": "Fresh organic produce",
  "deliveryRadius": 20,
  "minimumOrderValue": 250
}
```

---

### 3. Toggle Store Status
**PATCH** `/api/merchants/toggle-store`

**Headers:**
```
Authorization: Bearer <merchant_access_token>
```

**Response:**
```json
{
  "success": true,
  "message": "Store is now open/closed",
  "data": {
    "isStoreOpen": true
  }
}
```

---

### 4. Get Dashboard Stats
**GET** `/api/merchants/dashboard-stats`

**Headers:**
```
Authorization: Bearer <merchant_access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalRevenue": 15000,
    "totalOrders": 45,
    "pendingOrders": 5,
    "lowStockProducts": 3
  }
}
```

---

## 👨‍💼 Admin APIs

### 1. Get Pending Merchants
**GET** `/api/admin/merchants/pending`

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

---

### 2. Verify Merchant
**PUT** `/api/admin/merchants/verify/:merchantId`

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

**Request Body:**
```json
{
  "status": "approved",
  "rejectionReason": ""
}
```

---

### 3. Get All Users
**GET** `/api/admin/users`

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 10)
- `search` (optional)

---

### 4. Block/Unblock User
**PATCH** `/api/admin/users/:userId/block`

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

---

### 5. Get Platform Stats
**GET** `/api/admin/stats`

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalUsers": 150,
    "totalMerchants": 25,
    "totalOrders": 500,
    "totalRevenue": 250000
  }
}
```

---

## 🛍️ Product APIs

### 1. Get All Products
**GET** `/api/products`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 12)
- `category` (optional)
- `merchant` (optional)
- `search` (optional)
- `minPrice` (optional)
- `maxPrice` (optional)
- `tags` (optional, comma-separated)

**Example:**
```
GET /api/products?page=1&limit=10&category=vegetables&search=tomato
```

**Response:**
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "_id": "...",
        "name": "Organic Tomatoes",
        "price": 60,
        "unit": "kg",
        "stock": 100,
        "merchant": {
          "businessName": "Green Valley Farms"
        },
        "category": {
          "name": "Vegetables"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 12,
      "pages": 2
    }
  }
}
```

---

### 2. Get Product by ID
**GET** `/api/products/:id`

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "...",
    "name": "Organic Tomatoes",
    "description": "Fresh, juicy tomatoes...",
    "price": 60,
    "stock": 100,
    "images": [...],
    "nutritionalInfo": {...}
  }
}
```

---

### 3. Create Product (Merchant Only)
**POST** `/api/products`

**Headers:**
```
Authorization: Bearer <merchant_access_token>
```

**Request Body:**
```json
{
  "name": "Fresh Cucumber",
  "description": "Organic cucumbers",
  "category": "category_id",
  "price": 40,
  "unit": "kg",
  "stock": 100,
  "primaryImage": "image_url",
  "tags": ["organic", "farm-fresh"]
}
```

---

### 4. Update Product (Merchant Only)
**PUT** `/api/products/:id`

**Headers:**
```
Authorization: Bearer <merchant_access_token>
```

---

### 5. Delete Product (Merchant Only)
**DELETE** `/api/products/:id`

**Headers:**
```
Authorization: Bearer <merchant_access_token>
```

---

### 6. Update Stock (Merchant Only)
**PATCH** `/api/products/:id/stock`

**Headers:**
```
Authorization: Bearer <merchant_access_token>
```

**Request Body:**
```json
{
  "stock": 150
}
```

---

### 7. Search Products
**GET** `/api/products/search`

**Query Parameters:**
- `q` (search query)

---

## 📂 Category APIs

### 1. Get All Categories
**GET** `/api/categories`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "...",
      "name": "Vegetables",
      "description": "Fresh organic vegetables",
      "icon": "carrot",
      "image": "..."
    },
    {
      "_id": "...",
      "name": "Fruits",
      "description": "Seasonal fresh fruits",
      "icon": "apple",
      "image": "..."
    }
  ]
}
```

---

### 2. Get Category by ID
**GET** `/api/categories/:id`

---

### 3. Create Category (Admin Only)
**POST** `/api/categories`

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

**Request Body:**
```json
{
  "name": "Beverages",
  "description": "Fresh juices and drinks",
  "icon": "drink",
  "image": "image_url"
}
```

---

### 4. Update Category (Admin Only)
**PUT** `/api/categories/:id`

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

---

### 5. Delete Category (Admin Only)
**DELETE** `/api/categories/:id`

**Headers:**
```
Authorization: Bearer <admin_access_token>
```

---

## 🛒 Cart APIs

### 1. Get Cart
**GET** `/api/cart`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "product": {...},
        "quantity": 2,
        "price": 60,
        "subtotal": 120
      }
    ],
    "total": 120
  }
}
```

---

### 2. Add to Cart
**POST** `/api/cart/add`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Request Body:**
```json
{
  "productId": "product_id",
  "quantity": 2,
  "preparationType": "whole"
}
```

---

### 3. Update Cart Item
**PUT** `/api/cart/update/:productId`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Request Body:**
```json
{
  "quantity": 3
}
```

---

### 4. Remove from Cart
**DELETE** `/api/cart/remove/:productId`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

---

### 5. Clear Cart
**DELETE** `/api/cart/clear`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

---

### 6. Add Recipe to Cart (Special Feature)
**POST** `/api/cart/recipe-to-cart`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Request Body:**
```json
{
  "recipeId": "recipe_id",
  "servings": 4
}
```

**Response:**
```json
{
  "success": true,
  "message": "Recipe ingredients added to cart",
  "data": {
    "itemsAdded": 4,
    "cart": {...}
  }
}
```

---

## 📦 Order APIs

### 1. Create Order
**POST** `/api/orders`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Request Body:**
```json
{
  "deliveryAddress": "address_id",
  "deliveryType": "standard",
  "deliveryTimeSlot": "morning",
  "paymentMethod": "cod",
  "specialRequests": "Please ring the bell"
}
```

---

### 2. Get My Orders
**GET** `/api/orders/my-orders`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 10)
- `status` (optional: pending, confirmed, delivered, cancelled)

---

### 3. Get Order by ID
**GET** `/api/orders/:id`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

---

### 4. Cancel Order
**PATCH** `/api/orders/:id/cancel`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Request Body:**
```json
{
  "reason": "Changed my mind"
}
```

---

### 5. Update Order Status (Merchant Only)
**PATCH** `/api/orders/:id/status`

**Headers:**
```
Authorization: Bearer <merchant_access_token>
```

**Request Body:**
```json
{
  "status": "confirmed",
  "note": "Order confirmed and will be delivered soon"
}
```

---

### 6. Add Review (After Delivery)
**POST** `/api/orders/:id/review`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Request Body:**
```json
{
  "productId": "product_id",
  "rating": 5,
  "comment": "Excellent quality!",
  "images": ["image_url"]
}
```

---

## 🍳 Recipe APIs

### 1. Get All Recipes
**GET** `/api/recipes`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 12)
- `cuisine` (optional)
- `category` (optional: breakfast, lunch, dinner, snack)
- `difficulty` (optional: easy, medium, hard)
- `search` (optional)

**Response:**
```json
{
  "success": true,
  "data": {
    "recipes": [
      {
        "_id": "...",
        "name": "Vegetable Curry",
        "cuisine": "south-indian",
        "category": "lunch",
        "servings": 4,
        "prepTime": 20,
        "cookTime": 30,
        "difficulty": "medium",
        "ingredients": [...]
      }
    ],
    "pagination": {...}
  }
}
```

---

### 2. Get Recipe by ID
**GET** `/api/recipes/:id`

**Response:**
```json
{
  "success": true,
  "data": {
    "name": "Vegetable Curry",
    "description": "...",
    "ingredients": [
      {
        "name": "Carrots",
        "quantity": 0.2,
        "unit": "kg",
        "product": {...}
      }
    ],
    "instructions": [
      {
        "stepNumber": 1,
        "instruction": "Heat oil in a pan..."
      }
    ],
    "nutritionalInfo": {...}
  }
}
```

---

### 3. Calculate Ingredients for Custom Servings
**POST** `/api/recipes/:id/calculate-ingredients`

**Request Body:**
```json
{
  "servings": 8
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "originalServings": 4,
    "requestedServings": 8,
    "ingredients": [
      {
        "name": "Carrots",
        "originalQuantity": 0.2,
        "calculatedQuantity": 0.4,
        "unit": "kg",
        "product": {...}
      }
    ]
  }
}
```

---

### 4. Search Recipes
**GET** `/api/recipes/search`

**Query Parameters:**
- `q` (search query)

---

## ⭐ Review APIs

### 1. Get Product Reviews
**GET** `/api/reviews/product/:productId`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 10)

---

### 2. Get Merchant Reviews
**GET** `/api/reviews/merchant/:merchantId`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 10)

---

### 3. Delete Review (Admin/Owner Only)
**DELETE** `/api/reviews/:reviewId`

**Headers:**
```
Authorization: Bearer <access_token>
```

---

## 🔄 Subscription APIs

### 1. Create Subscription
**POST** `/api/subscriptions`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Request Body:**
```json
{
  "items": [
    {
      "product": "product_id",
      "quantity": 2
    }
  ],
  "frequency": "weekly",
  "deliveryDay": "monday",
  "deliveryAddress": "address_id",
  "startDate": "2024-02-15"
}
```

---

### 2. Get My Subscriptions
**GET** `/api/subscriptions/my-subscriptions`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

---

### 3. Update Subscription Status
**PATCH** `/api/subscriptions/:id/status`

**Headers:**
```
Authorization: Bearer <user_access_token>
```

**Request Body:**
```json
{
  "status": "paused"
}
```

**Status Options:**
- `active`
- `paused`
- `cancelled`

---

## 🏥 Health Check APIs

### 1. Root Health Check
**GET** `/`

**Response:**
```json
{
  "success": true,
  "message": "Green Basket API is running",
  "version": "1.0.0",
  "timestamp": "2024-02-09T05:30:00.000Z"
}
```

---

### 2. API Health Check
**GET** `/api/health`

**Response:**
```json
{
  "success": true,
  "status": "healthy",
  "uptime": 3600,
  "timestamp": "2024-02-09T05:30:00.000Z"
}
```

---

### 3. API Documentation
**GET** `/api`

**Response:**
```json
{
  "success": true,
  "message": "Green Basket API",
  "version": "1.0.0",
  "endpoints": {
    "authentication": {...},
    "products": {...},
    "cart": {...},
    ...
  }
}
```

---

## 📊 Summary

### Total APIs: **60+**

| Category | Count | Status |
|----------|-------|--------|
| Authentication | 10 | ✅ Working |
| User | 6 | ✅ Working |
| Merchant | 4 | ✅ Working |
| Admin | 5 | ✅ Working |
| Product | 7 | ✅ Working |
| Category | 5 | ✅ Working |
| Cart | 6 | ✅ Working |
| Order | 6 | ✅ Working |
| Recipe | 4 | ✅ Working |
| Review | 3 | ✅ Working |
| Subscription | 3 | ✅ Working |
| Health | 3 | ✅ Working |

---

## 🧪 Testing the APIs

### Using cURL:

```bash
# Test user login
curl -X POST http://localhost:5001/api/auth/user/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Get all products
curl http://localhost:5001/api/products

# Get all categories
curl http://localhost:5001/api/categories

# Get all recipes
curl http://localhost:5001/api/recipes
```

### Using Postman:

1. Import the base URL: `http://localhost:5001/api`
2. Create requests for each endpoint
3. Use the test credentials provided above
4. Set Authorization header for protected routes

---

## 🔐 Authentication Flow

1. **Login** → Get `accessToken` and `refreshToken`
2. **Use accessToken** in Authorization header: `Bearer <token>`
3. **Token expires** → Use refresh token to get new access token
4. **Logout** → Invalidate tokens

---

## 📝 Notes

- All **protected routes** require `Authorization: Bearer <token>` header
- **Merchant routes** require merchant authentication
- **Admin routes** require admin authentication
- **Pagination** is available on list endpoints (page, limit)
- **Search** is available on products and recipes
- **Filtering** is available on products (category, price, tags)

---

**Last Updated:** February 9, 2024  
**API Version:** 1.0.0  
**Server:** http://localhost:5001
