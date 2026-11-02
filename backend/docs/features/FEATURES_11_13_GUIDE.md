# Features 11-13 Implementation Guide

## Overview
This document provides comprehensive details about Features 11-13 for the GreenBasket backend platform.

---

## Feature 11: Premium Membership System

### Overview
Complete premium membership system with tiered plans, exclusive benefits, and automatic renewal management.

### Database Schema
**Model:** `Membership.js`
- User reference (unique)
- Plan types: basic, premium, premium_plus
- Status tracking: active, cancelled, expired
- Payment history
- Auto-renewal settings

### API Endpoints (6 APIs)

#### 11.1 GET /api/membership/plans (Public)
Get all available membership plans with pricing and benefits.

**Response:**
```json
{
  "success": true,
  "data": {
    "plans": {
      "basic": {
        "price": 0,
        "durationDays": 0,
        "benefits": {
          "freeDelivery": false,
          "bonusPoints": 0
        }
      },
      "premium": {
        "price": 199,
        "durationDays": 30,
        "benefits": {
          "freeDelivery": true,
          "bonusPoints": 10,
          "exclusiveDeals": true
        }
      },
      "premium_plus": {
        "price": 499,
        "durationDays": 90,
        "benefits": {
          "freeDelivery": true,
          "bonusPoints": 20,
          "exclusiveDeals": true,
          "earlyAccess": true,
          "prioritySupport": true
        }
      }
    }
  }
}
```

#### 11.2 GET /api/membership (User)
Get current user's membership details.

**Headers:** `Authorization: Bearer {token}`

**Response:**
```json
{
  "success": true,
  "data": {
    "membership": {
      "_id": "...",
      "user": "...",
      "plan": "premium",
      "status": "active",
      "startDate": "2026-02-10",
      "endDate": "2026-03-10",
      "autoRenew": true
    },
    "planDetails": { /* plan configuration */ },
    "isActive": true
  }
}
```

#### 11.3 POST /api/membership/subscribe (User)
Subscribe to a premium plan.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "plan": "premium",
  "paymentId": "pay_xxxxx",
  "razorpaySubscriptionId": "sub_xxxxx"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Subscribed successfully",
  "data": {
    "membership": { /* membership object */ },
    "planDetails": { /* plan configuration */ }
  }
}
```

#### 11.4 POST /api/membership/cancel (User)
Cancel current membership (benefits continue until end date).

**Headers:** `Authorization: Bearer {token}`

**Response:**
```json
{
  "success": true,
  "message": "Membership cancelled successfully. You can continue using premium benefits until the end date.",
  "data": {
    "membership": { /* updated membership */ }
  }
}
```

#### 11.5 GET /api/membership/premium-products (User)
Get products exclusive to premium members.

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20)

**Response:**
```json
{
  "success": true,
  "data": {
    "products": [ /* premium exclusive products */ ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50,
      "pages": 3
    }
  }
}
```

#### 11.6 GET /api/membership/check-benefit (User)
Check if user has a specific membership benefit.

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `benefit` (e.g., "freeDelivery", "bonusPoints", "exclusiveDeals")

**Response:**
```json
{
  "success": true,
  "data": {
    "hasBenefit": true,
    "membershipPlan": "premium",
    "benefitValue": true
  }
}
```

### Key Features
- ✅ Three-tier membership system
- ✅ Automatic expiry checking
- ✅ Payment history tracking
- ✅ Auto-renewal management
- ✅ Premium exclusive products
- ✅ Benefit verification system
- ✅ Email/push notifications

### Integration Points
- **Payment System:** Razorpay subscription integration
- **Product System:** `isPremiumExclusive` flag
- **Notification System:** Membership activation/expiry alerts
- **Order System:** Free delivery for premium members

---

## Feature 12: Pre-Booking System

### Overview
Allow users to pre-book products that are currently out of stock, with automatic notifications when available.

### Database Schema
**Model:** `PreBooking.js`
- User, product, and merchant references
- Quantity and expected availability
- Status: pending, available, ordered, cancelled, expired
- 7-day expiry after availability
- Notification preferences

### API Endpoints (6 APIs)

#### 12.1 POST /api/prebooking (User)
Create a new pre-booking for an out-of-stock product.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "productId": "prod_123",
  "quantity": 2,
  "expectedAvailability": "2026-03-01",
  "notes": "Please notify when available"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Pre-booking created successfully. You will be notified when the product becomes available.",
  "data": {
    "preBooking": {
      "_id": "...",
      "user": "...",
      "product": { /* populated product */ },
      "merchant": { /* populated merchant */ },
      "quantity": 2,
      "expectedAvailability": "2026-03-01",
      "status": "pending"
    }
  }
}
```

