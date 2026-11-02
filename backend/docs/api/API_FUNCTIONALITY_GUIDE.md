# Green Basket Backend - API Functionality Guide

## 📖 Complete API Functionality Explanation

This document explains **how each API works**, including business logic, data flow, and real-world usage scenarios.

---

## Table of Contents

1. [Authentication Flow](#authentication-flow)
2. [User Management](#user-management)
3. [Merchant Operations](#merchant-operations)
4. [Admin Functions](#admin-functions)
5. [Product Management](#product-management)
6. [Category System](#category-system)
7. [Shopping Cart](#shopping-cart)
8. [Order Processing](#order-processing)
9. [Recipe System](#recipe-system)
10. [Review System](#review-system)
11. [Subscription Management](#subscription-management)

---

# 1. Authentication Flow

## 🔐 How Authentication Works

### Architecture Overview
```
User/Merchant/Admin
        ↓
   Login Request
        ↓
   Validate Credentials (bcrypt)
        ↓
   Generate JWT Token
        ↓
   Return Token + User Data
        ↓
   Store Token (Frontend)
        ↓
   Use Token in Headers for Protected Routes
```

---

## 1.1 User Signup

**Endpoint:** `POST /api/auth/user/signup`

### How It Works:

1. **Receive Registration Data**
   - Name, email, password, phone number
   
2. **Validation**
   - Check if email already exists
   - Validate email format
   - Ensure password meets requirements (min 6 characters)
   - Validate phone number format

3. **Password Hashing**
   ```javascript
   // Uses bcrypt with 12 salt rounds
   hashedPassword = bcrypt.hash(password, 12)
   ```

4. **Create User Record**
   ```javascript
   user = {
     name: "John Doe",
     email: "john@example.com",
     password: hashedPassword,
     phone: "9876543210",
     isEmailVerified: false,
     loyaltyPoints: 0,
     loyaltyTier: "bronze"
   }
   ```

5. **Generate Email Verification Token**
   ```javascript
   verificationToken = JWT.sign(
     { id: user._id, email: user.email },
     SECRET,
     { expiresIn: '24h' }
   )
   ```

6. **Send Verification Email**
   - Email contains link: `frontend.com/verify-email?token=xxx`
   - User clicks link to verify email

7. **Generate Access Token**
   ```javascript
   accessToken = JWT.sign(
     { id: user._id, userType: 'user' },
     SECRET,
     { expiresIn: '15m' }
   )
   ```

8. **Return Response**
   ```json
   {
     "success": true,
     "message": "User registered successfully",
     "data": {
       "user": { ... },
       "token": "eyJhbGc..."
     }
   }
   ```

### Business Logic:
- New users start with **Bronze tier** (0 points)
- Email verification required for certain features
- Password is **never stored in plain text**
- Tokens expire after 15 minutes (security)

---

## 1.2 User Login

**Endpoint:** `POST /api/auth/user/login`

### How It Works:

1. **Receive Login Credentials**
   ```json
   {
     "email": "user@example.com",
     "password": "password123"
   }
   ```

2. **Find User by Email**
   ```javascript
   user = User.findOne({ email }).select('+password')
   // Note: password field is normally hidden
   ```

3. **Verify Password**
   ```javascript
   isMatch = await bcrypt.compare(password, user.password)
   if (!isMatch) {
     return error("Invalid credentials")
   }
   ```

4. **Check Account Status**
   ```javascript
   if (user.isBlocked) {
     return error("Account has been blocked")
   }
   ```

5. **Update Last Login**
   ```javascript
   user.lastLoginAt = new Date()
   await user.save()
   ```

6. **Generate JWT Token**
   ```javascript
   token = JWT.sign(
     { 
       id: user._id,
       userType: 'user'
     },
     JWT_SECRET,
     { expiresIn: '15m' }
   )
   ```

7. **Return User Data + Token**
   ```json
   {
     "success": true,
     "data": {
       "user": {
         "id": "...",
         "name": "John Doe",
         "email": "user@example.com",
         "loyaltyPoints": 250,
         "loyaltyTier": "silver"
       },
       "token": "eyJhbGc..."
     }
   }
   ```

### Security Features:
- ✅ Password hashing (bcrypt)
- ✅ JWT tokens with expiration
- ✅ Account blocking capability
- ✅ Last login tracking
- ✅ Password never returned in response

---

## 1.3 Merchant Login

**Endpoint:** `POST /api/auth/merchant/login`

### How It Works:

Similar to user login, but with additional checks:

1. **Verify Merchant Credentials**
2. **Check Verification Status**
   ```javascript
   if (merchant.verificationStatus !== 'approved') {
     return error("Merchant account not yet approved")
   }
   ```

3. **Check Store Status**
   ```javascript
   // Merchant can login even if store is closed
   // But certain operations require open store
   ```

4. **Generate Merchant Token**
   ```javascript
   token = JWT.sign(
     { 
       id: merchant._id,
       userType: 'merchant'
     },
     JWT_SECRET,
     { expiresIn: '15m' }
   )
   ```

### Business Logic:
- Only **approved merchants** can login
- Pending/rejected merchants get specific error messages
- Token includes `userType: 'merchant'` for authorization

---

## 1.4 Email Verification

**Endpoint:** `POST /api/auth/user/verify-email`

### How It Works:

1. **Receive Verification Token**
   ```json
   {
     "token": "eyJhbGc..."
   }
   ```

2. **Verify JWT Token**
   ```javascript
   decoded = JWT.verify(token, JWT_SECRET)
   // Contains: { id, email }
   ```

3. **Find User**
   ```javascript
   user = User.findById(decoded.id)
   ```

4. **Update Verification Status**
   ```javascript
   user.isEmailVerified = true
   user.emailVerifiedAt = new Date()
   await user.save()
   ```

5. **Return Success**
   ```json
   {
     "success": true,
     "message": "Email verified successfully"
   }
   ```

### Business Logic:
- Token expires after 24 hours
- Can resend verification email if expired
- Verified users get access to premium features

---

## 1.5 Password Reset Flow

### Step 1: Request Reset

**Endpoint:** `POST /api/auth/user/forgot-password`

**How It Works:**

1. **Receive Email**
   ```json
   {
     "email": "user@example.com"
   }
   ```

2. **Find User**
   ```javascript
   user = User.findOne({ email })
   ```

3. **Generate Reset Token**
   ```javascript
   resetToken = JWT.sign(
     { id: user._id },
     JWT_SECRET,
     { expiresIn: '1h' }
   )
   ```

4. **Send Reset Email**
   ```
   Link: frontend.com/reset-password?token=xxx
   ```

5. **Return Success** (don't reveal if email exists - security)
   ```json
   {
     "success": true,
     "message": "If email exists, reset link has been sent"
   }
   ```

### Step 2: Reset Password

**Endpoint:** `POST /api/auth/user/reset-password`

**How It Works:**

1. **Receive Token + New Password**
   ```json
   {
     "token": "eyJhbGc...",
     "newPassword": "newSecurePassword123"
   }
   ```

2. **Verify Token**
   ```javascript
   decoded = JWT.verify(token, JWT_SECRET)
   ```

3. **Hash New Password**
   ```javascript
   hashedPassword = bcrypt.hash(newPassword, 12)
   ```

4. **Update User Password**
   ```javascript
   user.password = hashedPassword
   user.passwordChangedAt = new Date()
   await user.save()
   ```

5. **Invalidate All Existing Tokens** (optional security measure)

### Security Features:
- ✅ Token expires in 1 hour
- ✅ One-time use token
- ✅ Doesn't reveal if email exists
- ✅ Password immediately hashed

---

# 2. User Management

## 👤 How User APIs Work

---

## 2.1 Get User Profile

**Endpoint:** `GET /api/users/profile`

### How It Works:

1. **Extract Token from Header**
   ```javascript
   token = req.headers.authorization.split(' ')[1]
   // Format: "Bearer eyJhbGc..."
   ```

2. **Verify Token**
   ```javascript
   decoded = JWT.verify(token, JWT_SECRET)
   // Contains: { id, userType }
   ```

3. **Check User Type**
   ```javascript
   if (decoded.userType !== 'user') {
     return error("Access denied")
   }
   ```

4. **Fetch User Data**
   ```javascript
   user = User.findById(decoded.id)
     .select('-password') // Exclude password
     .populate('addresses')
   ```

5. **Return Profile**
   ```json
   {
     "success": true,
     "data": {
       "id": "...",
       "name": "John Doe",
       "email": "user@example.com",
       "phone": "9876543210",
       "loyaltyPoints": 250,
       "loyaltyTier": "silver",
       "dietaryPreferences": ["vegetarian"],
       "allergies": ["nuts"],
       "addresses": [...]
     }
   }
   ```

### Business Logic:
- Password is **never** returned
- Loyalty tier calculated based on points:
  - Bronze: 0-499 points
  - Silver: 500-999 points
  - Gold: 1000+ points

---

## 2.2 Update User Profile

**Endpoint:** `PUT /api/users/profile`

### How It Works:

1. **Receive Update Data**
   ```json
   {
     "name": "John Updated",
     "phone": "9876543211",
     "dietaryPreferences": ["vegetarian", "organic-only"],
     "allergies": ["nuts", "dairy"]
   }
   ```

2. **Validate Data**
   - Name: min 2 characters
   - Phone: valid format
   - Dietary preferences: from allowed list
   - Allergies: from allowed list

3. **Update User**
   ```javascript
   user = User.findByIdAndUpdate(
     userId,
     updateData,
     { new: true, runValidators: true }
   )
   ```

4. **Return Updated Profile**

### Allowed Updates:
- ✅ Name
- ✅ Phone
- ✅ Profile image
- ✅ Dietary preferences
- ✅ Allergies
- ✅ Notification settings
- ❌ Email (requires verification)
- ❌ Password (use reset flow)
- ❌ Loyalty points (system managed)

---

## 2.3 Address Management

### Add Address

**Endpoint:** `POST /api/users/addresses`

**How It Works:**

1. **Receive Address Data**
   ```json
   {
     "label": "home",
     "name": "John Doe",
     "phone": "9876543210",
     "addressLine1": "123 Main Street",
     "addressLine2": "Apartment 4B",
     "landmark": "Near City Hospital",
     "city": "Bangalore",
     "state": "Karnataka",
     "pincode": "560001",
     "isDefault": true
   }
   ```

2. **Validate Address**
   - Pincode format (6 digits)
   - Required fields present
   - Valid state/city

3. **Handle Default Address**
   ```javascript
   if (isDefault) {
     // Remove default from other addresses
     await Address.updateMany(
       { user: userId, isDefault: true },
       { isDefault: false }
     )
   }
   ```

4. **Geocode Address** (optional)
   ```javascript
   // Convert address to coordinates for delivery radius check
   location = {
     type: 'Point',
     coordinates: [longitude, latitude]
   }
   ```

5. **Create Address**
   ```javascript
   address = Address.create({
     user: userId,
     ...addressData,
     location
   })
   ```

6. **Return Created Address**

### Business Logic:
- User can have **multiple addresses**
- Only **one default** address at a time
- Addresses used for:
  - Order delivery
  - Merchant distance calculation
  - Delivery fee calculation

---

# 3. Merchant Operations

## 🏪 How Merchant APIs Work

---

## 3.1 Merchant Dashboard Stats

**Endpoint:** `GET /api/merchants/dashboard-stats`

### How It Works:

1. **Authenticate Merchant**
   ```javascript
   merchantId = req.user._id // From JWT token
   ```

2. **Calculate Total Revenue**
   ```javascript
   revenue = await Order.aggregate([
     { $match: { 
       merchant: merchantId,
       status: 'delivered'
     }},
     { $group: {
       _id: null,
       total: { $sum: '$totalAmount' }
     }}
   ])
   ```

3. **Count Orders by Status**
   ```javascript
   totalOrders = await Order.countDocuments({ merchant: merchantId })
   pendingOrders = await Order.countDocuments({ 
     merchant: merchantId,
     status: 'pending'
   })
   ```

4. **Find Low Stock Products**
   ```javascript
   lowStockProducts = await Product.find({
     merchant: merchantId,
     $expr: { $lte: ['$stock', '$lowStockThreshold'] }
   })
   ```

5. **Calculate Today's Orders**
   ```javascript
   todayOrders = await Order.countDocuments({
     merchant: merchantId,
     createdAt: { $gte: startOfDay }
   })
   ```

6. **Return Dashboard Data**
   ```json
   {
     "success": true,
     "data": {
       "totalRevenue": 15000,
       "totalOrders": 45,
       "pendingOrders": 5,
       "todayOrders": 3,
       "lowStockProducts": 2,
       "averageRating": 4.5,
       "totalProducts": 25
     }
   }
   ```

### Business Logic:
- Revenue only counts **delivered orders**
- Low stock = stock ≤ lowStockThreshold
- Real-time data (no caching)
- Used for merchant decision making

---

## 3.2 Toggle Store Status

**Endpoint:** `PATCH /api/merchants/toggle-store`

### How It Works:

1. **Get Current Status**
   ```javascript
   merchant = await Merchant.findById(merchantId)
   currentStatus = merchant.isStoreOpen
   ```

2. **Toggle Status**
   ```javascript
   newStatus = !currentStatus
   merchant.isStoreOpen = newStatus
   await merchant.save()
   ```

3. **Notify Customers** (if store closes)
   ```javascript
   if (!newStatus) {
     // Send notifications to customers with pending orders
     await notifyPendingOrders(merchantId)
   }
   ```

4. **Update Product Availability**
   ```javascript
   // Products from closed stores don't appear in search
   await Product.updateMany(
     { merchant: merchantId },
     { isAvailable: newStatus }
   )
   ```

5. **Return New Status**
   ```json
   {
     "success": true,
     "message": "Store is now open/closed",
     "data": {
       "isStoreOpen": true
     }
   }
   ```

### Business Logic:
- Closed stores:
  - ❌ Can't receive new orders
  - ❌ Products hidden from search
  - ✅ Can still manage existing orders
  - ✅ Can update inventory
- Useful for:
  - Holidays
  - Inventory restocking
  - Temporary closures

---

# 4. Admin Functions

## 👨‍💼 How Admin APIs Work

---

## 4.1 Merchant Verification

**Endpoint:** `PUT /api/admin/merchants/verify/:merchantId`

### How It Works:

1. **Receive Verification Decision**
   ```json
   {
     "status": "approved",
     "rejectionReason": ""
   }
   ```

2. **Find Merchant**
   ```javascript
   merchant = await Merchant.findById(merchantId)
   ```

3. **Update Verification Status**
   ```javascript
   merchant.verificationStatus = status // approved/rejected
   merchant.verifiedAt = new Date()
   merchant.verifiedBy = adminId
   
   if (status === 'rejected') {
     merchant.rejectionReason = rejectionReason
   }
   ```

4. **Send Notification Email**
   ```javascript
   if (status === 'approved') {
     await sendEmail({
       to: merchant.email,
       subject: 'Merchant Account Approved',
       template: 'merchantApproval',
       data: { businessName: merchant.businessName }
     })
   } else {
     await sendEmail({
       to: merchant.email,
       subject: 'Merchant Application Update',
       template: 'merchantRejection',
       data: { reason: rejectionReason }
     })
   }
   ```

5. **Create Admin Log**
   ```javascript
   await AdminLog.create({
     admin: adminId,
     action: 'merchant_verification',
     target: merchantId,
     status: status
   })
   ```

6. **Return Result**

### Business Logic:
- **Pending** → Can't login
- **Approved** → Can login and sell
- **Rejected** → Can reapply after fixing issues
- Admin must provide reason for rejection
- Email notification sent automatically

---

## 4.2 Platform Statistics

**Endpoint:** `GET /api/admin/stats`

### How It Works:

1. **Aggregate User Stats**
   ```javascript
   totalUsers = await User.countDocuments()
   activeUsers = await User.countDocuments({
     lastLoginAt: { $gte: last30Days }
   })
   newUsersThisMonth = await User.countDocuments({
     createdAt: { $gte: startOfMonth }
   })
   ```

2. **Aggregate Merchant Stats**
   ```javascript
   totalMerchants = await Merchant.countDocuments()
   approvedMerchants = await Merchant.countDocuments({
     verificationStatus: 'approved'
   })
   pendingMerchants = await Merchant.countDocuments({
     verificationStatus: 'pending'
   })
   ```

3. **Calculate Revenue**
   ```javascript
   revenue = await Order.aggregate([
     { $match: { status: 'delivered' }},
     { $group: {
       _id: null,
       total: { $sum: '$totalAmount' },
       platformFee: { $sum: '$platformFee' }
     }}
   ])
   ```

4. **Order Statistics**
   ```javascript
   totalOrders = await Order.countDocuments()
   ordersByStatus = await Order.aggregate([
     { $group: {
       _id: '$status',
       count: { $sum: 1 }
     }}
   ])
   ```

5. **Product Statistics**
   ```javascript
   totalProducts = await Product.countDocuments()
   activeProducts = await Product.countDocuments({
     status: 'active',
     stock: { $gt: 0 }
   })
   ```

6. **Return Dashboard**
   ```json
   {
     "success": true,
     "data": {
       "users": {
         "total": 1500,
         "active": 800,
         "newThisMonth": 50
       },
       "merchants": {
         "total": 120,
         "approved": 100,
         "pending": 15,
         "rejected": 5
       },
       "orders": {
         "total": 5000,
         "pending": 50,
         "completed": 4500
       },
       "revenue": {
         "total": 500000,
         "platformFee": 25000,
         "thisMonth": 50000
       },
       "products": {
         "total": 1200,
         "active": 1000
       }
     }
   }
   ```

### Business Logic:
- Real-time aggregation
- Used for business decisions
- Tracks platform growth
- Monitors revenue streams

---

# 5. Product Management

## 🛍️ How Product APIs Work

---

## 5.1 Get All Products (with Filters)

**Endpoint:** `GET /api/products`

### How It Works:

1. **Parse Query Parameters**
   ```javascript
   {
     page: 1,
     limit: 12,
     category: 'categoryId',
     merchant: 'merchantId',
     search: 'tomato',
     minPrice: 50,
     maxPrice: 200,
     tags: 'organic,farm-fresh'
   }
   ```

2. **Build Query Object**
   ```javascript
   query = { status: 'active' }
   
   if (category) query.category = category
   if (merchant) query.merchant = merchant
   if (minPrice || maxPrice) {
     query.price = {}
     if (minPrice) query.price.$gte = minPrice
     if (maxPrice) query.price.$lte = maxPrice
   }
   if (tags) {
     query.tags = { $in: tags.split(',') }
   }
   if (search) {
     query.$text = { $search: search }
   }
   ```

3. **Execute Query with Pagination**
   ```javascript
   products = await Product.find(query)
     .populate('merchant', 'businessName averageRating')
     .populate('category', 'name')
     .skip((page - 1) * limit)
     .limit(limit)
     .sort({ createdAt: -1 })
   ```

4. **Count Total**
   ```javascript
   total = await Product.countDocuments(query)
   pages = Math.ceil(total / limit)
   ```

5. **Return Results**
   ```json
   {
     "success": true,
     "data": {
       "products": [...],
       "pagination": {
         "page": 1,
         "limit": 12,
         "total": 45,
         "pages": 4
       }
     }
   }
   ```

### Search Features:
- **Text Search**: Searches name and description
- **Category Filter**: Show only vegetables, fruits, etc.
- **Price Range**: Min/max price filtering
- **Tags**: Multiple tag filtering (organic, seasonal, etc.)
- **Merchant Filter**: Products from specific merchant
- **Pagination**: Efficient loading

---

## 5.2 Create Product (Merchant)

**Endpoint:** `POST /api/products`

### How It Works:

1. **Authenticate Merchant**
   ```javascript
   merchantId = req.user._id
   if (req.userType !== 'merchant') {
     return error("Merchants only")
   }
   ```

2. **Receive Product Data**
   ```json
   {
     "name": "Fresh Cucumber",
     "description": "Organic cucumbers from our farm",
     "category": "categoryId",
     "price": 40,
     "unit": "kg",
     "stock": 100,
     "lowStockThreshold": 10,
     "primaryImage": "https://...",
     "tags": ["organic", "farm-fresh"],
     "nutritionalInfo": {
       "calories": 15,
       "protein": 0.6
     }
   }
   ```

3. **Validate Data**
   - Name: required, min 3 characters
   - Price: required, > 0
   - Stock: required, >= 0
   - Category: must exist
   - Unit: must be valid enum value

4. **Generate Slug**
   ```javascript
   slug = name.toLowerCase()
     .replace(/[^a-z0-9]+/g, '-')
     + '-' + Date.now()
   // Example: "fresh-cucumber-1707456789"
   ```

5. **Create Product**
   ```javascript
   product = await Product.create({
     ...productData,
     merchant: merchantId,
     slug,
     status: 'active'
   })
   ```

6. **Notify Followers** (if merchant has followers)
   ```javascript
   await notifyFollowers(merchantId, {
     type: 'new_product',
     product: product._id
   })
   ```

7. **Return Created Product**

### Business Logic:
- Each product belongs to **one merchant**
- Slug is **unique** (includes timestamp)
- New products are **active** by default
- Stock tracking enabled automatically

---

## 5.3 Update Stock (Merchant)

**Endpoint:** `PATCH /api/products/:id/stock`

### How It Works:

1. **Verify Ownership**
   ```javascript
   product = await Product.findById(productId)
   if (product.merchant.toString() !== merchantId) {
     return error("Not your product")
   }
   ```

2. **Receive New Stock**
   ```json
   {
     "stock": 150
   }
   ```

3. **Check Low Stock**
   ```javascript
   wasLowStock = product.stock <= product.lowStockThreshold
   product.stock = newStock
   isLowStock = newStock <= product.lowStockThreshold
   ```

4. **Update Status**
   ```javascript
   if (newStock === 0) {
     product.status = 'out-of-stock'
   } else if (product.status === 'out-of-stock') {
     product.status = 'active'
   }
   ```

5. **Send Notifications**
   ```javascript
   if (isLowStock && !wasLowStock) {
     // Notify merchant: stock is low
     await sendNotification(merchantId, {
       type: 'low_stock',
       product: product.name,
       stock: newStock
     })
   }
   
   if (newStock > 0 && wasOutOfStock) {
     // Notify customers: back in stock
     await notifyWaitlist(productId)
   }
   ```

6. **Save and Return**

### Business Logic:
- Stock = 0 → Status changes to "out-of-stock"
- Stock ≤ threshold → Low stock alert
- Back in stock → Notify waitlist customers
- Real-time inventory tracking

---

# 6. Category System

## 📂 How Category APIs Work

---

## 6.1 Get All Categories

**Endpoint:** `GET /api/categories`

### How It Works:

1. **Fetch Active Categories**
   ```javascript
   categories = await Category.find({ isActive: true })
     .sort({ name: 1 })
   ```

2. **Count Products per Category**
   ```javascript
   // Add product count to each category
   for (let category of categories) {
     category.productCount = await Product.countDocuments({
       category: category._id,
       status: 'active'
     })
   }
   ```

3. **Return Categories**
   ```json
   {
     "success": true,
     "data": [
       {
         "_id": "...",
         "name": "Vegetables",
         "description": "Fresh organic vegetables",
         "icon": "carrot",
         "image": "https://...",
         "productCount": 25
       }
     ]
   }
   ```

### Business Logic:
- Only **active** categories shown
- Sorted alphabetically
- Product count helps users navigate
- Used for filtering products

---

# 7. Shopping Cart

## 🛒 How Cart APIs Work

---

## 7.1 Add to Cart

**Endpoint:** `POST /api/cart/add`

### How It Works:

1. **Receive Product Details**
   ```json
   {
     "productId": "...",
     "quantity": 2,
     "preparationType": "chopped"
   }
   ```

2. **Validate Product**
   ```javascript
   product = await Product.findById(productId)
   if (!product) return error("Product not found")
   if (product.stock < quantity) {
     return error("Insufficient stock")
   }
   ```

3. **Check Merchant**
   ```javascript
   merchant = await Merchant.findById(product.merchant)
   if (!merchant.isStoreOpen) {
     return error("Store is currently closed")
   }
   ```

4. **Calculate Price**
   ```javascript
   basePrice = product.price
   
   // Add preparation cost if applicable
   if (preparationType) {
     prep = product.preparationOptions.find(
       p => p.type === preparationType
     )
     basePrice += prep.additionalPrice
   }
   
   subtotal = basePrice * quantity
   ```

5. **Find or Create Cart**
   ```javascript
   cart = await Cart.findOne({ user: userId })
   if (!cart) {
     cart = await Cart.create({ user: userId, items: [] })
   }
   ```

6. **Check Merchant Consistency**
   ```javascript
   if (cart.items.length > 0) {
     firstMerchant = cart.items[0].merchant
     if (firstMerchant !== product.merchant) {
       return error("Can only order from one merchant at a time")
     }
   }
   ```

7. **Update Cart**
   ```javascript
   existingItem = cart.items.find(
     item => item.product === productId &&
             item.preparationType === preparationType
   )
   
   if (existingItem) {
     existingItem.quantity += quantity
     existingItem.subtotal = existingItem.price * existingItem.quantity
   } else {
     cart.items.push({
       product: productId,
       quantity,
       price: basePrice,
       subtotal,
       preparationType
     })
   }
   ```

8. **Calculate Total**
   ```javascript
   cart.total = cart.items.reduce((sum, item) => sum + item.subtotal, 0)
   await cart.save()
   ```

9. **Return Updated Cart**

### Business Logic:
- **One merchant per cart** (can't mix)
- Stock validation before adding
- Preparation options add cost
- Existing items get quantity updated
- Total recalculated automatically

---

## 7.2 Recipe to Cart (Special Feature)

**Endpoint:** `POST /api/cart/recipe-to-cart`

### How It Works:

1. **Receive Recipe Request**
   ```json
   {
     "recipeId": "...",
     "servings": 8
   }
   ```

2. **Fetch Recipe**
   ```javascript
   recipe = await Recipe.findById(recipeId)
     .populate('ingredients.product')
   ```

3. **Calculate Scaled Quantities**
   ```javascript
   originalServings = recipe.servings // 4
   requestedServings = 8
   scaleFactor = requestedServings / originalServings // 2
   
   scaledIngredients = recipe.ingredients.map(ing => ({
     product: ing.product,
     originalQty: ing.quantity,
     scaledQty: ing.quantity * scaleFactor,
     unit: ing.unit
   }))
   ```

4. **Match Products**
   ```javascript
   // Find available products for each ingredient
   for (let ingredient of scaledIngredients) {
     if (ingredient.product) {
       // Product already linked
       product = ingredient.product
     } else {
       // Search for matching product
       product = await Product.findOne({
         name: { $regex: ingredient.name, $options: 'i' },
         status: 'active',
         stock: { $gte: ingredient.scaledQty }
       })
     }
     
     if (product) {
       ingredient.matchedProduct = product
     }
   }
   ```

5. **Add All to Cart**
   ```javascript
   itemsAdded = 0
   for (let ingredient of scaledIngredients) {
     if (ingredient.matchedProduct) {
       await addToCart({
         productId: ingredient.matchedProduct._id,
         quantity: ingredient.scaledQty
       })
       itemsAdded++
     }
   }
   ```

6. **Return Summary**
   ```json
   {
     "success": true,
     "message": "Recipe ingredients added to cart",
     "data": {
       "recipeName": "Vegetable Curry",
       "originalServings": 4,
       "scaledServings": 8,
       "itemsAdded": 4,
       "itemsNotFound": 0,
       "cart": {...}
     }
   }
   ```

### Business Logic:
- **Automatic scaling** based on servings
- **Smart product matching** if not pre-linked
- **Stock validation** for each ingredient
- **Batch addition** to cart
- **Summary report** of what was added

### Example:
```
Recipe: Vegetable Curry (4 servings)
- 200g Carrots
- 300g Potatoes
- 200g Tomatoes

User requests: 8 servings
System calculates:
- 400g Carrots (200g × 2)
- 600g Potatoes (300g × 2)
- 400g Tomatoes (200g × 2)

All added to cart automatically!
```

---

# 8. Order Processing

## 📦 How Order APIs Work

---

## 8.1 Create Order

**Endpoint:** `POST /api/orders`

### How It Works:

1. **Receive Order Details**
   ```json
   {
     "deliveryAddress": "addressId",
     "deliveryType": "standard",
     "deliveryTimeSlot": "morning",
     "paymentMethod": "cod",
     "specialRequests": "Please ring the bell"
   }
   ```

2. **Fetch Cart**
   ```javascript
   cart = await Cart.findOne({ user: userId })
     .populate('items.product')
   
   if (cart.items.length === 0) {
     return error("Cart is empty")
   }
   ```

3. **Validate Stock**
   ```javascript
   for (let item of cart.items) {
     product = item.product
     if (product.stock < item.quantity) {
       return error(`${product.name} has insufficient stock`)
     }
   }
   ```

4. **Calculate Totals**
   ```javascript
   itemsTotal = cart.total
   
   // Get delivery charges from merchant
   merchant = await Merchant.findById(cart.items[0].merchant)
   deliveryCharges = merchant.deliveryCharges
   
   // Apply discount if coupon used
   discount = 0
   if (couponCode) {
     coupon = await validateCoupon(couponCode, userId)
     discount = calculateDiscount(itemsTotal, coupon)
   }
   
   totalAmount = itemsTotal + deliveryCharges - discount
   ```

5. **Create Order**
   ```javascript
   order = await Order.create({
     orderId: generateOrderId(), // ORD-1707456789
     customer: userId,
     merchant: merchant._id,
     items: cart.items,
     itemsTotal,
     deliveryCharges,
     discount,
     totalAmount,
     deliveryAddress,
     deliveryType,
     deliveryTimeSlot,
     paymentMethod,
     paymentStatus: 'pending',
     status: 'pending',
     specialRequests
   })
   ```

6. **Reduce Stock**
   ```javascript
   for (let item of cart.items) {
     await Product.findByIdAndUpdate(item.product, {
       $inc: { stock: -item.quantity }
     })
   }
   ```

7. **Clear Cart**
   ```javascript
   cart.items = []
   cart.total = 0
   await cart.save()
   ```

8. **Send Notifications**
   ```javascript
   // Real-time notification to merchant via Socket.IO
   OrderSocket.notifyNewOrder(merchant._id, {
     orderId: order.orderId,
     customerName: req.user.name,
     totalAmount: order.totalAmount,
     itemsCount: order.items.length
   })
   
   // Email to customer
   await sendEmail({
     to: req.user.email,
     subject: 'Order Confirmed',
     template: 'orderConfirmation',
     data: { order }
   })
   
   // Create notification record
   await Notification.create({
     user: merchant._id,
     type: 'new_order',
     title: 'New Order Received',
     message: `Order ${order.orderId} from ${req.user.name}`,
     data: { orderId: order._id }
   })
   ```

9. **Return Order**
   ```json
   {
     "success": true,
     "message": "Order placed successfully",
     "data": {
       "order": {...},
       "estimatedDelivery": "2024-02-10 10:00 AM"
     }
   }
   ```

### Business Logic:
- **Stock reserved** immediately
- **Cart cleared** after order
- **Merchant notified** in real-time
- **Payment pending** for COD
- **Order ID** auto-generated
- **Delivery estimate** calculated

---

## 8.2 Update Order Status (Merchant)

**Endpoint:** `PATCH /api/orders/:id/status`

### How It Works:

1. **Receive Status Update**
   ```json
   {
     "status": "confirmed",
     "note": "Order confirmed, will deliver by 10 AM"
   }
   ```

2. **Validate Status Transition**
   ```javascript
   allowedTransitions = {
     'pending': ['confirmed', 'cancelled'],
     'confirmed': ['preparing', 'cancelled'],
     'preparing': ['out-for-delivery'],
     'out-for-delivery': ['delivered'],
     'delivered': [], // final state
     'cancelled': [] // final state
   }
   
   if (!allowedTransitions[currentStatus].includes(newStatus)) {
     return error("Invalid status transition")
   }
   ```

3. **Update Order**
   ```javascript
   order.status = newStatus
   order.statusHistory.push({
     status: newStatus,
     timestamp: new Date(),
     updatedBy: `merchant_${merchantId}`,
     note: note
   })
   
   // Update specific timestamps
   if (newStatus === 'confirmed') {
     order.confirmedAt = new Date()
   } else if (newStatus === 'delivered') {
     order.deliveredAt = new Date()
     order.paymentStatus = 'completed'
   }
   
   await order.save()
   ```

4. **Send Real-time Update**
   ```javascript
   // Socket.IO to customer
   OrderSocket.notifyOrderStatusUpdate(order.customer, {
     orderId: order.orderId,
     status: newStatus,
     statusMessage: getStatusMessage(newStatus),
     note: note
   })
   ```

5. **Send Notification**
   ```javascript
   await Notification.create({
     user: order.customer,
     type: 'order_update',
     title: `Order ${newStatus}`,
     message: getStatusMessage(newStatus),
     data: { orderId: order._id }
   })
   ```

6. **Update Loyalty Points** (if delivered)
   ```javascript
   if (newStatus === 'delivered') {
     points = Math.floor(order.totalAmount / 10) // 1 point per ₹10
     await User.findByIdAndUpdate(order.customer, {
       $inc: { loyaltyPoints: points }
     })
   }
   ```

7. **Return Updated Order**

### Status Flow:
```
pending → confirmed → preparing → out-for-delivery → delivered
   ↓
cancelled (can cancel before delivery)
```

### Business Logic:
- **Status history** tracked
- **Real-time updates** to customer
- **Loyalty points** awarded on delivery
- **Payment completed** when delivered
- **Timestamps** for each status

---

## 8.3 Cancel Order (Customer)

**Endpoint:** `PATCH /api/orders/:id/cancel`

### How It Works:

1. **Check Cancellation Eligibility**
   ```javascript
   if (['delivered', 'cancelled'].includes(order.status)) {
     return error("Cannot cancel this order")
   }
   
   if (order.status === 'out-for-delivery') {
     return error("Order already out for delivery")
   }
   ```

2. **Receive Cancellation Reason**
   ```json
   {
     "reason": "Changed my mind"
   }
   ```

3. **Update Order**
   ```javascript
   order.status = 'cancelled'
   order.cancellationReason = reason
   order.cancelledBy = 'customer'
   order.cancelledAt = new Date()
   await order.save()
   ```

4. **Restore Stock**
   ```javascript
   for (let item of order.items) {
     await Product.findByIdAndUpdate(item.product, {
       $inc: { stock: item.quantity }
     })
   }
   ```

5. **Process Refund** (if prepaid)
   ```javascript
   if (order.paymentMethod !== 'cod' && order.paymentStatus === 'completed') {
     await processRefund(order)
     order.refundStatus = 'initiated'
   }
   ```

6. **Notify Merchant**
   ```javascript
   OrderSocket.notifyOrderCancellation(order.merchant, {
     orderId: order.orderId,
     reason: reason
   })
   ```

7. **Return Confirmation**

### Business Logic:
- **Can't cancel** after out for delivery
- **Stock restored** immediately
- **Refund initiated** for prepaid orders
- **Merchant notified** of cancellation
- **Reason tracked** for analytics

---

# 9. Recipe System

## 🍳 How Recipe APIs Work

---

## 9.1 Calculate Ingredients

**Endpoint:** `POST /api/recipes/:id/calculate-ingredients`

### How It Works:

1. **Receive Serving Request**
   ```json
   {
     "servings": 8
   }
   ```

2. **Fetch Recipe**
   ```javascript
   recipe = await Recipe.findById(recipeId)
     .populate('ingredients.product')
   ```

3. **Calculate Scale Factor**
   ```javascript
   originalServings = recipe.servings // 4
   requestedServings = 8
   scaleFactor = requestedServings / originalServings // 2.0
   ```

4. **Scale Each Ingredient**
   ```javascript
   scaledIngredients = recipe.ingredients.map(ingredient => {
     originalQty = ingredient.quantity
     scaledQty = originalQty * scaleFactor
     
     // Round to reasonable precision
     if (ingredient.unit === 'piece') {
       scaledQty = Math.ceil(scaledQty)
     } else {
       scaledQty = Math.round(scaledQty * 100) / 100
     }
     
     return {
       name: ingredient.name,
       originalQuantity: originalQty,
       calculatedQuantity: scaledQty,
       unit: ingredient.unit,
       product: ingredient.product,
       isOptional: ingredient.isOptional
     }
   })
   ```

5. **Check Product Availability**
   ```javascript
   for (let ingredient of scaledIngredients) {
     if (ingredient.product) {
       product = ingredient.product
       ingredient.available = product.stock >= ingredient.calculatedQuantity
       ingredient.price = product.price * ingredient.calculatedQuantity
     }
   }
   ```

6. **Calculate Total Cost**
   ```javascript
   totalCost = scaledIngredients
     .filter(ing => ing.product && ing.available)
     .reduce((sum, ing) => sum + ing.price, 0)
   ```

7. **Return Calculation**
   ```json
   {
     "success": true,
     "data": {
       "recipeName": "Vegetable Curry",
       "originalServings": 4,
       "requestedServings": 8,
       "scaleFactor": 2.0,
       "ingredients": [
         {
           "name": "Carrots",
           "originalQuantity": 0.2,
           "calculatedQuantity": 0.4,
           "unit": "kg",
           "product": {...},
           "available": true,
           "price": 28
         }
       ],
       "totalCost": 120,
       "allIngredientsAvailable": true
     }
   }
   ```

### Business Logic:
- **Proportional scaling** for all ingredients
- **Smart rounding** based on unit type
- **Stock availability** checked
- **Cost calculated** automatically
- **Can add to cart** directly

### Example:
```
Original Recipe (4 servings):
- 200g Carrots (₹70/kg) = ₹14
- 300g Potatoes (₹40/kg) = ₹12
Total: ₹26

Scaled Recipe (8 servings):
- 400g Carrots (₹70/kg) = ₹28
- 600g Potatoes (₹40/kg) = ₹24
Total: ₹52
```

---

# 10. Review System

## ⭐ How Review APIs Work

---

## 10.1 Add Review (After Delivery)

**Endpoint:** `POST /api/orders/:id/review`

### How It Works:

1. **Verify Order Eligibility**
   ```javascript
   order = await Order.findById(orderId)
   
   if (order.customer.toString() !== userId) {
     return error("Not your order")
   }
   
   if (order.status !== 'delivered') {
     return error("Can only review delivered orders")
   }
   
   if (order.reviewedAt) {
     return error("Already reviewed")
   }
   ```

2. **Receive Review Data**
   ```json
   {
     "productId": "...",
     "rating": 5,
     "comment": "Excellent quality! Very fresh.",
     "images": ["https://..."]
   }
   ```

3. **Validate Product in Order**
   ```javascript
   productInOrder = order.items.find(
     item => item.product.toString() === productId
   )
   
   if (!productInOrder) {
     return error("Product not in this order")
   }
   ```

4. **Create Review**
   ```javascript
   review = await Review.create({
     user: userId,
     product: productId,
     order: orderId,
     rating: rating,
     comment: comment,
     images: images,
     isVerifiedPurchase: true
   })
   ```

5. **Update Product Rating**
   ```javascript
   // Calculate new average rating
   stats = await Review.aggregate([
     { $match: { product: productId } },
     { $group: {
       _id: '$product',
       avgRating: { $avg: '$rating' },
       totalReviews: { $sum: 1 }
     }}
   ])
   
   await Product.findByIdAndUpdate(productId, {
     averageRating: stats[0].avgRating,
     totalReviews: stats[0].totalReviews
   })
   ```

6. **Update Merchant Rating**
   ```javascript
   // Aggregate all product reviews for merchant
   merchantStats = await Review.aggregate([
     { $lookup: {
       from: 'products',
       localField: 'product',
       foreignField: '_id',
       as: 'productData'
     }},
     { $match: { 'productData.merchant': merchantId }},
     { $group: {
       _id: null,
       avgRating: { $avg: '$rating' },
       totalReviews: { $sum: 1 }
     }}
   ])
   
   await Merchant.findByIdAndUpdate(merchantId, {
     averageRating: merchantStats[0].avgRating,
     totalReviews: merchantStats[0].totalReviews
   })
   ```

7. **Update Order**
   ```javascript
   order.rating = rating
   order.review = comment
   order.reviewedAt = new Date()
   await order.save()
   ```

8. **Award Bonus Points**
   ```javascript
   // Bonus loyalty points for reviewing
   await User.findByIdAndUpdate(userId, {
     $inc: { loyaltyPoints: 10 }
   })
   ```

9. **Return Review**

### Business Logic:
- **Verified purchase** badge for order reviews
- **Product rating** updated automatically
- **Merchant rating** recalculated
- **Bonus points** for reviewing (10 points)
- **One review per order**
- **Images optional** but encouraged

---

# 11. Subscription Management

## 🔄 How Subscription APIs Work

---

## 11.1 Create Subscription

**Endpoint:** `POST /api/subscriptions`

### How It Works:

1. **Receive Subscription Details**
   ```json
   {
     "items": [
       {
         "product": "productId",
         "quantity": 2
       }
     ],
     "frequency": "weekly",
     "deliveryDay": "monday",
     "deliveryAddress": "addressId",
     "startDate": "2024-02-15"
   }
   ```

2. **Validate Products**
   ```javascript
   for (let item of items) {
     product = await Product.findById(item.product)
     if (!product) return error("Product not found")
     
     // Check if product is subscription-eligible
     if (!product.subscriptionEligible) {
       return error(`${product.name} not available for subscription`)
     }
   }
   ```

3. **Calculate Next Delivery**
   ```javascript
   nextDelivery = calculateNextDelivery(startDate, frequency, deliveryDay)
   // Example: If today is Feb 9 (Friday), weekly on Monday
   // Next delivery: Feb 12 (Monday)
   ```

4. **Calculate Pricing**
   ```javascript
   itemsTotal = items.reduce((sum, item) => {
     product = item.product
     return sum + (product.price * item.quantity)
   }, 0)
   
   // Subscription discount (10%)
   discount = itemsTotal * 0.10
   totalAmount = itemsTotal - discount
   ```

5. **Create Subscription**
   ```javascript
   subscription = await Subscription.create({
     user: userId,
     merchant: items[0].product.merchant,
     items: items,
     frequency: frequency, // daily, weekly, biweekly, monthly
     deliveryDay: deliveryDay,
     deliveryAddress: deliveryAddress,
     nextDeliveryDate: nextDelivery,
     itemsTotal: itemsTotal,
     discount: discount,
     totalAmount: totalAmount,
     status: 'active'
   })
   ```

6. **Schedule Cron Job**
   ```javascript
   // Cron job runs daily at 6 AM
   // Checks all subscriptions with nextDeliveryDate = today
   // Automatically creates orders
   ```

7. **Return Subscription**
   ```json
   {
     "success": true,
     "message": "Subscription created successfully",
     "data": {
       "subscription": {...},
       "nextDelivery": "2024-02-12",
       "savingsPerOrder": 12,
       "estimatedMonthlySavings": 48
     }
   }
   ```

### Business Logic:
- **10% discount** on subscriptions
- **Automatic order creation** via cron job
- **Flexible frequency** (daily, weekly, etc.)
- **Can pause/resume** anytime
- **Stock checked** before each order

---

## 11.2 Subscription Processing (Cron Job)

**Runs:** Daily at 6:00 AM

### How It Works:

1. **Find Due Subscriptions**
   ```javascript
   today = new Date().setHours(0,0,0,0)
   
   subscriptions = await Subscription.find({
     status: 'active',
     nextDeliveryDate: { 
       $lte: today 
     }
   }).populate('items.product')
   ```

2. **Process Each Subscription**
   ```javascript
   for (let subscription of subscriptions) {
     try {
       // Check stock availability
       allAvailable = true
       for (let item of subscription.items) {
         if (item.product.stock < item.quantity) {
           allAvailable = false
           break
         }
       }
       
       if (!allAvailable) {
         // Notify user about stock issue
         await notifyStockIssue(subscription)
         continue
       }
       
       // Create order automatically
       order = await Order.create({
         orderId: generateOrderId(),
         customer: subscription.user,
         merchant: subscription.merchant,
         items: subscription.items,
         totalAmount: subscription.totalAmount,
         deliveryAddress: subscription.deliveryAddress,
         paymentMethod: subscription.paymentMethod,
         isSubscriptionOrder: true,
         subscription: subscription._id,
         status: 'pending'
       })
       
       // Reduce stock
       for (let item of subscription.items) {
         await Product.findByIdAndUpdate(item.product, {
           $inc: { stock: -item.quantity }
         })
       }
       
       // Calculate next delivery
       nextDelivery = calculateNextDelivery(
         subscription.nextDeliveryDate,
         subscription.frequency,
         subscription.deliveryDay
       )
       
       subscription.nextDeliveryDate = nextDelivery
       subscription.lastOrderDate = new Date()
       subscription.totalOrders += 1
       await subscription.save()
       
       // Notify user
       await sendEmail({
         to: subscription.user.email,
         subject: 'Subscription Order Created',
         template: 'subscriptionOrder',
         data: { order, subscription }
       })
       
       // Notify merchant
       OrderSocket.notifyNewOrder(subscription.merchant, {
         orderId: order.orderId,
         isSubscription: true
       })
       
     } catch (error) {
       console.error(`Subscription ${subscription._id} failed:`, error)
       // Log error but continue processing other subscriptions
     }
   }
   ```

3. **Log Results**
   ```javascript
   console.log(`Processed ${subscriptions.length} subscriptions`)
   console.log(`Created ${ordersCreated} orders`)
   console.log(`Failed ${ordersFailed} orders`)
   ```

### Business Logic:
- **Runs automatically** every day
- **Stock validated** before order creation
- **User notified** if stock unavailable
- **Next delivery** calculated automatically
- **Merchant notified** of new subscription order
- **Error handling** prevents one failure from stopping others

---

## Summary of Key Features

### 🔐 Security
- JWT authentication
- Password hashing (bcrypt)
- Role-based access control
- Token expiration
- Account blocking

### 💰 Business Logic
- Loyalty points system
- Subscription discounts
- Dynamic pricing
- Stock management
- Multi-merchant support

### 🔔 Real-time Features
- Socket.IO notifications
- Order status updates
- Stock alerts
- New order alerts

### 🤖 Automation
- Cron jobs for subscriptions
- Auto-stock updates
- Auto-rating calculations
- Auto-loyalty points

### 📊 Analytics
- Dashboard statistics
- Revenue tracking
- Order analytics
- Product performance

---

**Last Updated:** February 9, 2024  
**Version:** 1.0.0  
**Total APIs Documented:** 60+
