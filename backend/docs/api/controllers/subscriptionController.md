# Subscription Controller Documentation

## Overview
**File**: `src/controllers/subscriptionController.js`  
**Purpose**: Manages recurring delivery subscriptions for regular customers.

## Dependencies
```javascript
const Subscription = require('../models/Subscription');
```

---

## Methods

### 1. `createSubscription(req, res)`

**Purpose**: Creates a new recurring delivery subscription.

**Access**: Authenticated users only

**Request**:
```json
{
  "merchant": "merchant_id",
  "name": "Weekly Vegetable Box",
  "frequency": "weekly",
  "items": [
    {
      "product": "product_id_1",
      "quantity": 2,
      "preparation": "whole"
    },
    {
      "product": "product_id_2",
      "quantity": 1,
      "preparation": "chopped"
    }
  ],
  "deliveryDay": "monday",
  "deliveryTime": "10:00-12:00",
  "deliveryAddress": "address_id",
  "startDate": "2024-01-22"
}
```

**Frequency Options**:
- `daily`: Every day
- `weekly`: Once per week
- `bi-weekly`: Every two weeks
- `monthly`: Once per month

**Delivery Days**:
- monday, tuesday, wednesday, thursday, friday, saturday, sunday

**Logic**:
1. Validates user authentication
2. Calculates subscription price from products
3. Creates subscription with status 'active'
4. Sets next delivery date based on frequency
5. Returns subscription details

**Response**:
```json
{
  "success": true,
  "data": {
    "_id": "subscription_id",
    "user": "user_id",
    "merchant": "merchant_id",
    "name": "Weekly Vegetable Box",
    "frequency": "weekly",
    "items": [
      {
        "product": "product_id_1",
        "quantity": 2,
        "preparation": "whole"
      }
    ],
    "deliveryDay": "monday",
    "deliveryTime": "10:00-12:00",
    "deliveryAddress": "address_id",
    "price": 450,
    "status": "active",
    "startDate": "2024-01-22T00:00:00.000Z",
    "nextDelivery": "2024-01-29T00:00:00.000Z"
  }
}
```

**Business Value**:
- **Customer Convenience**: Automated recurring orders
- **Merchant Stability**: Predictable revenue
- **Reduced Churn**: Subscription lock-in
- **Inventory Planning**: Forecast demand

---

### 2. `getMySubscriptions(req, res)`

**Purpose**: Retrieves all subscriptions for the authenticated user.

**Access**: Authenticated users only

**Request**:
```
GET /api/subscriptions/my-subscriptions
```

**Logic**:
1. Finds all subscriptions for user
2. Populates merchant details
3. Populates product details for items
4. Returns subscription list

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "_id": "subscription_id",
      "name": "Weekly Vegetable Box",
      "merchant": {
        "businessName": "Green Valley Farm",
        "profileImage": "https://..."
      },
      "items": [
        {
          "product": {
            "name": "Organic Tomatoes",
            "primaryImage": "https://...",
            "price": 60
          },
          "quantity": 2
        }
      ],
      "frequency": "weekly",
      "deliveryDay": "monday",
      "price": 450,
      "status": "active",
      "nextDelivery": "2024-01-29T00:00:00.000Z"
    },
    {
      "_id": "subscription_id_2",
      "name": "Daily Milk Delivery",
      "frequency": "daily",
      "status": "paused",
      "pausedUntil": "2024-02-01T00:00:00.000Z"
    }
  ]
}
```

**Use Cases**:
- User dashboard subscription management
- View upcoming deliveries
- Manage active subscriptions

---

### 3. `updateSubscriptionStatus(req, res)`

**Purpose**: Pause, resume, or cancel a subscription.

**Access**: Authenticated users only (own subscriptions)

**Request**:
```json
{
  "status": "paused",
  "pausedUntil": "2024-02-01"
}
```

**Status Options**:
- `active`: Subscription is running
- `paused`: Temporarily stopped
- `cancelled`: Permanently stopped

**Logic**:
1. Finds subscription by ID
2. Validates user ownership
3. Updates status
4. If paused, sets `pausedUntil` date
5. Returns updated subscription

**Response**:
```json
{
  "success": true,
  "message": "Subscription paused",
  "data": {
    "_id": "subscription_id",
    "status": "paused",
    "pausedUntil": "2024-02-01T00:00:00.000Z"
  }
}
```

**Business Rules**:
- **Pause**: Temporarily stop deliveries (vacation mode)
- **Resume**: Reactivate paused subscription
- **Cancel**: Permanent termination (can't be undone)

---

## Subscription Model Schema

```javascript
{
  user: ObjectId,              // Customer
  merchant: ObjectId,          // Merchant providing products
  name: String,                // Subscription name
  frequency: String,           // daily, weekly, bi-weekly, monthly
  items: [{
    product: ObjectId,
    quantity: Number,
    preparation: String
  }],
  deliveryDay: String,         // monday-sunday (for weekly/bi-weekly)
  deliveryTime: String,        // Time slot
  deliveryAddress: ObjectId,   // Delivery address
  price: Number,               // Total subscription price
  status: String,              // active, paused, cancelled
  startDate: Date,             // Subscription start
  nextDelivery: Date,          // Next scheduled delivery
  pausedUntil: Date,           // Resume date if paused
  createdAt: Date,
  updatedAt: Date
}
```

---

## Subscription Processing (Cron Job)

The subscription system requires a cron job to process deliveries:

```javascript
// cron/subscriptionCron.js
const cron = require('node-cron');
const Subscription = require('../models/Subscription');
const Order = require('../models/Order');

