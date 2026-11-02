# Order Controller Documentation

## Overview
**File**: `src/controllers/orderController.js`  
**Purpose**: Central hub for order lifecycle management, from creation to delivery, with real-time Socket.IO integration.

## Dependencies
```javascript
const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Product = require('../models/Product');
const OrderSocket = require('../sockets/orderSocket');
const notificationService = require('../services/notificationService');
const mongoose = require('mongoose');
```

---

## Methods

### 1. `createOrder(req, res)` 🔥

**Purpose**: Creates a new order, processes payment, updates inventory, and notifies merchant in real-time.

**Access**: Authenticated users only

**Request**:
```json
{
  "items": [
    {
      "product": "product_id_123",
      "quantity": 2,
      "preparation": "chopped"
    },
    {
      "product": "product_id_456",
      "quantity": 1,
      "preparation": "whole"
    }
  ],
  "deliveryAddress": "address_id_789",
  "deliveryType": "home-delivery", // or "pickup"
  "paymentMethod": "cod", // or "online", "wallet"
  "deliveryTimeSlot": {
    "date": "2024-01-25",
    "startTime": "10:00",
    "endTime": "12:00"
  },
  "specialRequests": "Please ring the doorbell twice",
  "couponCode": "FIRST10"
}
```

**Logic Flow**:

1. **Item Validation & Calculation**:
   ```javascript
   for (let item of items) {
     - Fetch product details
     - Verify product exists
     - Check stock availability
     - Calculate subtotal (price × quantity)
     - Build order items array
     - Decrement product stock
     - Increment totalSales counter
   }
   ```

2. **Merchant Identification**:
   - Gets merchant from first product
   - All items must be from same merchant (current limitation)

3. **Price Calculation**:
   ```javascript
   itemsTotal = sum of all subtotals
   deliveryCharges = deliveryType === 'pickup' ? 0 : 40
   discount = coupon logic (TODO)
   totalAmount = itemsTotal + deliveryCharges - discount
   ```

4. **Order Creation**:
   - Generates unique `orderId` (via model pre-save hook)
   - Sets initial status to 'pending'
   - Stores all order details

5. **Cart Cleanup**:
   - Clears user's cart after successful order

6. **Real-Time Notification** 🔔:
   ```javascript
   OrderSocket.notifyNewOrder(merchantId, {
     orderId, customerName, totalAmount, itemsCount
   });
   ```

7. **Database Notification**:
   ```javascript
   notificationService.createNotification({
     recipient: merchantId,
     type: 'order',
     title: 'New Order Received',
     message: `New order ${orderId} from ${customerName}`
   });
   ```

**Response**:
```json
{
  "success": true,
  "message": "Order placed successfully",
  "data": {
    "order": {
      "orderId": "GB1706001234567",
      "customer": "user_id",
      "merchant": "merchant_id",
      "items": [...],
      "totalAmount": 540,
      "status": "pending",
      "paymentMethod": "cod",
      "deliveryType": "home-delivery"
    }
  }
}
```

**Error Handling**:
- 404: Product not found
- 400: Insufficient stock
- 500: Order creation failed

**Business Impact**:
- Inventory automatically updated
- Merchant receives instant notification
- Customer cart cleared for new shopping
- Order tracking begins

---

### 2. `getMyOrders(req, res)`

**Purpose**: Retrieves customer's order history with pagination.

**Access**: Authenticated users only

**Request**:
- Query Parameters:
  - `page` (default: 1)
  - `limit` (default: 10)
  - `status` (optional filter)

**Response**:
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "orderId": "GB1706001234567",
        "merchant": {
          "businessName": "Green Valley Farm",
          "profileImage": "https://..."
        },
        "items": [
          {
            "product": {
              "name": "Organic Tomatoes",
              "primaryImage": "https://..."
            },
            "quantity": 2,
            "price": 60
          }
        ],
        "totalAmount": 540,
        "status": "delivered",
        "createdAt": "2024-01-20T10:30:00.000Z"
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

**Features**:
- Sorted by most recent first
- Populated merchant and product details
- Status filtering for order tracking

---

### 3. `getMerchantOrders(req, res)`

**Purpose**: Retrieves all orders for a merchant with customer details.

**Access**: Authenticated merchants only

**Request**:
- Query Parameters: `page`, `limit`, `status`

