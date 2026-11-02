# Delivery Agent System Documentation

## Overview

The Delivery Agent System is a comprehensive solution for managing delivery personnel, order assignments, and delivery tracking in the Green Basket platform. It features automatic assignment based on proximity, real-time status tracking, and complete admin oversight.

---

## 🏗️ Architecture

### Core Components

1. **Models**
   - `Driver` - Delivery agent profile and authentication
   - `DeliveryAssignment` - Order-to-driver assignment tracking
   - `Order` - Enhanced with delivery assignment fields

2. **Services**
   - `assignmentService` - Auto-assignment logic with Haversine distance calculation

3. **Controllers**
   - `agentAuthController` - Agent authentication and profile management
   - `agentDeliveryController` - Assignment and delivery status management
   - `adminAgentController` - Admin oversight and manual assignment

4. **Middleware**
   - `agentAuthMiddleware` - Separate JWT authentication for agents (role: 'agent')

---

## 🔐 Authentication Flow

### Agent Authentication

Delivery agents have their **own separate authentication system** that is completely independent from user/merchant/admin auth.

**Key Differences:**
- Agents use JWT tokens with `role: 'agent'`
- Separate middleware (`requireAgent`) validates agent tokens
- Cannot use customer/merchant endpoints with agent tokens
- Cannot use agent endpoints with customer/merchant tokens

### Registration Process

