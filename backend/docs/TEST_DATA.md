# GreenBasket Backend - Comprehensive Test Data & API Guide

This document provides structured test data for all **221 API endpoints** in the GreenBasket ecosystem. Use these values in Postman or during manual verification.

---

## 🔐 1. Authentication & Onboarding

### User Signup (`POST /api/auth/user/signup`)
```json
{
    "name": "Test User",
    "email": "user@gmail.com",
    "phone": "9876543210",
    "password": "password123"
}
```

### Merchant Signup (`POST /api/auth/merchant/signup`)
```json
{
    "name": "Organic Farm",
    "email": "farm@example.com",
    "phone": "9988776655",
    "password": "password123",
    "businessName": "Green Valley Farm",
    "merchantType": "farmer"
}
```

### Delivery Agent Register (`POST /api/agents/register`)
```json
{
    "name": "Swift Delivery",
    "email": "driver@example.com",
    "phone": "8877665544",
    "password": "password123",
    "vehicleType": "bike",
    "vehicleNumber": "KA-01-GB-123"
}
```

---

## 🛒 2. Shopping & Products

### Create Product (`POST /api/products` - Merchant)
```json
{
    "name": "Premium Organic Spinach",
    "description": "Garden-fresh pesticide-free spinach.",
    "price": 45.0,
    "stock": 50,
    "unit": "bunch",
    "category": "{{category_id}}",
    "tags": ["organic", "leafy", "iron-rich"]
}
```

### Add to Cart (`POST /api/cart/add`)
```json
{
    "productId": "{{product_id}}",
    "quantity": 3,
    "preparation": "chopped"
}
```

---

## 💳 3. Payments & Wallet

### Add Money to Wallet (`POST /api/wallet/add-money`)
```json
{
    "amount": 2500.0,
    "method": "stripe"
}
```

### Create Order (`POST /api/orders`)
```json
{
    "addressId": "{{address_id}}",
    "paymentMethod": "wallet",
    "deliverySlot": {
        "date": "2026-02-25",
        "startTime": "08:00",
        "endTime": "10:00"
    }
}
```

---

## 🚚 4. Delivery Agent Operations

### Update Status (`PUT /api/agents/me/status`)
```json
{
    "status": "online"
}
```

### Update Location (`POST /api/agents/me/location`)
```json
{
    "latitude": 12.9716,
    "longitude": 77.5946
}
```

### Update Assignment Status (`PUT /api/agents/assignments/:id/status`)
```json
{
    "status": "delivered",
    "otp": "123456" 
}
```

---

## 🎖️ 5. Loyalty & Membership

### Subscribe to Premium (`POST /api/membership/subscribe`)
```json
{
    "planId": "gold_yearly",
    "paymentMethod": "stripe"
}
```

### Redeem Loyalty Points (`POST /api/loyalty/redeem`)
```json
{
    "points": 500
}
```

---

## 🔧 6. Support & Disputes

### Raise Dispute (`POST /api/disputes`)
```json
{
    "orderId": "{{order_id}}",
    "category": "not_delivered",
    "description": "Item shows delivered but not received.",
    "images": ["url_to_uploaded_proof"]
}
```

### Request Return (`POST /api/returns`)
```json
{
    "orderId": "{{order_id}}",
    "items": [
        {
            "productId": "{{product_id}}",
            "quantity": 1,
            "reason": "Damaged on arrival"
        }
    ]
}
```

---

## 📊 7. Admin Operations

### Verify Merchant (`PATCH /api/admin/merchants/:id/verify`)
```json
{
    "verificationStatus": "verified",
    "note": "Documents verified successfully."
}
```

### Verify Delivery Agent (`PATCH /api/admin/agents/:id/verify`)
```json
{
    "isVerified": true
}
```

---

## 📝 8. Environment Variables for Postman
| Variable | Suggested Initial Value |
|---|---|
| `base_url` | `http://localhost:6000` |
| `token` | *[Paste JWT after login]* |
| `product_id` | *[Get from GET /api/products]* |
| `category_id` | *[Get from GET /api/categories]* |

---

### **💡 Pro-Tip for Testing**
1. **Login First**: Always start by logging in (`POST /api/auth/user/login`) and copying the `token` into your Postman environment.
2. **Context Matters**: Some APIs (like `updateStock`) only work for **Merchants**, while others (like `manualAssign`) only work for **Admins**.
3. **FCM Tokens**: Use a dummy string for `fcm-token` testing unless you have a real Firebase device ID.
