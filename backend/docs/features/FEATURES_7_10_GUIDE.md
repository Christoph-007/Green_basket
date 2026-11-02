# Features 7-10 Implementation Guide

## Overview
This document provides comprehensive details about the newly implemented features 7-10 for the GreenBasket backend platform.

## Feature 7: Referral System

### Overview
Complete referral system allowing users to invite friends, track referrals, and earn wallet bonuses when referred users complete their first order.

### Configuration
**File:** `src/config/referral.js`

```javascript
{
  referrerBonus: 100,       // ₹100 for referrer when friend completes first order
  referredBonus: 50,        // ₹50 for new user who signs up with referral code
  minOrderForReward: 200,   // Minimum order value to trigger referral reward
  codeLength: 8,            // Length of referral code
  codePrefix: 'GB'          // Prefix for all referral codes
}
```

### API Endpoints

#### 1. Generate Referral Code
- **Endpoint:** `POST /api/referral/generate`
- **Auth:** Required (User)
- **Description:** Generates a unique referral code for the user
- **Response:** Returns referral code, link, and share text

#### 2. Get Referral Stats
- **Endpoint:** `GET /api/referral/stats`
- **Auth:** Required (User)
- **Description:** Get user's referral statistics and earnings
- **Response:** Total referrals, completed/pending counts, earnings

#### 3. Apply Referral Code
- **Endpoint:** `POST /api/referral/apply`
- **Auth:** Required (User)
- **Body:** `{ "referralCode": "GBJOHN1234" }`
- **Description:** Apply referral code during signup
- **Response:** Confirmation and bonus amount

#### 4. Validate Referral Code
- **Endpoint:** `GET /api/referral/validate/:code`
- **Auth:** Public
- **Description:** Validate if a referral code exists
- **Response:** Validity status and referrer name (masked)

#### 5. Process Referral Reward
- **Endpoint:** `POST /api/referral/process-reward`
- **Auth:** Required (Admin/System)
- **Description:** Internal endpoint to process rewards after first order
- **Body:** `{ "userId": "...", "orderId": "...", "orderAmount": 500 }`

### Database Schema
The User model already includes the referral structure:
- `referral.code`: Unique referral code
- `referral.referredBy`: Reference to referrer
- `referral.referrals[]`: Array of referred users
- `referral.totalEarned`: Total earnings from referrals

---

## Feature 8: Offers & Promotions System

### Overview
Complete promotional system for merchants and admins to create coupons, flash sales, category discounts, and product-specific offers.

### Offer Types
1. **Percentage:** Discount by percentage (e.g., 20% off)
2. **Flat:** Fixed amount discount (e.g., ₹50 off)
3. **BOGO:** Buy One Get One
4. **Free Delivery:** Waive delivery charges
5. **Bundle:** Bundle deals

### API Endpoints

#### 1. Create Offer
- **Endpoint:** `POST /api/offers`
- **Auth:** Required (Merchant/Admin)
- **Description:** Create a new offer/coupon
- **Body:**
```json
{
  "title": "Weekend Special",
  "description": "Get 20% off on all vegetables",
  "type": "percentage",
  "discountPercentage": 20,
  "maxDiscountCap": 100,
  "minOrderValue": 300,
  "applicableOn": "categories",
  "categories": ["category_id"],
  "startDate": "2024-02-10T00:00:00.000Z",
  "endDate": "2024-02-12T23:59:59.000Z",
  "couponCode": "WEEKEND20",
  "totalUsageLimit": 100,
  "usagePerUser": 1,
  "isFlashSale": false
}
```

#### 2. Get Merchant Offers
- **Endpoint:** `GET /api/offers/merchant`
- **Auth:** Required (Merchant)
- **Query:** `?status=active&page=1&limit=20`
- **Description:** Get all offers created by merchant

#### 3. Get Available Offers
- **Endpoint:** `GET /api/offers/available`
- **Auth:** Required (User)
- **Query:** `?merchantId=...&cartTotal=500`
- **Description:** Get available offers for user with eligibility check

#### 4. Apply Coupon
- **Endpoint:** `POST /api/offers/cart/apply-coupon`
- **Auth:** Required (User)
- **Body:** `{ "couponCode": "WEEKEND20" }`
- **Description:** Apply coupon code to cart

#### 5. Remove Coupon
- **Endpoint:** `DELETE /api/offers/cart/remove-coupon`
- **Auth:** Required (User)
- **Description:** Remove applied coupon from cart

#### 6. Update Offer
- **Endpoint:** `PUT /api/offers/:id`
- **Auth:** Required (Merchant/Admin - Owner)
- **Description:** Update existing offer

#### 7. Delete Offer
- **Endpoint:** `DELETE /api/offers/:id`
- **Auth:** Required (Merchant/Admin)
- **Description:** Deactivate offer (soft delete)

#### 8. Get Offer Analytics
- **Endpoint:** `GET /api/offers/:id/analytics`
- **Auth:** Required (Merchant/Admin)
- **Description:** Get detailed analytics for an offer
- **Response:** Usage stats, revenue generated, daily breakdown

