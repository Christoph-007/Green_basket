# 🚀 GreenBasket Backend - Quick Reference

## 📊 **At a Glance**

**Total APIs:** 204  
**Total Features:** 20  
**Status:** ✅ Production Ready  

---

## 🎯 **All 20 Features**

| # | Feature | APIs |
|---|---------|------|
| 1-10 | Core (Auth, Products, Orders, etc.) | 117 |
| 11 | Premium Membership | 6 |
| 12 | Pre-Booking System | 6 |
| 13 | Document Verification | 6 |
| 14 | Dispute Management | 8 |
| 15 | Financial & Payouts | 10 |
| 16 | Bulk Operations | 4 |
| 17 | Advanced Search | 3 |
| 18 | Order Tracking | 2 |
| 19 | Returns & Exchange | 6 |
| 20 | Gift Cards & Vouchers | 7 |

---

## 🔑 **Latest Features (14-20) - Quick Access**

### Feature 14: Disputes
```
POST   /api/disputes
GET    /api/disputes/my-disputes
POST   /api/disputes/:id/message
PUT    /api/disputes/admin/:id/resolve
```

### Feature 15: Financial
```
GET    /api/financial/merchants/earnings
POST   /api/financial/admin/payouts/generate
GET    /api/financial/admin/reports/financial
```

### Feature 16: Bulk Ops
```
POST   /api/bulk/products/bulk-upload
PUT    /api/bulk/products/bulk-update-price
GET    /api/bulk/products/export
```

### Feature 17: Search
```
GET    /api/search/products
GET    /api/search/suggestions
GET    /api/search/trending
```

### Feature 19: Returns
```
POST   /api/returns
GET    /api/returns/my-returns
PUT    /api/returns/admin/:id/process
```

### Feature 20: Gift Cards ⭐ NEW
```
GET    /api/gift-cards/balance/:code (Public)
POST   /api/gift-cards/validate (User)
POST   /api/gift-cards/redeem (User)
GET    /api/gift-cards/my-cards (User)
POST   /api/gift-cards/admin/generate (Admin)
```

---

## 📦 **Models (21 Total)**

Core: User, Merchant, Product, Order, Cart, Address, Category  
Features: Wallet, Membership, PreBooking, Dispute, Payout, Return, GiftCard  
System: Notification, Recipe, Review, Subscription, Offer, PlatformSettings, Upload

---

## 🔐 **Authentication**

```bash
# Login
POST /api/auth/user/login
POST /api/auth/merchant/login
POST /api/auth/admin/login

# Headers
Authorization: Bearer {token}
```

---

## 🧪 **Quick Test**

```bash
# Health check
curl http://localhost:5000/health

# API docs
curl http://localhost:5000/api

# Test gift card (new!)
curl http://localhost:5000/api/gift-cards/balance/GB-GIFT-123
```

---

## 📁 **Key Files**

```
server.js                          - Main entry point
src/models/                        - 21 models
src/controllers/                   - 20+ controllers
src/routes/                        - 20+ route files
src/middlewares/authMiddleware.js  - Auth & RBAC
```

---

## 🎯 **Common Workflows**

### Dispute Resolution
```
1. User raises → POST /api/disputes
2. Admin reviews → GET /api/disputes/admin/all
3. Admin resolves → PUT /api/disputes/admin/:id/resolve
4. Wallet credited automatically
```

### Gift Card Usage ⭐
```
1. Admin generates → POST /api/gift-cards/admin/generate
2. User checks → GET /api/gift-cards/balance/:code
3. User redeems → POST /api/gift-cards/redeem
4. Order total reduced automatically
```

### Payout Processing
```
1. Admin generates → POST /api/financial/admin/payouts/generate
2. Review → GET /api/financial/admin/payouts
3. Process → POST /api/financial/admin/payouts/:id/process
4. Merchant notified
```

---

## 📊 **Stats**

- **Lines of Code:** 15,000+
- **Files:** 60+
- **Dependencies:** 25+
- **Database Collections:** 21
- **API Endpoints:** 204

---

## ✅ **Production Ready**

- [x] All features implemented
- [x] Error handling
- [x] Input validation
- [x] Authentication & Authorization
- [x] Rate limiting
- [x] Documentation
- [x] Testing examples

---

## 🚀 **Start Server**

```bash
npm install
npm start
```

**Server:** http://localhost:5000  
**API Docs:** http://localhost:5000/api  
**Health:** http://localhost:5000/health

---

**Version:** 1.0.0  
**Status:** ✅ Complete  
**Date:** Feb 11, 2026
