# Merchant Controller Documentation

## Overview
**File**: `src/controllers/merchantController.js`  
**Purpose**: Manages merchant business profiles, store operations, and dashboard analytics.

## Dependencies
```javascript
const Merchant = require('../models/Merchant');
const Order = require('../models/Order');
const Product = require('../models/Product');
const mongoose = require('mongoose');
```

---

## Methods

### 1. `getProfile(req, res)`

**Purpose**: Retrieves the authenticated merchant's complete profile.

**Access**: Authenticated merchants only

**Request**:
- Method: `GET`
- Merchant ID from JWT token

**Logic**:
- Fetches merchant document by ID
- Returns all profile fields

**Response**:
```json
{
  "success": true,
  "data": {
    "_id": "merchant_id",
    "name": "Farmer John",
    "email": "john@farm.com",
    "phone": "9876543210",
    "businessName": "Green Valley Farm",
    "merchantType": "organic-farmer",
    "businessDescription": "Certified organic vegetables",
    "address": {
      "street": "123 Farm Road",
      "city": "Bangalore",
      "state": "Karnataka",
      "pincode": "560001"
    },
    "verificationStatus": "approved",
    "isStoreOpen": true,
    "averageRating": 4.5,
    "totalReviews": 120,
    "operatingHours": {
      "monday": { "open": "08:00", "close": "18:00", "isOpen": true },
      ...
    },
    "deliveryRadius": 10,
    "minimumOrderValue": 200,
    "deliveryCharges": 40
  }
}
```

**Use Cases**:
- Display merchant dashboard
- Profile editing form pre-fill
- Mobile app profile screen

---

### 2. `updateProfile(req, res)`

**Purpose**: Updates merchant business information.

**Access**: Authenticated merchants only

**Request**:
```json
{
  "businessName": "Green Valley Organic Farm",
  "businessDescription": "Premium organic vegetables and fruits",
  "address": {
    "street": "456 New Farm Road",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560002",
    "landmark": "Near City Hospital"
  },
  "operatingHours": {
    "monday": { "open": "07:00", "close": "19:00", "isOpen": true },
    "tuesday": { "open": "07:00", "close": "19:00", "isOpen": true },
    "sunday": { "open": "08:00", "close": "14:00", "isOpen": true }
  },
  "deliveryRadius": 15,
  "minimumOrderValue": 250,
  "deliveryCharges": 50,
  "bankDetails": {
    "accountHolderName": "John Doe",
    "accountNumber": "1234567890",
    "ifscCode": "SBIN0001234",
    "bankName": "State Bank of India",
    "branch": "Bangalore Main"
  }
}
```

**Updatable Fields**:
- Business information (name, description)
- Address and location
- Operating hours
- Delivery settings (radius, charges, minimum order)
- Bank details for payments

**Logic Flow**:
1. Extracts update fields from request body
2. Finds merchant by ID and updates
3. Runs validators to ensure data integrity
4. Returns updated merchant document

**Response**:
```json
{
  "success": true,
  "message": "Merchant profile updated",
  "data": {
    // Updated merchant object
  }
}
```

**Validation**:
- `runValidators: true` ensures schema validation
- Required fields cannot be removed
- Data types must match schema

**Business Impact**:
- Delivery radius affects customer visibility
- Operating hours control order acceptance
- Bank details required for payment settlements

---

### 3. `toggleStoreStatus(req, res)`

**Purpose**: Opens or closes the merchant's store for new orders.

**Access**: Authenticated merchants only

**Request**:
- Method: `PATCH`
- No body required (toggles current state)

**Logic Flow**:
1. Fetches merchant document
2. Toggles `isStoreOpen` boolean
3. Saves updated status
4. Returns new status

**Response**:
```json
{
  "success": true,
  "message": "Store is now Open", // or "Store is now Closed"
  "isStoreOpen": true
}
```

**Business Logic**:
- When closed, store doesn't appear in customer searches
- Existing orders continue to be processed
- Useful for:
  - Daily opening/closing
  - Temporary closures (holidays, emergencies)
  - Inventory management

**Frontend Integration**:
```javascript
// Toggle button in merchant dashboard
const toggleStore = async () => {
  const response = await api.patch('/api/merchants/toggle-store');
  // Update UI based on response.isStoreOpen
};
```

---

### 4. `getDashboardStats(req, res)`

**Purpose**: Provides key business metrics for the merchant dashboard.

**Access**: Authenticated merchants only