#### 9. Get Flash Sales
- **Endpoint:** `GET /api/offers/flash-sales`
- **Auth:** Public
- **Description:** Get all active flash sales with countdown

#### 10. Get All Offers (Admin)
- **Endpoint:** `GET /api/offers/admin/all`
- **Auth:** Required (Admin)
- **Query:** `?status=active&type=percentage&page=1`
- **Description:** Get all platform offers

### Cart Integration
The Cart model has been updated to support:
- `appliedCoupon.code`: Applied coupon code
- `appliedCoupon.offerId`: Reference to offer
- `appliedCoupon.discount`: Calculated discount
- `discount`: Total discount amount
- `finalTotal`: Final amount after discount

---

## Feature 9: Advanced Merchant Analytics

### Overview
Comprehensive analytics dashboard for merchants including sales trends, product performance, customer insights, and inventory analysis.

### API Endpoints

#### 1. Sales Analytics
- **Endpoint:** `GET /api/merchants/analytics/sales`
- **Auth:** Required (Merchant)
- **Query:** `?period=month&startDate=...&endDate=...`
- **Periods:** today, week, month, year
- **Response:**
```json
{
  "summary": {
    "totalRevenue": 25000,
    "totalOrders": 150,
    "averageOrderValue": 167,
    "revenueGrowth": 15.5,
    "ordersGrowth": 12.3
  },
  "dailyBreakdown": [...],
  "peakHours": [...],
  "topSellingDay": "Saturday",
  "paymentMethodBreakdown": {...}
}
```

#### 2. Product Performance Analytics
- **Endpoint:** `GET /api/merchants/analytics/products`
- **Auth:** Required (Merchant)
- **Query:** `?limit=10`
- **Response:** Best sellers and low performers

#### 3. Customer Analytics
- **Endpoint:** `GET /api/merchants/analytics/customers`
- **Auth:** Required (Merchant)
- **Response:**
```json
{
  "totalCustomers": 250,
  "newCustomers": 45,
  "returningCustomers": 205,
  "retentionRate": 82,
  "averageOrderFrequency": 3.2,
  "topCustomers": [...]
}
```

#### 4. Inventory Analytics
- **Endpoint:** `GET /api/merchants/analytics/inventory`
- **Auth:** Required (Merchant)
- **Response:**
```json
{
  "totalProducts": 150,
  "activeProducts": 145,
  "lowStockProducts": 12,
  "outOfStockProducts": 5,
  "inventoryValue": 125000,
  "recommendations": [...]
}
```

#### 5. Revenue Forecast
- **Endpoint:** `GET /api/merchants/analytics/forecast`
- **Auth:** Required (Merchant)
- **Description:** AI-powered revenue prediction based on historical data
- **Response:**
```json
{
  "nextMonth": {
    "predictedRevenue": 28000,
    "predictedOrders": 165,
    "confidence": 0.85,
    "growthRate": 12.5
  },
  "historicalAverage": {...}
}
```

#### 6. Review Analytics
- **Endpoint:** `GET /api/merchants/analytics/reviews`
- **Auth:** Required (Merchant)
- **Response:**
```json
{
  "totalReviews": 320,
  "averageRating": 4.5,
  "reviewsThisMonth": 28,
  "ratingDistribution": {
    "1": 5, "2": 10, "3": 25, "4": 80, "5": 200
  }
}
```

---

## Feature 10: Delivery Zone Management

### Overview
Geographic delivery zone management for merchants with delivery charge calculation, zone validation, and nearby merchant discovery.

### Database Schema
The Merchant model has been enhanced with:
- `location.type`: 'Point' (GeoJSON)
- `location.coordinates`: [longitude, latitude]
- `deliveryZones[]`: Array of delivery zones

### Delivery Zone Structure
```javascript
{
  name: "City Center Zone",
  radiusKm: 5,
  deliveryCharge: 30,
  minimumOrder: 200,
  freeDeliveryAbove: 500,
  estimatedDeliveryTime: "30-45 mins",
  isActive: true
}
```

### API Endpoints

#### 1. Set Merchant Location
- **Endpoint:** `PUT /api/merchants/zones/location`
- **Auth:** Required (Merchant)
- **Body:**
```json
{
  "latitude": 8.5241,
  "longitude": 76.9366,
  "address": {
    "street": "123 Main St",
    "city": "Thiruvananthapuram",
    "state": "Kerala",
    "pincode": "695001"
  }
}
```

#### 2. Add Delivery Zone
- **Endpoint:** `POST /api/merchants/zones/delivery-zones`
- **Auth:** Required (Merchant)
- **Body:**
```json
{
  "name": "City Center Zone",
  "radiusKm": 5,
  "deliveryCharge": 30,
  "minimumOrder": 200,
  "freeDeliveryAbove": 500,
  "estimatedDeliveryTime": "30-45 mins"
}
```

#### 3. Get All Delivery Zones
- **Endpoint:** `GET /api/merchants/zones/delivery-zones`
- **Auth:** Required (Merchant)
- **Response:** All zones with merchant location

