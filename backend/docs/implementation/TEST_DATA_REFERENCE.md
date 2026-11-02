# Test Data Seeder - Reference Guide

## ✅ Successfully Seeded!

The database has been populated with comprehensive test data for the Green Basket application.

## 📊 Data Summary

| Entity | Count | Details |
|--------|-------|---------|
| **Admins** | 1 | Super admin with full permissions |
| **Users** | 3 | Regular customers with different loyalty tiers |
| **Addresses** | 3 | Delivery addresses for users |
| **Merchants** | 3 | 2 approved, 1 pending verification |
| **Categories** | 5 | Vegetables, Fruits, Spices, Dairy, Grains |
| **Products** | 12 | Mix of vegetables, fruits, spices, and dairy |
| **Recipes** | 2 | Vegetable Curry and Spinach Soup |

---

## 🔐 Test Credentials

### Admin Account
- **Email**: `admin@greenbasket.com`
- **Password**: `admin123`
- **Role**: Super Admin
- **Permissions**: All (manage-users, manage-merchants, manage-products, manage-orders, manage-content, view-analytics)

### User Accounts

#### User 1 (Silver Tier)
- **Email**: `user@example.com`
- **Password**: `password123`
- **Name**: John Doe
- **Phone**: 9876543210
- **Loyalty Points**: 250
- **Loyalty Tier**: Silver
- **Dietary Preferences**: Vegetarian, Organic-only
- **Addresses**: 2 (Home, Office)

#### User 2 (Gold Tier)
- **Email**: `jane@example.com`
- **Password**: `password123`
- **Name**: Jane Smith
- **Phone**: 9876543211
- **Loyalty Points**: 500
- **Loyalty Tier**: Gold
- **Dietary Preferences**: Non-vegetarian
- **Addresses**: 1 (Home)

#### User 3 (Bronze Tier)
- **Email**: `rahul@example.com`
- **Password**: `password123`
- **Name**: Rahul Kumar
- **Phone**: 9876543212
- **Loyalty Points**: 100
- **Loyalty Tier**: Bronze
- **Dietary Preferences**: Vegetarian, Gluten-free

### Merchant Accounts

#### Merchant 1 (Approved)
- **Email**: `merchant@example.com`
- **Password**: `password123`
- **Business Name**: Green Valley Farms
- **Type**: Organic Farmer
- **Status**: Approved
- **Store**: Open
- **Location**: Bangalore (77.5946, 12.9716)
- **Delivery Radius**: 15 km
- **Minimum Order**: ₹200
- **Delivery Charges**: ₹40

#### Merchant 2 (Approved)
- **Email**: `priya@example.com`
- **Password**: `password123`
- **Business Name**: Fresh Harvest
- **Type**: Local Farmer
- **Status**: Approved
- **Store**: Open
- **Location**: Bangalore (77.6088, 12.9698)
- **Delivery Radius**: 10 km
- **Minimum Order**: ₹150
- **Delivery Charges**: ₹30

#### Merchant 3 (Pending)
- **Email**: `pending@example.com`
- **Password**: `password123`
- **Business Name**: New Farm
- **Type**: Home Grower
- **Status**: **Pending Verification**
- **Store**: Closed

---

## 📦 Products Catalog

### Vegetables (6 products)

| Product | Merchant | Price | Stock | Tags |
|---------|----------|-------|-------|------|
| Organic Tomatoes | Green Valley Farms | ₹60/kg | 100 | organic, farm-fresh, best-seller |
| Organic Ooty Carrot | Green Valley Farms | ₹70/kg | 80 | organic, farm-fresh |
| Potato | Green Valley Farms | ₹40/kg | 200 | organic, farm-fresh |
| Onions | Fresh Harvest | ₹50/kg | 150 | farm-fresh, best-seller |
| Spinach | Fresh Harvest | ₹30/bundle | 50 | organic, farm-fresh |
| Broccoli | Green Valley Farms | ₹80/kg | **5** ⚠️ | organic, seasonal |

### Fruits (3 products)

| Product | Merchant | Price | Stock | Tags | Status |
|---------|----------|-------|-------|------|--------|
| Red Delicious Apple | Green Valley Farms | ₹180/kg | 50 | seasonal, best-seller | Active |
| Banana | Fresh Harvest | ₹50/dozen | 100 | farm-fresh, best-seller | Active |
| Mango (Alphonso) | Green Valley Farms | ₹300/kg | 30 | seasonal, best-seller | **Coming Soon** |

### Spices (2 products)

| Product | Merchant | Price | Stock | Tags |
|---------|----------|-------|-------|------|
| Turmeric Powder | Green Valley Farms | ₹120/g | 60 | organic |
| Chilli Powder | Fresh Harvest | ₹100/g | 70 | organic |

