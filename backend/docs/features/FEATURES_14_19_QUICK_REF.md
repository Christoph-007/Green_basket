# Features 14-19 Quick Reference

## 🎯 **33 New APIs Across 6 Features**

---

## Feature 14: Disputes (8 APIs)

### User
```
POST   /api/disputes                    - Raise dispute
GET    /api/disputes/my-disputes        - My disputes
GET    /api/disputes/:id                - Dispute details
POST   /api/disputes/:id/message        - Add message
PATCH  /api/disputes/:id/escalate       - Escalate
```

### Admin
```
GET    /api/disputes/admin/all          - All disputes
PUT    /api/disputes/admin/:id/resolve  - Resolve
PATCH  /api/disputes/admin/:id/status   - Update status
```

---

## Feature 15: Financial (10 APIs)

### Merchant
```
GET    /api/financial/merchants/earnings - Earnings
GET    /api/financial/merchants/payouts  - Payout history
```

### Admin
```
GET    /api/financial/admin/payouts                  - All payouts
POST   /api/financial/admin/payouts/generate         - Generate
POST   /api/financial/admin/payouts/:id/process      - Process
PATCH  /api/financial/admin/payouts/:id/hold         - Hold/Release
GET    /api/financial/admin/reports/financial        - Financial report
GET    /api/financial/admin/reports/gst              - GST report
PUT    /api/financial/admin/settings/commission      - Update settings
```

### Both
```
GET    /api/financial/payouts/:id       - Payout details
```

---

## Feature 16: Bulk Operations (4 APIs)

### Merchant
```
POST   /api/bulk/products/bulk-upload         - Upload CSV
PUT    /api/bulk/products/bulk-update-price   - Update prices
PUT    /api/bulk/products/bulk-update-stock   - Update stock
GET    /api/bulk/products/export              - Export CSV
```

---

## Feature 17: Search (3 APIs)

### Public
```
GET    /api/search/products      - Advanced search
GET    /api/search/suggestions   - Autocomplete
GET    /api/search/trending      - Trending products
```

---

## Feature 18: Order Tracking

### Enhanced Fields in Order Model
```javascript
statusHistory[]      - Detailed status tracking
estimatedDeliveryTime - ETA
deliveryPersonnel{}  - Driver info
```

---

## Feature 19: Returns (6 APIs)

### User
```
POST   /api/returns              - Request return/exchange
GET    /api/returns/my-returns   - My returns
GET    /api/returns/:id          - Return details
DELETE /api/returns/:id          - Cancel return
```

### Admin
```
GET    /api/returns/admin/all         - All returns
PUT    /api/returns/admin/:id/process - Process return
```

---

## 📊 **Total Backend Stats**

```
Total APIs:     197
Total Features: 19
Models:         20+
Controllers:    15+
Routes:         15+
```

---

## 🔑 **Key Models**

```javascript
Dispute {
  disputeId, order, raisedBy, category,
  description, images, conversation[],
  status, priority, resolution
}

Payout {
  payoutId, merchant, period{},
  grossRevenue, platformCommission,
  netAmount, status, paymentDetails
}

PlatformSettings {
  commission{}, payoutSchedule,
  minimumPayoutAmount, taxSettings{}
}

Return {
  returnId, order, user, items[],
  type, reason, images, status,
  refundAmount, refundMethod
}
```

---

## 🚀 **Quick Start**

### 1. Start Server
```bash
cd backend
npm start
```

### 2. Test Endpoints
```bash
# Get API list
curl http://localhost:5000/api

# Test dispute
curl -X POST http://localhost:5000/api/disputes \
  -H "Authorization: Bearer TOKEN" \
  -d '{"orderId":"GB123","category":"damaged_item","description":"Damaged"}'

# Test search
curl "http://localhost:5000/api/search/products?q=tomato&tags=organic"

# Test returns
curl -X POST http://localhost:5000/api/returns \
  -H "Authorization: Bearer TOKEN" \
  -d '{"orderId":"GB123","type":"return","reason":"Wrong item"}'
```

---

## 📝 **Common Workflows**

### Dispute Resolution
```
1. User raises dispute → POST /api/disputes
2. Admin reviews → GET /api/disputes/admin/all
3. Admin resolves → PUT /api/disputes/admin/:id/resolve
4. Wallet credited automatically
```

### Payout Processing
```
1. Admin generates → POST /api/financial/admin/payouts/generate
2. Review payouts → GET /api/financial/admin/payouts
3. Process payout → POST /api/financial/admin/payouts/:id/process
4. Merchant notified
```

### Bulk Upload
```
1. Prepare CSV with: name,description,category,price,stock,unit,tags
2. Upload → POST /api/bulk/products/bulk-upload
3. Review results: successCount, errorCount, errors[]
```

### Return Request
```
1. User requests → POST /api/returns
2. Admin reviews → GET /api/returns/admin/all
3. Admin approves → PUT /api/returns/admin/:id/process
4. Wallet credited automatically
```

---

## ⚙️ **Configuration**

### Set Commission Rates
```bash
PUT /api/financial/admin/settings/commission
{
  "defaultRate": 5,
  "premiumMerchantRate": 3,
  "payoutSchedule": "weekly",
  "minimumPayoutAmount": 1000
}
```

---

## 🔍 **Search Examples**

```bash
# Basic search
GET /api/search/products?q=tomato

# With filters
GET /api/search/products?q=tomato&minPrice=50&maxPrice=200&tags=organic&sortBy=price_asc

# Autocomplete
GET /api/search/suggestions?q=tom

# Trending
GET /api/search/trending?limit=10
```

---

## 📦 **CSV Format**

```csv
name,description,category,price,stock,unit,tags,primaryImage
Tomatoes,Fresh organic,Vegetables,80,100,kg,"organic,fresh",https://...
Potatoes,Farm fresh,Vegetables,40,200,kg,"fresh",https://...
```

---

## ✅ **Status**

All features are:
- ✅ Implemented
- ✅ Tested
- ✅ Documented
- ✅ Production-ready

**Total: 197 APIs | 19 Features**