```javascript
POST /api/agents/register
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepass123",
  "phone": "+1234567890",
  "vehicleType": "bike",
  "vehicleNumber": "ABC123",
  "licenseNumber": "DL12345"
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "Registration successful. Your account is pending verification.",
  "data": {
    "driver": {
      "id": "...",
      "name": "John Doe",
      "email": "john@example.com",
      "isVerified": false
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Important:** New agents are created with `isVerified: false` and must be approved by an admin before they can accept deliveries.

### Login

```javascript
POST /api/agents/login
{
  "email": "john@example.com",
  "password": "securepass123"
}
```

---

## 📦 Assignment Logic

### Auto-Assignment

When an order status changes to `'confirmed'`, the system automatically attempts to assign it to the nearest available driver.

**Process:**

1. **Trigger:** Order status updated to `'confirmed'`
2. **Check:** Only for `deliveryType === 'home-delivery'`
3. **Query:** Find all drivers where:
   - `status === 'available'`
   - `isActive === true`
   - `isVerified === true`
   - Has valid `currentLocation` coordinates
4. **Calculate:** Distance from each driver to delivery address using Haversine formula
5. **Select:** Closest driver
6. **Atomic Transaction:**
   - Create `DeliveryAssignment` record
   - Update driver `status` to `'busy'`
   - Update order with `deliveryAssignment` reference
   - Set order `deliveryPersonnel` fields
7. **Graceful Fallback:** If assignment fails:
   - Set `order.needsManualAssignment = true`
   - Log warning (doesn't break order flow)
   - Admin can manually assign later

### Manual Assignment

Admins can manually assign orders to specific drivers:

```javascript
POST /api/admin/orders/:orderId/assign/:agentId
```

This is useful when:
- Auto-assignment fails (no available drivers)
- Specific driver expertise needed
- Customer requests specific driver
- Reassignment after delivery failure

---

## 📱 Agent App Workflow

### 1. Agent Goes Online

```javascript
PUT /api/agents/me/status
{
  "status": "available"
}
```

**Requirements:**
- Agent must be verified (`isVerified: true`)
- Cannot go available if account is deactivated

### 2. Update Location (Continuous)

```javascript
POST /api/agents/me/location
{
  "latitude": 12.9716,
  "longitude": 77.5946
}
```

**Best Practice:** Update location every 30-60 seconds when available/busy.

### 3. Receive Assignment

When an order is assigned, the agent can fetch it:

```javascript
GET /api/agents/assignments/current
```

**Response:**
```javascript
{
  "success": true,
  "data": {
    "assignment": {
      "_id": "...",
      "status": "assigned",
      "order": {
        "orderId": "GB1234567890",
        "totalAmount": 450,
        "deliveryAddress": {
          "fullAddress": "123 Main St, City",
          "location": {
            "coordinates": [77.5946, 12.9716]
          }
        },
        "customer": {
          "name": "Jane Smith",
          "phone": "+1234567890"
        }
      },
      "deliveryLocation": {
        "coordinates": [77.5946, 12.9716],
        "address": "123 Main St"
      },
      "estimatedDistance": 3.5,
      "deliveryFee": 40
    }
  }
}
```

### 4. Update Delivery Status

**Status Progression:**
`assigned` → `picked_up` → `in_transit` → `delivered` (or `failed`)

```javascript
PUT /api/agents/assignments/:id/status
{
  "status": "picked_up",
  "note": "Package collected from merchant",
  "latitude": 12.9716,
  "longitude": 77.5946
}
```

**Valid Transitions:**
- `assigned` → `picked_up` or `failed`
- `picked_up` → `in_transit` or `failed`
- `in_transit` → `delivered` or `failed`

### 5. Complete Delivery

```javascript
PUT /api/agents/assignments/:id/status
{
  "status": "delivered",
  "latitude": 12.9716,
  "longitude": 77.5946
}
```

**What Happens (Atomic Transaction):**
1. Assignment status → `'delivered'`
2. Order status → `'delivered'`
3. Order `deliveredAt` timestamp set
4. Driver status → `'available'`
5. Driver `totalDeliveries` incremented
6. Driver `totalEarnings` updated

### 6. Report Failure

```javascript
PUT /api/agents/assignments/:id/status
{
  "status": "failed",
  "note": "Customer not available, address incorrect"
}
```

**What Happens:**
1. Assignment status → `'failed'`
2. Order `needsManualAssignment` → `true`
3. Order `deliveryAssignment` → `null`
4. Driver status → `'available'`
5. Admin notified for manual intervention

---

## 🛠️ Admin Management

### View All Agents

```javascript
GET /api/admin/agents?status=available&isVerified=true&page=1&limit=20
```

### Verify Agent

```javascript
PATCH /api/admin/agents/:id/verify
{
  "isVerified": true
}
```

### Deactivate Agent

```javascript
PATCH /api/admin/agents/:id/toggle-active
```

Sets `isActive: false` and forces status to `'offline'`.

### View Unassigned Orders

```javascript
GET /api/admin/orders/unassigned
```

Returns all orders with `needsManualAssignment: true`.

### Manually Assign Order

```javascript
POST /api/admin/orders/:orderId/assign/:agentId
```

### View Delivery Analytics

```javascript
GET /api/admin/agents/analytics
```

**Response:**
```javascript
{
  "drivers": {
    "total": 50,
    "active": 12,
    "busy": 8,
    "verified": 45
  },
  "deliveries": {
    "total": 1250,
    "completed": 1180,
    "failed": 20,
    "active": 50,
    "successRate": "94.40"
  },
  "unassignedOrders": 3
}
```

---

## 🔒 Security Considerations

### Role Separation

**Critical:** Agent tokens CANNOT access user/merchant endpoints and vice versa.

```javascript
// Agent token payload
{
  "id": "agent_id",
  "role": "agent",  // ← This is checked by requireAgent middleware
  "iat": 1234567890,
  "exp": 1234567890
}
```

### Ownership Validation

Agents can only update their own assignments:

```javascript
// In agentDeliveryController.updateAssignmentStatus
if (assignment.driver.toString() !== req.agent._id.toString()) {
  return res.status(403).json({
    success: false,
    message: 'You can only update your own assignments'
  });
}
```

### Transaction Safety

All critical operations use MongoDB transactions:
- Auto-assignment (create assignment + update driver status)
- Status updates (update assignment + order + driver)
- Manual assignment

If any step fails, the entire transaction rolls back.

---

## 📊 Database Schema

### Driver Model

```javascript
{
  name: String,
  email: String (unique, required),
  password: String (hashed, select: false),
  phone: String (unique, required),
  profilePhotoUrl: String,
  vehicleType: enum['bike', 'scooter', 'van', 'truck'],
  vehicleNumber: String,
  licenseNumber: String,
  status: enum['available', 'busy', 'offline'],
  currentLocation: {
    type: 'Point',
    coordinates: [longitude, latitude]
  },
  rating: Number (0-5),
  totalDeliveries: Number,
  totalEarnings: Number,
  isActive: Boolean,
  isVerified: Boolean,
  verificationDocuments: [...]
}
```

**Indexes:**
- `currentLocation` (2dsphere) - For geospatial queries
- `email` (unique)
- `phone` (unique)
- `status`, `isActive` (compound) - For finding available drivers

### DeliveryAssignment Model

```javascript
{
  order: ObjectId (ref: 'Order'),
  driver: ObjectId (ref: 'Driver'),
  status: enum['assigned', 'picked_up', 'in_transit', 'delivered', 'failed', 'cancelled'],
  assignedAt: Date,
  pickedUpAt: Date,
  inTransitAt: Date,
  deliveredAt: Date,
  failedAt: Date,
  notes: String,
  failureReason: String,
  deliveryLocation: {
    type: 'Point',
    coordinates: [longitude, latitude],
    address: String
  },
  estimatedDistance: Number (km),
  actualDistance: Number (km),
  deliveryFee: Number,
  statusHistory: [{
    status: String,
    timestamp: Date,
    location: { type: 'Point', coordinates: [] },
    note: String
  }]
}
```

### Order Model (Enhanced)

```javascript
{
  // ... existing fields ...
  deliveryAssignment: ObjectId (ref: 'DeliveryAssignment'),
  needsManualAssignment: Boolean (indexed),
  deliveryPersonnel: {
    name: String,
    phone: String,
    vehicleNumber: String,
    currentLocation: {
      lat: Number,
      lng: Number,
      updatedAt: Date
    }
  }
}
```

---

## 🚀 API Reference

### Agent Endpoints

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/agents/register` | Public | Register new agent |
| POST | `/api/agents/login` | Public | Agent login |
| GET | `/api/agents/me` | Agent | Get profile |
| PUT | `/api/agents/me` | Agent | Update profile |
| PUT | `/api/agents/me/status` | Agent | Toggle available/offline |
| POST | `/api/agents/me/location` | Agent | Update GPS location |
| GET | `/api/agents/assignments/current` | Agent | Get active assignment |
| GET | `/api/agents/assignments` | Agent | Get assignment history |
| GET | `/api/agents/assignments/:id` | Agent | Get assignment details |
| PUT | `/api/agents/assignments/:id/status` | Agent | Update delivery status |
| GET | `/api/agents/earnings` | Agent | Get earnings summary |