**Request**:
- Method: `GET`
- Merchant ID from JWT

**Logic Flow**:
1. **Parallel Queries**: Uses `Promise.all()` for efficiency
2. **Total Orders**: Counts all orders for this merchant
3. **Total Revenue**: Aggregates sum of delivered orders
4. **Low Stock Alert**: Counts products with stock ≤ 10

**MongoDB Aggregation for Revenue**:
```javascript
Order.aggregate([
  { 
    $match: { 
      merchant: new mongoose.Types.ObjectId(merchantId), 
      status: 'delivered' 
    } 
  },
  { 
    $group: { 
      _id: null, 
      total: { $sum: '$totalAmount' } 
    } 
  }
])
```

**Response**:
```json
{
  "success": true,
  "data": {
    "totalOrders": 342,
    "totalRevenue": 125600,
    "lowStockProducts": 8
  }
}
```

**Dashboard Display**:
```
┌─────────────────────────────────────┐
│  Merchant Dashboard                 │
├─────────────────────────────────────┤
│  Total Orders:        342           │
│  Total Revenue:       ₹1,25,600     │
│  Low Stock Alerts:    8 products    │
└─────────────────────────────────────┘
```

**Performance**:
- Three queries run in parallel
- Aggregation is efficient for large datasets
- Consider caching for high-traffic merchants

---

## Business Workflows

### Daily Operations Flow

1. **Morning**: Merchant opens store
   ```
   PATCH /api/merchants/toggle-store
   ```

2. **Throughout Day**: Monitor dashboard
   ```
   GET /api/merchants/dashboard-stats
   ```

3. **Inventory Check**: Review low stock alerts
   ```
   GET /api/products/my/products?status=low-stock
   ```

4. **Evening**: Close store
   ```
   PATCH /api/merchants/toggle-store
   ```

### Profile Management Flow

1. **View Current Profile**
   ```
   GET /api/merchants/profile
   ```

2. **Update Business Info**
   ```
   PUT /api/merchants/profile
   ```

3. **Verify Changes**
   ```
   GET /api/merchants/profile
   ```

---

## Data Relationships

### Merchant → Orders
- One merchant has many orders
- Used for revenue calculation
- Filtered by status for accurate metrics

### Merchant → Products
- One merchant has many products
- Used for inventory management
- Low stock alerts help prevent stockouts

### Merchant → Reviews
- Customers review merchant service
- Aggregated into `averageRating`
- Displayed on merchant profile

---

## Security Considerations

1. **Authorization**: Merchants can only access their own data
   - `req.user.id` ensures isolation
   - Middleware validates merchant role

2. **Sensitive Data**: Bank details require extra protection
   - Consider encryption at rest
   - Mask account numbers in responses
   - Audit log for changes

3. **Store Status**: Prevent unauthorized toggling
   - Only merchant can change their status
   - Admin override capability (future)

---

## Error Handling

All methods follow consistent pattern:

```javascript
try {
  // Business logic
} catch (error) {
  res.status(500).json({
    success: false,
    message: 'Error description',
    error: error.message
  });
}
```

**Common Errors**:
- 404: Merchant not found (shouldn't happen with JWT)
- 500: Database errors, aggregation failures

---

## API Endpoints Summary

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/merchants/profile` | Get merchant profile |
| PUT | `/api/merchants/profile` | Update profile |
| PATCH | `/api/merchants/toggle-store` | Open/close store |
| GET | `/api/merchants/dashboard-stats` | Get analytics |

---

## Future Enhancements

1. **Advanced Analytics**:
   - Revenue trends (daily, weekly, monthly)
   - Top-selling products
   - Customer demographics
   - Order fulfillment time

2. **Inventory Management**:
   - Automated low stock alerts
   - Reorder suggestions
   - Seasonal demand forecasting

3. **Performance Metrics**:
   - Order acceptance rate
   - Average delivery time
   - Customer satisfaction score
   - Repeat customer percentage

4. **Financial Tools**:
   - Payout history
   - Tax reports
   - Expense tracking
   - Profit margins

5. **Store Customization**:
   - Custom store hours for holidays
   - Vacation mode with auto-response
   - Delivery zone mapping
   - Dynamic pricing rules

6. **Communication**:
   - Bulk customer notifications
   - Order update templates
   - Chat with customers

7. **Multi-Store Support**:
   - Manage multiple locations
   - Transfer inventory between stores
   - Consolidated reporting
