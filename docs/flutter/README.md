# 🥬 GreenBasket Flutter Documentation

Complete documentation package for building the GreenBasket Flutter frontend.

## 📚 Documentation Files

| File | Lines | Size | Description |
|------|-------|------|-------------|
| **[README.md](./README.md)** | 257 | 6.7 KB | This file - Overview and navigation |
| **[SITE_MAP.md](./SITE_MAP.md)** | 377 | 35 KB | Complete app navigation structure with ASCII diagrams |
| **[ROUTE_MAP.md](./ROUTE_MAP.md)** | 599 | 19 KB | All 221 API endpoints organized by module |
| **[API_DOCUMENTATION.md](./API_DOCUMENTATION.md)** | 983 | 19 KB | Detailed API specs with request/response examples |
| **[COMPLETE_API_REFERENCE.md](./COMPLETE_API_REFERENCE.md)** | 2,790 | 49 KB | **Comprehensive API reference** - Every endpoint fully documented |
| **[FLUTTER_IMPLEMENTATION_GUIDE.md](./FLUTTER_IMPLEMENTATION_GUIDE.md)** | 1,872 | 49 KB | Complete Flutter implementation guide with code examples |
| **[MODELS_REFERENCE.md](./MODELS_REFERENCE.md)** | 1,293 | 32 KB | All data models for Dart/Flutter |

**Total: 8,171 lines | 210 KB of documentation**

---

## 🎯 Quick Navigation

### For Understanding the App Structure
👉 **[SITE_MAP.md](./SITE_MAP.md)** - Screen hierarchy, navigation flows, user journeys

### For API Integration
👉 **[COMPLETE_API_REFERENCE.md](./COMPLETE_API_REFERENCE.md)** - Every endpoint with full details

### For Flutter Development
👉 **[FLUTTER_IMPLEMENTATION_GUIDE.md](./FLUTTER_IMPLEMENTATION_GUIDE.md)** - Code examples, architecture, patterns

### For Data Models
👉 **[MODELS_REFERENCE.md](./MODELS_REFERENCE.md)** - All Dart models with JSON serialization

---

## 🏗️ Backend Overview

**GreenBasket** is a comprehensive grocery/farm-fresh marketplace backend with:

- **221+ API Endpoints** across 35 route files
- **21 Feature Modules**
- **4 User Roles**: Customer, Merchant, Admin, Delivery Agent
- **Payment Integration**: Stripe, PhonePe, COD
- **Real-time**: Socket.IO for live tracking
- **Push Notifications**: Firebase Cloud Messaging

---

## 📁 Backend Structure Analyzed

```
backend/
├── server.js                    # Main server (476 lines)
├── src/
│   ├── routes/                  # 35 route files
│   │   ├── authRoutes.js
│   │   ├── userRoutes.js
│   │   ├── productRoutes.js
│   │   ├── cartRoutes.js
│   │   ├── orderRoutes.js
│   │   ├── paymentRoutes.js
│   │   ├── merchantRoutes.js
│   │   ├── adminRoutes.js
│   │   ├── adminAgentRoutes.js
│   │   ├── agentRoutes.js
│   │   ├── wishlistRoutes.js
│   │   ├── walletRoutes.js
│   │   ├── loyaltyRoutes.js
│   │   ├── referralRoutes.js
│   │   ├── offerRoutes.js
│   │   ├── subscriptionRoutes.js
│   │   ├── notificationRoutes.js
│   │   ├── reviewRoutes.js
│   │   ├── categoryRoutes.js
│   │   ├── recipeRoutes.js
│   │   ├── deliveryZoneRoutes.js
│   │   ├── membershipRoutes.js
│   │   ├── preBookingRoutes.js
│   │   ├── documentRoutes.js
│   │   ├── disputeRoutes.js
│   │   ├── financialRoutes.js
│   │   ├── bulkOperationsRoutes.js
│   │   ├── searchRoutes.js
│   │   ├── returnRoutes.js
│   │   ├── giftCardRoutes.js
│   │   ├── uploadRoutes.js
│   │   └── paymentWebhookRoute.js
│   ├── controllers/             # 35 controller files
│   │   ├── authController.js    # 561 lines
│   │   ├── userController.js    # 419 lines
│   │   ├── cartController.js    # 289 lines
│   │   ├── orderController.js   # 709 lines
│   │   └── ... (31 more)
│   ├── models/                  # 28 model files
│   │   ├── User.js              # 239 lines
│   │   ├── Product.js           # 200 lines
│   │   ├── Order.js             # 284 lines
│   │   ├── Cart.js              # 79 lines
│   │   ├── Merchant.js          # 370 lines
│   │   └── ... (23 more)
│   ├── middlewares/
│   │   ├── authMiddleware.js    # 163 lines
│   │   ├── agentAuthMiddleware.js
│   │   ├── uploadMiddleware.js
│   │   └── ...
│   └── services/
│       ├── paymentService.js
│       ├── notificationService.js
│       ├── emailService.js
│       └── ...
```