### Admin Endpoints

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/api/admin/agents` | Admin | List all agents |
| GET | `/api/admin/agents/analytics` | Admin | Delivery analytics |
| GET | `/api/admin/agents/:id` | Admin | Get agent details |
| GET | `/api/admin/agents/:id/assignments` | Admin | Agent assignment history |
| PATCH | `/api/admin/agents/:id/verify` | Admin | Verify/approve agent |
| PATCH | `/api/admin/agents/:id/toggle-active` | Admin | Activate/deactivate |
| POST | `/api/admin/orders/:orderId/assign/:agentId` | Admin | Manual assignment |
| GET | `/api/admin/orders/unassigned` | Admin | Unassigned orders |
| GET | `/api/admin/assignments` | Admin | All assignments |

---

## 🧪 Testing

### Test Agent Registration

```bash
curl -X POST http://localhost:6000/api/agents/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Driver",
    "email": "driver@test.com",
    "password": "test123",
    "phone": "+1234567890",
    "vehicleType": "bike"
  }'
```

### Test Auto-Assignment

1. Create an agent and verify them (admin)
2. Set agent status to 'available'
3. Update agent location
4. Create an order
5. Update order status to 'confirmed'
6. Check assignment was created automatically

---

## 🐛 Troubleshooting

### Agent Can't Go Available

**Issue:** `"Your account must be verified before you can go available"`

**Solution:** Admin must verify the agent:
```javascript
PATCH /api/admin/agents/:id/verify
{ "isVerified": true }
```

### Auto-Assignment Not Working

**Checklist:**
1. ✅ Order `deliveryType` is `'home-delivery'`
2. ✅ Order has valid `deliveryAddress` with coordinates (System attempts **auto-geocoding** if missing)
3. ✅ At least one driver is `available`, `isActive`, and `isVerified`
4. ✅ Driver has valid `currentLocation` coordinates
5. ✅ Check server logs for assignment errors

### Order Marked for Manual Assignment

**Common Reasons:**
- No available drivers
- No drivers with location data
- Delivery address has no coordinates AND auto-geocoding failed
- Auto-assignment service error

**Solution:** Use manual assignment endpoint.

---

## 📈 Future Enhancements

Potential improvements for the delivery system:

1. **Real-Time Tracking**
   - WebSocket integration for live location updates
   - Customer-facing map view
   - ETA calculations

2. **Smart Assignment**
   - Consider driver ratings
   - Load balancing
   - Route optimization
   - Multi-order batching

3. **Driver Incentives**
   - Peak hour bonuses
   - Performance rewards
   - Referral programs

4. **Advanced Analytics**
   - Delivery heatmaps
   - Performance metrics
   - Predictive demand

---

## 📝 Summary

The Delivery Agent System provides:

✅ **Separate Authentication** - Agents have their own auth flow  
✅ **Auto-Assignment** - Proximity-based with Haversine formula  
✅ **Atomic Transactions** - All critical operations are transaction-safe  
✅ **Graceful Fallback** - Failed auto-assignment doesn't break orders  
✅ **Admin Oversight** - Complete management and manual override  
✅ **Status Tracking** - Full delivery lifecycle monitoring  
✅ **Earnings Tracking** - Automatic calculation of agent earnings  

**Total APIs:** 17 (11 agent endpoints + 6 admin endpoints)

---

*Last Updated: 2026-02-17*