#### 12.2 GET /api/prebooking/my-prebookings (User)
Get user's pre-bookings with filtering.

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `status` (optional: pending, available, ordered, cancelled, expired)
- `page` (default: 1)
- `limit` (default: 20)

**Response:**
```json
{
  "success": true,
  "data": {
    "preBookings": [ /* array of pre-bookings */ ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5,
      "pages": 1
    }
  }
}
```

#### 12.3 DELETE /api/prebooking/:id (User)
Cancel a pending pre-booking.

**Headers:** `Authorization: Bearer {token}`

**Response:**
```json
{
  "success": true,
  "message": "Pre-booking cancelled successfully"
}
```

#### 12.4 PATCH /api/prebooking/products/:id/mark-available (Merchant)
Mark a product as available and notify all users with pending pre-bookings.

**Headers:** `Authorization: Bearer {merchant_token}`

**Request Body:**
```json
{
  "stock": 100
}
```

**Response:**
```json
{
  "success": true,
  "message": "Product marked as available. 5 user(s) notified.",
  "data": {
    "product": {
      "_id": "...",
      "name": "Organic Tomatoes",
      "stock": 100
    },
    "preBookingsUpdated": 5,
    "usersNotified": 5
  }
}
```

**What Happens:**
1. Product stock updated and activated
2. All pending pre-bookings → status "available"
3. Expiry date set to 7 days from now
4. Email + push notifications sent to users

#### 12.5 POST /api/prebooking/:id/convert-to-order (User)
Convert an available pre-booking to cart item.

**Headers:** `Authorization: Bearer {token}`

**Response:**
```json
{
  "success": true,
  "message": "Pre-booking converted successfully. Product added to your cart.",
  "data": {
    "preBooking": { /* updated pre-booking */ },
    "cart": { /* updated cart */ }
  }
}
```

#### 12.6 GET /api/prebooking/admin/all (Admin)
Get all pre-bookings with statistics (Admin view).

**Headers:** `Authorization: Bearer {admin_token}`

**Query Parameters:**
- `status` (optional filter)
- `page` (default: 1)
- `limit` (default: 20)

**Response:**
```json
{
  "success": true,
  "data": {
    "preBookings": [ /* array of pre-bookings */ ],
    "pagination": { /* pagination info */ },
    "statistics": [
      { "_id": "pending", "count": 15 },
      { "_id": "available", "count": 8 },
      { "_id": "ordered", "count": 42 }
    ]
  }
}
```

### Key Features
- ✅ Automatic expiry management (7 days)
- ✅ Bulk notification system
- ✅ Cart integration
- ✅ Duplicate prevention
- ✅ Product availability validation
- ✅ Admin analytics

### Workflow
1. **User** creates pre-booking for out-of-stock product
2. **Merchant** marks product as available
3. **System** notifies all users with pending pre-bookings
4. **User** has 7 days to convert to order
5. **System** auto-expires if not converted

---

## Feature 13: Document Verification System

### Overview
Comprehensive document management and verification system for merchant onboarding and compliance.