#### 4. Update Delivery Zone
- **Endpoint:** `PUT /api/merchants/zones/delivery-zones/:zoneId`
- **Auth:** Required (Merchant)
- **Description:** Update zone settings

#### 5. Delete Delivery Zone
- **Endpoint:** `DELETE /api/merchants/zones/delivery-zones/:zoneId`
- **Auth:** Required (Merchant)
- **Description:** Remove delivery zone

#### 6. Check Delivery Availability
- **Endpoint:** `POST /api/merchants/zones/check-delivery`
- **Auth:** Public
- **Body:**
```json
{
  "merchantId": "merchant_id",
  "latitude": 8.5241,
  "longitude": 76.9366
}
```
- **Response:**
```json
{
  "canDeliver": true,
  "zone": {
    "name": "City Center Zone",
    "deliveryCharge": 30,
    "minimumOrder": 200,
    "estimatedDeliveryTime": "30-45 mins"
  },
  "distanceKm": 2.5
}
```

#### 7. Get Nearby Merchants
- **Endpoint:** `POST /api/merchants/zones/nearby`
- **Auth:** Public
- **Body:**
```json
{
  "latitude": 8.5241,
  "longitude": 76.9366,
  "maxDistanceKm": 10
}
```
- **Description:** Find merchants within delivery range using geospatial queries
- **Response:** List of merchants sorted by distance with delivery info

### Geospatial Features
- Uses MongoDB 2dsphere index for efficient location queries
- Haversine formula for accurate distance calculation
- Supports multiple delivery zones per merchant
- Automatic zone matching based on customer location

---

## Integration Notes

### Order Processing
When an order is placed:
1. Check if user was referred
2. If first order and meets minimum amount, trigger referral reward
3. Apply any coupon discounts
4. Calculate delivery charges based on zone
5. Update offer usage count

### Wallet Integration
- Referral bonuses automatically credited to wallet
- Uses `walletHelpers.addReferralBonus()` function
- Notifications sent for all wallet credits

### Notification Integration
All features send notifications:
- Referral code applied
- Referral reward earned
- Coupon applied successfully
- Low stock alerts (analytics)

---

## Testing Recommendations

### Referral System
1. Test referral code generation uniqueness
2. Verify bonus credits on signup and first order
3. Test self-referral prevention
4. Check referral stats accuracy

### Offers System
1. Test coupon code uniqueness
2. Verify discount calculations for all types
3. Test usage limits (per user and total)
4. Check flash sale countdown accuracy
5. Verify offer expiration logic

### Analytics
1. Test with various date ranges
2. Verify growth calculations
3. Check forecast accuracy with historical data
4. Test with zero data scenarios

### Delivery Zones
1. Test geospatial queries accuracy
2. Verify distance calculations
3. Test zone overlap scenarios
4. Check nearby merchant sorting

---

## Performance Optimizations

### Indexes
- Referral codes: Unique sparse index
- Offer coupon codes: Unique sparse index
- Merchant location: 2dsphere index
- Order deliveredAt: Index for analytics queries

### Caching Recommendations
- Cache flash sales (5-minute TTL)
- Cache merchant analytics (15-minute TTL)
- Cache nearby merchants by location grid

### Query Optimizations
- Use aggregation pipelines for analytics
- Limit result sets with pagination
- Use projection to reduce data transfer
- Implement query result caching

---

## Security Considerations

1. **Referral System:**
   - Prevent referral code manipulation
   - Validate referrer exists before applying
   - Check for circular referrals

2. **Offers System:**
   - Validate merchant ownership before updates
   - Prevent coupon code reuse beyond limits
   - Sanitize user inputs

3. **Analytics:**
   - Restrict access to merchant's own data
   - Validate date ranges to prevent DoS
   - Rate limit analytics endpoints

4. **Delivery Zones:**
   - Validate coordinate ranges
   - Prevent excessive zone creation
   - Sanitize location data

---

## Future Enhancements

1. **Referral System:**
   - Multi-tier referral rewards
   - Referral leaderboards
   - Social media sharing integration

2. **Offers System:**
   - Smart offer recommendations
   - A/B testing for offers
   - Scheduled offer activation

3. **Analytics:**
   - Machine learning predictions
   - Competitor analysis
   - Customer segmentation

4. **Delivery Zones:**
   - Dynamic pricing based on demand
   - Route optimization
   - Real-time delivery tracking

---

## API Summary

| Feature | Endpoints | Total APIs |
|---------|-----------|------------|
| Referral System | 5 | 5 |
| Offers & Promotions | 10 | 10 |
| Merchant Analytics | 6 | 6 |
| Delivery Zones | 7 | 7 |
| **Total** | **28** | **28** |

**Grand Total APIs:** 147 (103 existing + 44 new)

---

## Support & Documentation

For detailed API documentation, refer to:
- `/backend/docs/` - Comprehensive API docs
- `/backend/COMPLETE_API_LIST.md` - Full API listing
- Postman collection (if available)

For issues or questions, contact the development team.
