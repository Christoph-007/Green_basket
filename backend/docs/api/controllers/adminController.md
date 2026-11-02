# Admin Controller Documentation

## Overview
**File**: `src/controllers/adminController.js`  
**Purpose**: Handles administrative operations including merchant verification, user management, and platform analytics.

## Dependencies
```javascript
const Merchant = require('../models/Merchant');
const User = require('../models/User');
const Order = require('../models/Order');
```

---

## Methods

### 1. `getPendingMerchants(req, res)`

**Purpose**: Retrieves all merchants awaiting admin verification.

**Access**: Admin only

**Request**: 
- Method: `GET`
- No parameters required

**Logic**:
1. Queries the `Merchant` collection for documents with `verificationStatus: 'pending'`
2. Returns the list of pending merchants

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "_id": "merchant_id",
      "businessName": "Green Farm",
      "email": "farmer@example.com",
      "verificationStatus": "pending",
      ...
    }
  ]
}
```

**Error Handling**:
- Returns 500 status with error message if database query fails

---

### 2. `verifyMerchant(req, res)`

**Purpose**: Approves or rejects a merchant's application.

**Access**: Admin only

**Request**:
- Method: `PATCH/PUT`
- URL Parameter: `id` (merchant ID)
- Body:
```json
{
  "status": "approved", // or "rejected"
  "rejectionReason": "Optional reason if rejected"
}
```

**Logic**:
1. Finds merchant by ID
2. Updates `verificationStatus` to the provided status
3. Sets `verifiedBy` to the current admin's ID
4. Sets `verifiedAt` to current timestamp
5. If rejected, stores the `rejectionReason`
6. Saves the updated merchant document
7. TODO: Send email notification to merchant

**Response**:
```json
{
  "success": true,
  "message": "Merchant approved", // or "Merchant rejected"
  "data": {
    "_id": "merchant_id",
    "verificationStatus": "approved",
    "verifiedBy": "admin_id",
    "verifiedAt": "2024-01-20T10:30:00.000Z"
  }
}
```

**Error Handling**:
- Returns 404 if merchant not found
- Returns 500 for database errors

**Business Impact**:
- Approved merchants can start listing products and receiving orders
- Rejected merchants receive notification with reason

---

### 3. `getUsers(req, res)`

**Purpose**: Fetches all registered users in the platform.

**Access**: Admin only

**Request**:
- Method: `GET`
- No parameters

**Logic**:
1. Queries all documents from `User` collection
2. Excludes password field using `.select('-password')`
3. Returns complete user list

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "_id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "9876543210",
      "isBlocked": false,
      ...
    }
  ]
}
```

**Considerations**:
- For large user bases, pagination should be implemented
- Consider adding filters (active/blocked, date range, etc.)

---

### 4. `toggleUserBlock(req, res)`

**Purpose**: Blocks or unblocks a user account.

**Access**: Admin only

**Request**:
- Method: `PATCH`
- URL Parameter: `id` (user ID)
- Body:
```json
{
  "isBlocked": true,
  "blockedReason": "Violation of terms of service"
}
```

**Logic**:
1. Finds user by ID and updates in one operation
2. Sets `isBlocked` status
3. Stores optional `blockedReason`
4. Returns updated user document

**Response**:
```json
{
  "success": true,
  "message": "User blocked", // or "User unblocked"
  "data": {
    "_id": "user_id",
    "isBlocked": true,
    "blockedReason": "Violation of terms of service"
  }
}
```

**Business Impact**:
- Blocked users cannot log in (checked in `authController.userLogin`)
- Existing sessions should be invalidated
- User receives appropriate error message on login attempt

---

### 5. `getPlatformStats(req, res)`

**Purpose**: Provides high-level platform metrics for admin dashboard.

**Access**: Admin only

**Request**:
- Method: `GET`
- No parameters

**Logic**:
1. Uses `Promise.all()` to execute three count queries in parallel:
   - Total users count
   - Total merchants count
   - Total orders count
2. Returns aggregated statistics

**Response**:
```json
{
  "success": true,
  "data": {
    "totalUsers": 1250,
    "totalMerchants": 45,
    "totalOrders": 3420
  }
}
```

**Performance Considerations**:
- Uses `countDocuments()` which is optimized for counting
- Parallel execution reduces response time
- For very large collections, consider caching these stats

**Potential Enhancements**:
- Add revenue statistics
- Include growth metrics (new users this week/month)
- Add order status breakdown
- Include merchant verification stats

---

## Usage Examples

### Verify a Merchant
```javascript
// Approve merchant
PUT /api/admin/merchants/verify/merchant_id_123
Authorization: Bearer admin_token
{
  "status": "approved"
}

// Reject merchant
PUT /api/admin/merchants/verify/merchant_id_456
{
  "status": "rejected",
  "rejectionReason": "Incomplete documentation"
}
```

### Block a User
```javascript
PATCH /api/admin/users/block/user_id_789
Authorization: Bearer admin_token
{
  "isBlocked": true,
  "blockedReason": "Multiple policy violations"
}
```

---

## Security Considerations

1. **Authentication**: All endpoints require valid admin JWT token
2. **Authorization**: Middleware should verify `userType === 'admin'`
3. **Audit Logging**: Consider logging all admin actions for compliance
4. **Rate Limiting**: Implement stricter rate limits for admin endpoints

---

## Future Improvements

1. **Email Notifications**: Implement email service integration for merchant verification results
2. **Pagination**: Add pagination to `getUsers` for scalability
3. **Advanced Filtering**: Add search and filter capabilities
4. **Bulk Operations**: Support bulk user/merchant management
5. **Activity Logs**: Track admin actions for audit trail
6. **Analytics Dashboard**: Expand stats to include charts and trends