### Database Schema
**Updated:** `Merchant.js` model with `documents[]` array

**Document Types:**
- fssai
- gst
- pan
- aadhaar
- bank_details
- organic_certificate
- farm_ownership
- other

**Document Status:**
- pending
- verified
- rejected
- expired

### API Endpoints (6 APIs)

#### 13.1 POST /api/documents/upload (Merchant)
Upload or update a merchant document.

**Headers:** `Authorization: Bearer {merchant_token}`

**Request Body:**
```json
{
  "documentType": "fssai",
  "documentNumber": "12345678901234",
  "documentUrl": "https://cloudinary.com/...",
  "expiryDate": "2027-12-31",
  "notes": "FSSAI license for food business"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Document submitted for verification",
  "data": {
    "documents": [ /* all merchant documents */ ]
  }
}
```

**Notes:**
- If document type exists, it will be updated
- Status automatically set to "pending"
- Previous rejection reason cleared

#### 13.2 GET /api/documents (Merchant)
Get all documents for the logged-in merchant.

**Headers:** `Authorization: Bearer {merchant_token}`

**Response:**
```json
{
  "success": true,
  "data": {
    "documents": [
      {
        "_id": "...",
        "type": "fssai",
        "documentNumber": "12345678901234",
        "documentUrl": "https://...",
        "expiryDate": "2027-12-31",
        "status": "verified",
        "verifiedBy": "...",
        "verifiedAt": "2026-02-10",
        "uploadedAt": "2026-02-09"
      }
    ],
    "merchantInfo": {
      "businessName": "Green Farm",
      "email": "farm@example.com"
    }
  }
}
```

**Auto-Expiry Check:**
- System automatically marks documents as "expired" if past expiry date

#### 13.3 DELETE /api/documents/:documentId (Merchant)
Delete a document (only pending or rejected).

**Headers:** `Authorization: Bearer {merchant_token}`

**Response:**
```json
{
  "success": true,
  "message": "Document deleted successfully"
}
```

**Restrictions:**
- Cannot delete verified documents
- Contact support for verified document changes

#### 13.4 GET /api/documents/admin/pending (Admin)
Get all pending documents across all merchants.

**Headers:** `Authorization: Bearer {admin_token}`

**Response:**
```json
{
  "success": true,
  "data": {
    "pendingDocuments": [
      {
        "merchantId": "...",
        "businessName": "Green Farm",
        "email": "farm@example.com",
        "phone": "+91...",
        "document": { /* document object */ }
      }
    ],
    "count": 12
  }
}
```

**Sorting:** Newest first by upload date

#### 13.5 PUT /api/documents/admin/:merchantId/:documentId/verify (Admin)
Verify or reject a merchant document.

**Headers:** `Authorization: Bearer {admin_token}`

**Request Body:**
```json
{
  "status": "verified",
  "rejectionReason": "Invalid document format" // only if rejected
}
```

**Response:**
```json
{
  "success": true,
  "message": "Document verified successfully",
  "data": {
    "document": { /* updated document */ },
    "merchantInfo": {
      "businessName": "Green Farm",
      "email": "farm@example.com"
    }
  }
}
```

**Actions:**
1. Update document status
2. Record verifier and timestamp
3. Send email + push notification to merchant
4. If rejected, include reason in notification

#### 13.6 GET /api/documents/admin/expiring-soon (Admin)
Get documents expiring within specified days.

**Headers:** `Authorization: Bearer {admin_token}`

**Query Parameters:**
- `days` (default: 30) - Look ahead period

**Response:**
```json
{
  "success": true,
  "data": {
    "expiringDocuments": [
      {
        "merchantId": "...",
        "businessName": "Green Farm",
        "email": "farm@example.com",
        "phone": "+91...",
        "document": { /* document object */ },
        "daysUntilExpiry": 5,
        "urgency": "high" // high: ≤7 days, medium: ≤15 days, low: >15 days
      }
    ],
    "count": 8,
    "breakdown": {
      "high": 2,
      "medium": 3,
      "low": 3
    }
  }
}
```