---

## 🔐 Authentication Flow

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  Splash │───▶│  Login  │───▶│  Home   │───▶│ Features│
└─────────┘    └─────────┘    └─────────┘    └─────────┘
                    │
                    ▼
               ┌─────────┐
               │  Signup │
               └─────────┘
```

### Supported Login Methods
1. **Unified Login** - Single endpoint for all roles
2. **Role-specific Login** - Separate endpoints (legacy)
3. **Social Login** - Google, Facebook (via User model)

### Token Format
```
Authorization: Bearer <JWT_TOKEN>
```

---

## 🚀 Quick Start for Flutter Development

### 1. Understand the Backend
Read in this order:
1. **[SITE_MAP.md](./SITE_MAP.md)** - App structure
2. **[ROUTE_MAP.md](./ROUTE_MAP.md)** - API overview
3. **[COMPLETE_API_REFERENCE.md](./COMPLETE_API_REFERENCE.md)** - API details

### 2. Project Setup
```bash
flutter create greenbasket_app
cd greenbasket_app
```

Add dependencies from **[FLUTTER_IMPLEMENTATION_GUIDE.md](./FLUTTER_IMPLEMENTATION_GUIDE.md#1-project-setup)**

### 3. Implement Architecture
Follow the [Clean Architecture with GetX](./FLUTTER_IMPLEMENTATION_GUIDE.md#2-architecture) pattern.

### 4. Core Implementation Order
```
1. API Service Layer    → Dio client with interceptors
2. Models               → JSON serializable models
3. Authentication       → Login/signup flow
4. Home & Products      → Browse and search
5. Cart                 → Add/update/remove items
6. Checkout             → Address + Payment
7. Orders               → List and tracking
8. Profile              → User management
```

---

## 📦 Feature Modules

### Customer App Features
| Feature | APIs | Status |
|---------|------|--------|
| Authentication | 11 | ✅ |
| Home/Dashboard | 5 | ✅ |
| Product Browse | 8 | ✅ |
| Search/Filter | 3 | ✅ |
| Cart Management | 6 | ✅ |
| Checkout/Payment | 8 | ✅ |
| Order Tracking | 9 | ✅ |
| Wallet | 5 | ✅ |
| Wishlist | 5 | ✅ |
| Reviews | 7 | ✅ |
| Notifications | 8 | ✅ |
| Loyalty Points | 4 | ✅ |
| Referral System | 5 | ✅ |
| Gift Cards | 9 | ✅ |
| Membership | 9 | ✅ |
| Pre-booking | 9 | ✅ |
| Returns | 6 | ✅ |
| Disputes | 8 | ✅ |

### Merchant App Features
| Feature | APIs | Status |
|---------|------|--------|
| Dashboard | 2 | ✅ |
| Product Management | 5 | ✅ |
| Order Management | 2 | ✅ |
| Analytics | 6 | ✅ |
| Delivery Zones | 5 | ✅ |
| Documents | 4 | ✅ |
| Financial | 4 | ✅ |
| Bulk Operations | 4 | ✅ |

### Admin App Features
| Feature | APIs | Status |
|---------|------|--------|
| Dashboard/Stats | 1 | ✅ |
| User Management | 2 | ✅ |
| Merchant Verification | 3 | ✅ |
| Order Management | 3 | ✅ |
| Agent Management | 7 | ✅ |
| Financial Control | 7 | ✅ |
| Content Management | 5 | ✅ |
| Dispute Resolution | 3 | ✅ |

### Delivery Agent App Features
| Feature | APIs | Status |
|---------|------|--------|
| Authentication | 2 | ✅ |
| Profile Management | 3 | ✅ |
| Job Assignment | 5 | ✅ |
| Earnings | 1 | ✅ |

---

## 🌐 API Base URLs

| Environment | URL |
|-------------|-----|
| Development | `http://localhost:6000/api` |
| Staging | `https://staging-api.greenbasket.com/api` |
| Production | `https://api.greenbasket.com/api` |

