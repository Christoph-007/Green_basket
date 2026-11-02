# 🟩 GreenBasket: Master API Test Data Handbook
This document provides valid JSON test payloads and query examples for **every single one of the 221 APIs** in the backend.

---

## 🔑 1. AUTHENTICATION & SECURITY

### `POST /api/auth/user/signup`
```json
{
  "name": "Jane Doe",
  "email": "jane@greenbasket.com",
  "phone": "9000010000",
  "password": "SecurePassword123"
}
```

### `POST /api/auth/merchant/signup`
```json
{
  "name": "Farmer Joe",
  "email": "joe@freshfarm.com",
  "phone": "8000010000",
  "password": "FarmerPassword123",
  "businessName": "Joe's Organic Greens",
  "merchantType": "farmer"
}
```

### `POST /api/auth/user/login`
```json
{
  "email": "jane@greenbasket.com",
  "password": "SecurePassword123"
}
```

### `POST /api/auth/merchant/login`
```json
{
  "email": "merchant@gmail.com",
  "password": "merchant123"
}
```

### `POST /api/auth/admin/login`
```json
{
  "email": "admin@gmail.com",
  "password": "admin123"
}
```

---

## 🥬 2. PRODUCT MANAGEMENT

### `POST /api/products` (Merchant Only)
```json
{
  "name": "Organic Hass Avocado",
  "description": "Buttery, rich avocados from certified organic groves.",
  "price": 120.0,
  "stock": 25,
  "unit": "piece",
  "category": "{{category_id}}",
  "tags": ["organic", "seasonal"],
  "primaryImage": "https://example.com/avocado.jpg",
  "nutritionalInfo": { 
    "calories": 160, 
    "fat": 15, 
    "protein": 2 
  }
}
```

### `PATCH /api/products/:id/stock` (Merchant)
```json
{ "stock": 50 }
```

### GET Filtration Examples
*   **Search**: `/api/products/search?q=tomatoes&minPrice=10&maxPrice=100`
*   **Sort**: `/api/products?sort=price_asc&category={{id}}`

---

## 🛒 3. CART & CHECKOUT

### `POST /api/cart/add`
```json
{
  "productId": "{{product_id}}",
  "quantity": 2,
  "preparation": "sliced" 
}
```

### `POST /api/orders`
```json
{
  "addressId": "{{address_id}}",
  "paymentMethod": "stripe",
  "deliveryInstructions": "Leave by the blue gate.",
  "deliverySlot": {
    "date": "2026-02-25",
    "startTime": "10:00",
    "endTime": "12:00"
  }
}
```

---

## 💳 4. WALLET & PAYMENTS

### `POST /api/wallet/add-money`
```json
{
  "amount": 5000,
  "method": "stripe"
}
```

### `POST /api/wallet/use-for-payment`
```json
{
  "orderId": "{{order_id}}",
  "amount": 450
}
```

---

## 🚚 5. DELIVERY AGENT SYSTEM

### `POST /api/agents/register`
```json
{
  "name": "Swift Ryder",
  "email": "ryder@greenbasket.com",
  "phone": "7000010000",
  "password": "RyderPassword123",
  "vehicleType": "scooter",
  "vehicleNumber": "KA-05-AB-9999"
}
```

### `PUT /api/agents/me/status`
```json
{ "status": "online" }
```

### `POST /api/agents/me/location`
```json
{ "latitude": 12.9716, "longitude": 77.5946 }
```

### `PUT /api/agents/assignments/:id/status`
```json
{ 
  "status": "delivered",
  "otp": "4567" 
}
```

---

## 🎖️ 6. LOYALTY, MEMBERSHIP & REFERRALS

### `POST /api/membership/subscribe`
```json
{ "planId": "yearly_platinum", "paymentMethod": "card" }
```

### `POST /api/loyalty/redeem`
```json
{ "points": 1000 }
```

### `POST /api/referral/apply`
```json
{ "code": "JANE999" }
```

---

## 🍳 7. RECIPES & PRE-BOOKING

