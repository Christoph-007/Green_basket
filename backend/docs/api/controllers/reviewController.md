# Review Controller Documentation

## Overview
**File**: `src/controllers/reviewController.js`  
**Purpose**: Manages product and merchant reviews, including retrieval and moderation.

## Dependencies
```javascript
const Review = require('../models/Review');
```

---

## Methods

### 1. `getProductReviews(req, res)`

**Purpose**: Fetches paginated reviews for a specific product.

**Access**: Public

**Request**:
```
GET /api/reviews/product/:productId?page=1&limit=10
```

**Query Parameters**:
- `page` (default: 1)
- `limit` (default: 10)

**Logic**:
1. Finds reviews for the product
2. Only shows verified reviews (`isVerified: true`)
3. Populates customer details (name, profile image)
4. Sorts by most recent first
5. Implements pagination

**Response**:
```json
{
  "success": true,
  "data": {
    "reviews": [
      {
        "_id": "review_id",
        "customer": {
          "name": "John Doe",
          "profileImage": "https://..."
        },
        "product": "product_id",
        "rating": 5,
        "comment": "Excellent quality! Fresh and organic.",
        "images": [
          "https://cloudinary.com/review1.jpg"
        ],
        "isVerified": true,
        "helpfulCount": 12,
        "merchantReply": {
          "comment": "Thank you for your feedback!",
          "repliedAt": "2024-01-21T10:00:00.000Z"
        },
        "createdAt": "2024-01-20T15:30:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 45,
      "pages": 5
    }
  }
}
```

**Use Cases**:
- Product detail page reviews section
- Customer decision-making
- Social proof display

---

### 2. `getMerchantReviews(req, res)`

**Purpose**: Fetches all reviews for a merchant's products.

**Access**: Public

**Request**:
```
GET /api/reviews/merchant/:merchantId?page=1&limit=10
```

**Logic**:
1. Finds all reviews linked to merchant
2. Populates customer and product details
3. Only verified reviews
4. Sorted by most recent

**Response**:
```json
{
  "success": true,
  "data": {
    "reviews": [
      {
        "_id": "review_id",
        "customer": {
          "name": "Jane Smith",
          "profileImage": "https://..."
        },
        "product": {
          "name": "Organic Tomatoes",
          "images": ["https://..."]
        },
        "merchant": "merchant_id",
        "rating": 4,
        "comment": "Good quality, delivered on time",
        "isVerified": true,
        "createdAt": "2024-01-19T12:00:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 120,
      "pages": 12
    }
  }
}
```

**Use Cases**:
- Merchant profile page
- Overall merchant rating calculation
- Merchant dashboard feedback section

---

### 3. `deleteReview(req, res)`

**Purpose**: Removes a review (moderation or user deletion).

**Access**: Admin or review author

**Request**:
```
DELETE /api/reviews/:id
```

**Logic**:
1. Finds review by ID
2. **Authorization Check**:
   ```javascript
   if (req.userType !== 'admin' && 
       review.customer.toString() !== req.user.id.toString()) {
     return res.status(403).json({
       message: 'Not authorized to delete this review'
     });
   }
   ```
3. Deletes review
4. TODO: Update product average rating

**Response**:
```json
{
  "success": true,
  "message": "Review deleted successfully"
}
```

**Business Rules**:
- Users can delete their own reviews
- Admins can delete any review (moderation)
- Merchants cannot delete reviews (prevents censorship)

**Post-Deletion Actions** (TODO):
```javascript
// Recalculate product rating
const stats = await Review.aggregate([
  { $match: { product: review.product } },
  { $group: { 
      _id: '$product', 
      avgRating: { $avg: '$rating' },
      count: { $sum: 1 }
  }}
]);

await Product.findByIdAndUpdate(review.product, {
  averageRating: stats[0]?.avgRating || 0,
  totalReviews: stats[0]?.count || 0
});
```

---

## Review Model Schema

```javascript
{
  order: ObjectId,           // Linked order (ensures verified purchase)
  customer: ObjectId,        // User who wrote review
  merchant: ObjectId,        // Merchant being reviewed
  product: ObjectId,         // Product being reviewed
  rating: Number,            // 1-5 stars
  comment: String,           // Review text
  images: [String],          // Photo reviews
  isVerified: Boolean,       // Auto-verified if from order
  helpfulCount: Number,      // Upvotes from other users
  merchantReply: {
    comment: String,
    repliedAt: Date
  },
  createdAt: Date
}
```