---

## 🧪 Testing

### Postman Collection
Location: `backend/GreenBasket.postman_collection.json`

### Test Credentials
```
Customer: customer@test.com / password123
Merchant: merchant@test.com / password123
Admin: admin@test.com / password123
```

---

## 🔗 Deep Linking

| URL Pattern | Screen |
|-------------|--------|
| `greenbasket://product/:id` | Product Detail |
| `greenbasket://order/:id` | Order Detail |
| `greenbasket://category/:id` | Category Products |
| `greenbasket://referral/:code` | Signup with Referral |

---

## 📱 Push Notifications

### Firebase Events
| Event | Description |
|-------|-------------|
| `order:status_update` | Order status changed |
| `order:location_update` | Delivery location updated |
| `notification:new` | New notification received |

---

## 🛡️ Security

### Authentication
- JWT tokens with 24h expiry
- Refresh token support
- Role-based access control
- FCM token management

### Rate Limiting
| Endpoint Type | Limit |
|---------------|-------|
| General | 100 req/min |
| Auth | 5 req/min |
| Payment | 10 req/min |

---

## 🎨 Design System

### Colors
```dart
class AppColors {
  static const primary = Color(0xFF2E7D32);      // Green
  static const primaryDark = Color(0xFF1B5E20);  // Dark Green
  static const accent = Color(0xFFFF6F00);       // Orange
  static const background = Color(0xFFF5F5F5);   // Light Grey
  static const error = Color(0xFFD32F2F);        // Red
}
```

---

## 📊 Key Models

### User
```dart
class User {
  String id;
  String name;
  String email;
  String phone;
  bool isPremium;
  int loyaltyPoints;
  String loyaltyTier; // bronze, silver, gold, platinum
  double walletBalance;
  Referral referral;
  NotificationPreferences notificationPreferences;
}
```

### Product
```dart
class Product {
  String id;
  String name;
  String description;
  double price;
  double comparePrice;
  int stock;
  List<String> images;
  String primaryImage;
  double averageRating;
  int totalReviews;
  bool isWishlisted;
  bool isPremiumExclusive;
  bool isPreBookable;
}
```

### Order
```dart
class Order {
  String id;
  String orderId; // GB1705312800123
  List<OrderItem> items;
  double totalAmount;
  String status; // pending, confirmed, ready, out-for-delivery, delivered, cancelled
  String paymentStatus;
  DateTime orderedAt;
  DateTime? estimatedDeliveryTime;
}
```

---

## 🚀 Deployment Checklist

- [ ] Configure release build signing
- [ ] Set up Firebase project
- [ ] Configure Google Maps API key
- [ ] Set up payment gateway credentials (Stripe/PhonePe)
- [ ] Configure push notifications (FCM)
- [ ] Set up deep linking
- [ ] Configure environment variables
- [ ] Run integration tests
- [ ] Performance testing
- [ ] Security audit

---

## 📞 Support

For backend API issues:
1. Check backend logs
2. Verify API response errors
3. Check token expiration
4. Review rate limiting headers

---

## 📝 License

This documentation is provided for development purposes only.

---

## 🙏 Credits

Documentation generated from comprehensive backend analysis:
- **35 Route files**
- **35 Controller files**
- **28 Model files**
- **Multiple middleware and service files**

**Built with ❤️ for the GreenBasket Platform**