**Response**:
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "orderId": "GB1706001234567",
        "customer": {
          "name": "John Doe",
          "phone": "9876543210",
          "profileImage": "https://..."
        },
        "deliveryAddress": {
          "addressLine1": "123 Main St",
          "city": "Bangalore",
          "pincode": "560001"
        },
        "items": [...],
        "totalAmount": 540,
        "status": "pending",
        "paymentMethod": "cod"
      }
    ],
    "pagination": {...}
  }
}
```

**Use Cases**:
- Merchant dashboard order list
- Order fulfillment queue
- Revenue tracking

---

### 4. `updateOrderStatus(req, res)` 🔔

**Purpose**: Merchant updates order status with real-time customer notification.

**Access**: Authenticated merchants only

**Request**:
```json
{
  "status": "preparing", // confirmed, preparing, ready, out-for-delivery, delivered
  "note": "Your order is being freshly prepared"
}
```

**Status Flow**:
```
pending → confirmed → preparing → ready → out-for-delivery → delivered
                                    ↓
                                cancelled
```

**Logic Flow**:
1. Validates merchant owns the order
2. Updates status using order model method
3. Updates timestamps (confirmedAt, deliveredAt)
4. **Real-Time Update**:
   ```javascript
   OrderSocket.notifyOrderStatusUpdate(customerId, {
     orderId, status, statusMessage
   });
   ```
5. Creates notification in database
6. Returns updated order

**Response**:
```json
{
  "success": true,
  "message": "Order status updated",
  "data": {
    "order": {
      "status": "preparing",
      "statusHistory": [
        {
          "status": "pending",
          "timestamp": "2024-01-20T10:30:00.000Z",
          "updatedBy": "system"
        },
        {
          "status": "confirmed",
          "timestamp": "2024-01-20T10:35:00.000Z",
          "updatedBy": "merchant_id",
          "note": "Order confirmed"
        },
        {
          "status": "preparing",
          "timestamp": "2024-01-20T10:40:00.000Z",
          "updatedBy": "merchant_id",
          "note": "Your order is being freshly prepared"
        }
      ]
    }
  }
}
```

**Status Messages**:
```javascript
const getStatusMessage = (status) => ({
  'confirmed': 'Your order has been confirmed',
  'preparing': 'Your order is being prepared',
  'ready': 'Your order is ready for pickup/delivery',
  'out-for-delivery': 'Your order is out for delivery',
  'delivered': 'Your order has been delivered',
  'cancelled': 'Your order has been cancelled'
}[status]);
```

---

### 5. `getOrderById(req, res)`

**Purpose**: Fetches detailed information for a specific order.

**Access**: Authenticated users (customer/merchant/admin)

**Response**:
```json
{
  "success": true,
  "data": {
    "order": {
      "orderId": "GB1706001234567",
      "customer": {
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "9876543210"
      },
      "merchant": {
        "businessName": "Green Valley Farm",
        "phone": "9876543211"
      },
      "items": [...],
      "deliveryAddress": {...},
      "statusHistory": [...],
      "totalAmount": 540,
      "paymentStatus": "paid"
    }
  }
}
```

**Populated Fields**:
- Customer details
- Merchant details
- Product information
- Delivery address

---

### 6. `cancelOrder(req, res)`

**Purpose**: Customer cancels an order with stock restoration.

**Access**: Authenticated users only

**Request**:
```json
{
  "reason": "Changed my mind"
}
```

**Logic Flow**:
1. Validates order belongs to customer
2. Checks if cancellation is allowed:
   - Not allowed if status is 'delivered' or already 'cancelled'
3. Updates order status to 'cancelled'
4. Stores cancellation details
5. **Restores Stock**:
   ```javascript
   for (let item of order.items) {
     Product.findByIdAndUpdate(item.product, {
       $inc: { stock: item.quantity }
     });
   }
   ```
6. Notifies merchant via Socket.IO
7. Returns updated order

**Response**:
```json
{
  "success": true,
  "message": "Order cancelled successfully",
  "data": {
    "order": {
      "status": "cancelled",
      "cancellationReason": "Changed my mind",
      "cancelledBy": "customer",
      "cancelledAt": "2024-01-20T11:00:00.000Z"
    }
  }
}
```

**Business Rules**:
- Can only cancel before delivery
- Stock is restored immediately
- Merchant is notified for refund processing
- Cancellation reason tracked for analytics

---

### 7. `addReview(req, res)`

**Purpose**: Customer adds rating and review after order delivery.

**Access**: Authenticated users only

**Request**:
```json
{
  "productId": "product_id_123",
  "rating": 5,
  "comment": "Fresh and high quality vegetables!",
  "images": ["https://review-image1.jpg"]
}
```

**Logic Flow**:
1. Validates order belongs to customer
2. Checks order status is 'delivered'
3. Validates product is in the order
4. Creates Review document
5. Recalculates product average rating
6. Updates order with review status

**Response**:
```json
{
  "success": true,
  "data": {
    "order": {
      "rating": 5,
      "review": "Fresh and high quality vegetables!",
      "reviewedAt": "2024-01-25T10:00:00.000Z"
    }
  }
}
```

**Rating Calculation**:
```javascript
const stats = await Review.aggregate([
  { $match: { product: productId } },
  { 
    $group: { 
      _id: '$product', 
      nRating: { $sum: 1 }, 
      avgRating: { $avg: '$rating' } 
    } 
  }
]);