**Sorting:** Most urgent first (by days until expiry)

### Key Features
- ✅ 8 document types supported
- ✅ Automatic expiry tracking
- ✅ Admin verification workflow
- ✅ Rejection reason tracking
- ✅ Email + push notifications
- ✅ Urgency classification
- ✅ Update/reupload capability

### Workflow
1. **Merchant** uploads required documents
2. **Admin** reviews pending documents
3. **Admin** verifies or rejects with reason
4. **Merchant** receives notification
5. **System** tracks expiry dates
6. **Admin** gets alerts for expiring documents

---

## Integration Summary

### Product Model Updates
Added fields to `Product.js`:
```javascript
isPremiumExclusive: Boolean  // For Feature 11
isPreBookable: Boolean        // For Feature 12
expectedAvailabilityDate: Date // For Feature 12
isActive: Boolean             // General status
```

### Merchant Model Updates
Added to `Merchant.js`:
```javascript
documents: [{
  type: String,
  documentNumber: String,
  documentUrl: String,
  expiryDate: Date,
  status: String,
  verifiedBy: ObjectId,
  verifiedAt: Date,
  rejectionReason: String,
  uploadedAt: Date,
  notes: String
}]
```

### Notification Integration
All three features send notifications:
- **Membership:** Activation, expiry warnings
- **Pre-Booking:** Product availability alerts
- **Documents:** Verification status updates

### Payment Integration
- **Membership:** Razorpay subscription integration
- Payment history tracking
- Auto-renewal support

---

## Testing Checklist

### Feature 11: Membership
- [ ] Get all plans
- [ ] Subscribe to premium
- [ ] Check membership status
- [ ] Access premium products
- [ ] Verify benefits
- [ ] Cancel membership

### Feature 12: Pre-Booking
- [ ] Create pre-booking
- [ ] View my pre-bookings
- [ ] Cancel pre-booking
- [ ] Merchant marks available
- [ ] Receive notification
- [ ] Convert to order
- [ ] Check expiry

### Feature 13: Documents
- [ ] Upload document
- [ ] View documents
- [ ] Admin view pending
- [ ] Admin verify document
- [ ] Admin reject document
- [ ] Check expiring documents
- [ ] Delete pending document

---

## Error Handling

All endpoints include comprehensive error handling:
- Input validation
- Authentication checks
- Authorization verification
- Database error handling
- Notification error logging (non-blocking)

---

## Security Considerations

1. **Authentication:** All endpoints require valid JWT
2. **Authorization:** Role-based access (User/Merchant/Admin)
3. **Validation:** Input sanitization and type checking
4. **Document URLs:** Secure Cloudinary URLs
5. **Payment IDs:** Razorpay verification required

---

## Performance Optimizations

1. **Indexes:**
   - Membership: `{ user: 1, status: 1 }`
   - PreBooking: `{ user: 1, status: 1 }`, `{ product: 1, status: 1 }`
   - Documents: Embedded in Merchant model

2. **Pagination:** All list endpoints support pagination

3. **Population:** Selective field population to reduce data transfer

4. **Caching Recommendations:**
   - Membership plans: Static data, cache indefinitely
   - Premium products: 15-minute TTL
   - Pending documents: 5-minute TTL

---

## API Statistics

| Feature | APIs | Models | Routes |
|---------|------|--------|--------|
| Premium Membership | 6 | 1 | 1 |
| Pre-Booking System | 6 | 1 | 1 |
| Document Verification | 6 | 0* | 1 |
| **Total** | **18** | **2** | **3** |

*Uses updated Merchant model

---

**Implementation Date:** February 10, 2026  
**Status:** ✅ Production Ready  
**Total APIs (Features 11-13):** 18  
**Grand Total APIs:** 164