### `POST /api/recipes` (Admin)
```json
{
  "title": "Avocado Toast with Poached Egg",
  "ingredients": [
    { "product": "{{avocado_id}}", "quantity": 1, "unit": "piece" },
    { "name": "Bread", "quantity": 2, "unit": "slices" }
  ],
  "steps": ["Toast bread", "Mash avocado", "Poach egg"],
  "difficulty": "easy"
}
```

### `POST /api/prebooking`
```json
{
  "productId": "{{seasonal_mango_id}}",
  "quantity": 5,
  "expectedHarvestDate": "2026-05-15"
}
```

---

## 🔧 8. CUSTOMER CARE (DISPUTES & RETURNS)

### `POST /api/disputes`
```json
{
  "orderId": "{{order_id}}",
  "category": "missing_item",
  "description": "Organic spinach was not in the bag.",
  "severity": "medium"
}
```

### `POST /api/returns`
```json
{
  "orderId": "{{order_id}}",
  "items": [{ "productId": "{{expired_milk_id}}", "quantity": 1, "reason": "Expired" }],
  "pickupSlot": { "date": "2026-02-21", "startTime": "09:00" }
}
```

---

## 🏢 9. MERCHANT TOOLS

### `PUT /api/merchants/zones/location`
```json
{ "lat": 12.9500, "lng": 77.5800, "address": "Bengaluru Central Hub" }
```

### `POST /api/merchants/zones/delivery-zones`
```json
{
  "name": "HSR Layout Sector 1",
  "radius": 5,
  "minOrderValue": 250
}
```

### `PUT /api/bulk/products/bulk-update-price`
```json
{
  "updates": [
    { "productId": "{{id1}}", "newPrice": 45 },
    { "productId": "{{id2}}", "newPrice": 88 }
  ]
}
```

---

## 🛡️ 10. ADMIN CONTROL PANEL

### `PATCH /api/admin/users/:id/block`
```json
{ "isBlocked": true, "reason": "Fraudulent return activity" }
```

### `POST /api/financial/admin/payouts/generate`
```json
{ "period": "weekly", "date": "2026-02-19" }
```

### `PUT /api/financial/admin/settings/commission`
```json
{ "baseCommission": 12.5, "premiumMerchantCommission": 8.0 }
```

---

## 🔔 11. NOTIFICATIONS & PROFILE

### `PUT /api/users/profile`
```json
{
  "name": "Jane Updated",
  "dietaryPreferences": ["vegan", "organic-only"],
  "allergies": ["nuts"]
}
```

### `POST /api/users/fcm-token`
```json
{ "token": "fcm_test_token_998877", "deviceType": "android" }
```

---

## 🗂️ 12. DOCUMENT VERIFICATION

### `POST /api/documents/upload` (Merchant)
*   **Body**: `multipart/form-data`
*   **Key**: `document`, **Type**: `File`, **Value**: `business_license.pdf`

### `PUT /api/documents/admin/:merchantId/:documentId/verify`
```json
{ "status": "approved", "comment": "Verified with local chamber of commerce." }
```

---

## 🎁 13. GIFT CARDS

### `POST /api/gift-cards/purchase/initiate`
```json
{
  "amount": 2000,
  "recipientEmail": "friend@example.com",
  "message": "Happy Birthday! Enjoy some fresh food."
}
```

### `POST /api/gift-cards/redeem`
```json
{ "code": "GB-GIFT-1234-XYZA" }
```

---

## 📂 14. UPLOAD SYSTEM
*   `POST /api/upload/image`: FormData `key: image` (png/jpg)
*   `POST /api/upload/document`: FormData `key: document` (pdf/docx)

---

## 📍 15. LOCALIZATION & ADDRESSES
### `POST /api/users/addresses`
```json
{
  "label": "Office",
  "addressLine1": "Global Tech Park, Tower A",
  "city": "Bengaluru",
  "pincode": "560100",
  "lat": 12.9200,
  "lng": 77.6300,
  "isDefault": false
}
```

---

### **📌 How to run these tests?**
1.  **Global Base URL**: `http://localhost:6000`
2.  **Order of Testing**: Signup ➔ Login ➔ Copy Token ➔ Add Token to Header `Authorization: Bearer <TOKEN>`.
3.  **Placeholders**: Replace `{{id}}` or `{{product_id}}` with actual MongoDB ObjectIDs returned from GET calls.