### Dairy (1 product)

| Product | Merchant | Price | Stock | Tags |
|---------|----------|-------|-------|------|
| Fresh Milk | Fresh Harvest | ₹60/liter | 40 | farm-fresh |

---

## 🍳 Recipes

### Recipe 1: Vegetable Curry
- **Cuisine**: South Indian
- **Category**: Lunch
- **Difficulty**: Medium
- **Servings**: 4
- **Prep Time**: 20 min
- **Cook Time**: 30 min
- **Total Time**: 50 min
- **Dietary Tags**: Vegetarian, Vegan, Gluten-free
- **Ingredients**:
  - Carrots (200g)
  - Potatoes (300g)
  - Tomatoes (200g)
  - Onions (150g)
- **Steps**: 6 instructions

### Recipe 2: Spinach Soup
- **Cuisine**: Continental
- **Category**: Dinner
- **Difficulty**: Easy
- **Servings**: 2
- **Prep Time**: 10 min
- **Cook Time**: 15 min
- **Total Time**: 25 min
- **Dietary Tags**: Vegetarian, Gluten-free
- **Ingredients**:
  - Spinach (2 pieces)
  - Onions (100g)
- **Steps**: 5 instructions

---

## 🏷️ Categories

1. **Vegetables** - Fresh organic vegetables
2. **Fruits** - Seasonal fresh fruits
3. **Spices** - Aromatic spices
4. **Dairy** - Fresh dairy products
5. **Grains** - Organic grains and pulses

---

## 📍 Addresses

### John Doe's Addresses

#### Home (Default)
- **Label**: Home
- **Address**: 123 Main Street, Apartment 4B
- **Landmark**: Near City Hospital
- **City**: Bangalore
- **State**: Karnataka
- **Pincode**: 560001
- **Coordinates**: [77.5946, 12.9716]

#### Office
- **Label**: Office
- **Address**: 456 Tech Park
- **City**: Bangalore
- **State**: Karnataka
- **Pincode**: 560100

### Jane Smith's Address

#### Home (Default)
- **Label**: Home
- **Address**: 789 Park Avenue
- **City**: Bangalore
- **State**: Karnataka
- **Pincode**: 560002

---

## 🧪 Testing Scenarios

### 1. Admin Workflows
- ✅ Login as admin
- ✅ View pending merchant (pending@example.com)
- ✅ Approve/reject merchant
- ✅ View platform statistics
- ✅ Manage users (block/unblock)

### 2. User Workflows
- ✅ Login as user
- ✅ Browse products by category
- ✅ Search products
- ✅ Add products to cart
- ✅ View recipes
- ✅ Calculate recipe ingredients for different servings
- ✅ Add recipe ingredients to cart
- ✅ Place order
- ✅ Manage addresses
- ✅ Update profile

### 3. Merchant Workflows
- ✅ Login as merchant
- ✅ View dashboard stats
- ✅ Manage products (CRUD)
- ✅ Update stock levels
- ✅ Toggle store status
- ✅ View orders
- ✅ Update order status

### 4. Product Features
- ✅ Filter by category
- ✅ Filter by merchant
- ✅ Search functionality
- ✅ View product details
- ✅ Low stock alerts (Broccoli has only 5 units)
- ✅ Coming soon products (Mango)
- ✅ Seasonal products

### 5. Recipe Features
- ✅ Browse recipes
- ✅ View recipe details
- ✅ Calculate ingredients for custom servings
- ✅ Add recipe to cart (auto-calculate quantities)

---

## 🔄 Running the Seeder

### Import Data (Default)
```bash
node src/utils/seeder.js
```

### Destroy All Data
```bash
node src/utils/seeder.js -d
```

---

## ⚠️ Important Notes

1. **Low Stock Alert**: Broccoli has only 5 units (threshold: 10) - test low stock notifications
2. **Pending Merchant**: One merchant is pending approval - test admin verification workflow
3. **Coming Soon Product**: Mango is marked as "coming-soon" - test product status filtering
4. **Multiple Merchants**: Products from 2 different merchants - test multi-merchant scenarios
5. **Loyalty Tiers**: Users have different loyalty tiers (Bronze, Silver, Gold) - test tier-based features

---

## 🎯 Next Steps

1. **Start the server**: `npm run dev`
2. **Test API endpoints** using the credentials above
3. **Create orders** to test order workflow
4. **Add reviews** after order delivery
5. **Test real-time notifications** (Socket.IO)
6. **Test subscription features** (create recurring orders)

---

## 📝 Customization

To modify the test data, edit `/backend/src/utils/seeder.js` and run the seeder again.

**Last Updated**: February 9, 2024  
**Database**: MongoDB (localhost:27017/greenbasket)