await Product.findByIdAndUpdate(productId, {
  averageRating: stats[0].avgRating,
  totalReviews: stats[0].nRating
});
```

---

## Real-Time Features (Socket.IO)

### New Order Notification
```javascript
// Merchant receives instant notification
socket.on('new_order', (data) => {
  // data: { orderId, customerName, totalAmount, itemsCount }
  showNotification('New Order!', data);
  playSound('new-order.mp3');
  updateOrderCount();
});
```

### Order Status Update
```javascript
// Customer receives real-time updates
socket.on('order_status_update', (data) => {
  // data: { orderId, status, statusMessage }
  updateOrderTracking(data);
  showToast(data.statusMessage);
});
```

### Order Cancellation
```javascript
// Merchant notified of cancellation
socket.on('order_cancelled', (data) => {
  // data: { orderId, reason }
  updateOrderList();
  showCancellationAlert(data);
});
```

---

## Order Lifecycle Diagram

```
Customer                    System                      Merchant
   |                          |                            |
   |--[Create Order]--------->|                            |
   |                          |--[Stock Check]             |
   |                          |--[Create Order]            |
   |                          |--[Clear Cart]              |
   |                          |--[Socket: New Order]------>|
   |                          |                            |
   |                          |<--[Confirm Order]----------|
   |<--[Socket: Confirmed]----|                            |
   |                          |                            |
   |                          |<--[Update: Preparing]------|
   |<--[Socket: Preparing]----|                            |
   |                          |                            |
   |                          |<--[Update: Ready]----------|
   |<--[Socket: Ready]--------|                            |
   |                          |                            |
   |                          |<--[Update: Delivered]------|
   |<--[Socket: Delivered]----|                            |
   |                          |                            |
   |--[Add Review]----------->|                            |
   |                          |--[Update Product Rating]   |
```

---

## API Endpoints Summary

| Method | Endpoint | Purpose | Access |
|--------|----------|---------|--------|
| POST | `/api/orders` | Create order | User |
| GET | `/api/orders/my-orders` | Get customer orders | User |
| GET | `/api/orders/merchant/orders` | Get merchant orders | Merchant |
| GET | `/api/orders/:id` | Get order details | User/Merchant |
| PATCH | `/api/orders/:id/cancel` | Cancel order | User |
| PATCH | `/api/orders/merchant/:id/status` | Update status | Merchant |
| POST | `/api/orders/:id/review` | Add review | User |

---

## Performance Optimizations

1. **Parallel Stock Updates**: Use bulk operations
2. **Cached Product Data**: Reduce DB queries
3. **Indexed Queries**: Status and merchant fields
4. **Pagination**: Limit result sets
5. **Socket.IO Rooms**: Efficient real-time delivery

---

## Future Enhancements

1. **Order Tracking**: GPS-based delivery tracking
2. **Estimated Delivery**: ML-based time predictions
3. **Partial Fulfillment**: Split orders for availability
4. **Recurring Orders**: Subscription-based ordering
5. **Order Modification**: Change items before confirmation
6. **Multi-Merchant Orders**: Cart splitting
7. **Advanced Analytics**: Order patterns, peak times