---

## Review Creation Flow

Reviews are typically created via `orderController.addReview()`:

```javascript
// In orderController.js
exports.addReview = async (req, res) => {
  const { productId, rating, comment, images } = req.body;
  
  // Validate order is delivered
  if (order.status !== 'delivered') {
    return res.status(400).json({
      message: 'Can only review delivered orders'
    });
  }
  
  // Create review
  const review = await Review.create({
    order: orderId,
    customer: userId,
    merchant: order.merchant,
    product: productId,
    rating,
    comment,
    images,
    isVerified: true  // Auto-verified from order
  });
  
  // Update product rating
  const stats = await Review.aggregate([...]);
  await Product.findByIdAndUpdate(productId, {
    averageRating: stats[0].avgRating,
    totalReviews: stats[0].nRating
  });
};
```

---

## Rating Calculation

### Product Average Rating

```javascript
const calculateProductRating = async (productId) => {
  const stats = await Review.aggregate([
    { $match: { product: new mongoose.Types.ObjectId(productId) } },
    { 
      $group: { 
        _id: '$product', 
        avgRating: { $avg: '$rating' },
        totalReviews: { $sum: 1 },
        ratingDistribution: {
          $push: '$rating'
        }
      } 
    }
  ]);
  
  return {
    averageRating: stats[0]?.avgRating.toFixed(1) || 0,
    totalReviews: stats[0]?.totalReviews || 0,
    distribution: calculateDistribution(stats[0]?.ratingDistribution)
  };
};

const calculateDistribution = (ratings) => {
  return {
    5: ratings.filter(r => r === 5).length,
    4: ratings.filter(r => r === 4).length,
    3: ratings.filter(r => r === 3).length,
    2: ratings.filter(r => r === 2).length,
    1: ratings.filter(r => r === 1).length
  };
};
```

### Merchant Average Rating

```javascript
const calculateMerchantRating = async (merchantId) => {
  const stats = await Review.aggregate([
    { $match: { merchant: new mongoose.Types.ObjectId(merchantId) } },
    { 
      $group: { 
        _id: '$merchant', 
        avgRating: { $avg: '$rating' },
        totalReviews: { $sum: 1 }
      } 
    }
  ]);
  
  await Merchant.findByIdAndUpdate(merchantId, {
    averageRating: stats[0]?.avgRating || 0,
    totalReviews: stats[0]?.totalReviews || 0
  });
};
```

---

## API Endpoints Summary

| Method | Endpoint | Purpose | Access |
|--------|----------|---------|--------|
| GET | `/api/reviews/product/:productId` | Get product reviews | Public |
| GET | `/api/reviews/merchant/:merchantId` | Get merchant reviews | Public |
| DELETE | `/api/reviews/:id` | Delete review | User/Admin |

---

## Review Display Example

```
┌────────────────────────────────────────────┐
│ ⭐⭐⭐⭐⭐ 5.0                              │
│ John Doe                    Jan 20, 2024   │
│ ✓ Verified Purchase                        │
├────────────────────────────────────────────┤
│ Excellent quality! Fresh and organic.      │
│ Delivered on time. Highly recommended.     │
│                                            │
│ [📷 Image 1] [📷 Image 2]                  │
│                                            │
│ 👍 12 people found this helpful            │
│                                            │
│ 💬 Merchant Reply:                         │
│    Thank you for your feedback!            │
│    - Green Valley Farm                     │
└────────────────────────────────────────────┘
```

---

## Future Enhancements

1. **Helpful Votes**: Users can mark reviews as helpful
   ```javascript
   exports.markHelpful = async (req, res) => {
     await Review.findByIdAndUpdate(reviewId, {
       $inc: { helpfulCount: 1 }
     });
   };
   ```

2. **Merchant Replies**: Allow merchants to respond
   ```javascript
   exports.addMerchantReply = async (req, res) => {
     const { comment } = req.body;
     await Review.findByIdAndUpdate(reviewId, {
       merchantReply: {
         comment,
         repliedAt: new Date()
       }
     });
   };
   ```

3. **Review Moderation**: Flag inappropriate reviews
4. **Photo Reviews**: Incentivize with loyalty points
5. **Review Filters**: Sort by rating, date, verified
6. **Review Analytics**: Sentiment analysis
7. **Review Reminders**: Email after delivery
8. **Review Rewards**: Points for detailed reviews