// Run daily at 2 AM
cron.schedule('0 2 * * *', async () => {
  console.log('Processing subscriptions...');
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  // Find subscriptions due today
  const dueSubscriptions = await Subscription.find({
    status: 'active',
    nextDelivery: {
      $lte: today
    }
  }).populate('items.product');
  
  for (let subscription of dueSubscriptions) {
    try {
      // Create order from subscription
      const order = await Order.create({
        customer: subscription.user,
        merchant: subscription.merchant,
        items: subscription.items.map(item => ({
          product: item.product._id,
          name: item.product.name,
          price: item.product.price,
          quantity: item.quantity,
          preparation: item.preparation,
          subtotal: item.product.price * item.quantity
        })),
        totalAmount: subscription.price,
        deliveryAddress: subscription.deliveryAddress,
        deliveryType: 'home-delivery',
        paymentMethod: 'auto-pay', // Saved payment method
        isSubscriptionOrder: true,
        subscription: subscription._id
      });
      
      // Update next delivery date
      subscription.nextDelivery = calculateNextDelivery(
        subscription.frequency,
        subscription.deliveryDay
      );
      await subscription.save();
      
      // Send notification
      await notificationService.createNotification({
        recipient: subscription.user,
        recipientModel: 'User',
        type: 'order',
        title: 'Subscription Order Created',
        message: `Your ${subscription.name} order has been placed`
      });
      
      console.log(`Created order for subscription: ${subscription._id}`);
    } catch (error) {
      console.error(`Error processing subscription ${subscription._id}:`, error);
      // TODO: Notify user of failed subscription
    }
  }
});

const calculateNextDelivery = (frequency, deliveryDay) => {
  const today = new Date();
  
  switch (frequency) {
    case 'daily':
      return new Date(today.setDate(today.getDate() + 1));
    
    case 'weekly':
      return getNextWeekday(deliveryDay);
    
    case 'bi-weekly':
      return new Date(today.setDate(today.getDate() + 14));
    
    case 'monthly':
      return new Date(today.setMonth(today.getMonth() + 1));
  }
};

const getNextWeekday = (dayName) => {
  const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  const targetDay = days.indexOf(dayName.toLowerCase());
  const today = new Date();
  const currentDay = today.getDay();
  
  let daysUntilTarget = targetDay - currentDay;
  if (daysUntilTarget <= 0) {
    daysUntilTarget += 7;
  }
  
  return new Date(today.setDate(today.getDate() + daysUntilTarget));
};
```

---

## Subscription Lifecycle

```
User                    System                      Cron Job
  |                        |                            |
  |--[Create Sub]--------->|                            |
  |<--[Sub Created]--------|                            |
  |                        |                            |
  |                        |<--[Daily Check]------------|
  |                        |--[Find Due Subs]           |
  |                        |--[Create Order]            |
  |                        |--[Update Next Date]        |
  |<--[Notification]-------|                            |
  |                        |                            |
  |--[Pause Sub]---------->|                            |
  |<--[Paused]-------------|                            |
  |                        |                            |
  |                        |<--[Daily Check]------------|
  |                        |--[Skip Paused]             |
  |                        |                            |
  |--[Resume Sub]--------->|                            |
  |<--[Active]-------------|                            |
```

---

## API Endpoints Summary

| Method | Endpoint | Purpose | Access |
|--------|----------|---------|--------|
| POST | `/api/subscriptions` | Create subscription | User |
| GET | `/api/subscriptions/my-subscriptions` | Get user subscriptions | User |
| PATCH | `/api/subscriptions/:id/status` | Update status | User |

---

## Payment Integration

Subscriptions require saved payment methods:

```javascript
// Future enhancement
const processSubscriptionPayment = async (subscription, order) => {
  const user = await User.findById(subscription.user);
  
  if (!user.savedPaymentMethod) {
    throw new Error('No saved payment method');
  }
  
  // Charge saved card
  const payment = await paymentService.chargeCard({
    customerId: user.paymentCustomerId,
    amount: subscription.price,
    orderId: order._id
  });
  
  if (payment.status === 'success') {
    order.paymentStatus = 'paid';
    await order.save();
  } else {
    // Retry logic or notify user
    await notificationService.createNotification({
      recipient: user._id,
      type: 'payment',
      title: 'Subscription Payment Failed',
      message: 'Please update your payment method'
    });
  }
};
```

---

## Future Enhancements

1. **Flexible Schedules**: Custom delivery dates
2. **Item Swapping**: Change products in subscription
3. **Quantity Adjustment**: Modify quantities
4. **Skip Delivery**: Skip specific dates
5. **Subscription Tiers**: Bronze, Silver, Gold plans
6. **Discount Pricing**: Subscription discounts
7. **Gift Subscriptions**: Send to others
8. **Trial Periods**: Free first delivery
9. **Analytics**: Subscription metrics
10. **Smart Recommendations**: Suggest products based on history
