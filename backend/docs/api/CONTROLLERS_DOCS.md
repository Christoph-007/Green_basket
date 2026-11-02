# Green Basket - Controllers Documentation

This document provides a detailed analysis of each controller file in the `src/controllers/` directory. These controllers handle the business logic for the application, processing requests, interacting with the database models, and sending responses.

## Table of Contents
1. [Admin Controller](#1-admincontrollerjs)
2. [Auth Controller](#2-authcontrollerjs)
3. [Cart Controller](#3-cartcontrollerjs)
4. [Merchant Controller](#4-merchantcontrollerjs)
5. [Order Controller](#5-ordercontrollerjs)
6. [Product Controller](#6-productcontrollerjs)
7. [Recipe Controller](#7-recipecontrollerjs)
8. [Review Controller](#8-reviewcontrollerjs)
9. [Subscription Controller](#9-subscriptioncontrollerjs)
10. [User Controller](#10-usercontrollerjs)

---

## 1. `adminController.js`
**Purpose**: Handles administrative tasks such as verifying merchants, managing users, and viewing platform statistics.

### Methods:
- **`getPendingMerchants(req, res)`**
  - **Purpose**: Fetches a list of merchants who are waiting for verification.
  - **Logic**: Queries `Merchant` model for `verificationStatus: 'pending'`.

- **`verifyMerchant(req, res)`**
  - **Purpose**: Approves or rejects a merchant account.
  - **Logic**: Updates `verificationStatus`, sets `verifiedBy` and `verifiedAt`. If rejected, saves the `rejectionReason`.

- **`getUsers(req, res)`**
  - **Purpose**: Retrieves a list of all registered users.
  - **Logic**: Returns all users, excluding passwords.

- **`toggleUserBlock(req, res)`**
  - **Purpose**: Blocks or unblocks a user account.
  - **Logic**: Updates `isBlocked` and optional `blockedReason`.

- **`getPlatformStats(req, res)`**
  - **Purpose**: Aggregates high-level platform metrics.
  - **Logic**: Counts total documents for Users, Merchants, and Orders.

---

## 2. `authController.js`
**Purpose**: Manages authentication and authorization for all user types (User, Merchant, Admin).

### Methods:
- **`userSignup(req, res)`**
  - **Purpose**: Registers a new customer.
  - **Logic**: Creates user, generates a **JWT** for email verification, and sends a verification email using `emailService`.

- **`userLogin(req, res)`**
  - **Purpose**: Authenticates a customer.
  - **Logic**: Validates credentials, checks if blocked, updates `lastLoginAt`, and issues a specialized User JWT.

- **`merchantSignup(req, res)`**
  - **Purpose**: Registers a new merchant.
  - **Logic**: Creates a merchant profile with `verificationStatus: 'pending'`. Returns a token immediately but access is restricted by middleware until approved.

- **`merchantLogin(req, res)`**
  - **Purpose**: Authenticates a merchant.
  - **Logic**: Validates credentials and returns Merchant JWT + store status.

- **`adminLogin(req, res)`**
  - **Purpose**: Authenticates an administrator.
  - **Logic**: Validates credentials and returns Admin JWT with permissions.

- **`verifyEmail(req, res)`**
  - **Purpose**: Verifies a user's email address via token.
  - **Logic**: Decodes token, finds user, sets `isEmailVerified: true`.

- **`forgotPassword(req, res)`**
  - **Purpose**: Initiates password recovery.
  - **Logic**: Generates a short-lived reset token and emails a reset link.

- **`resetPassword(req, res)`**
  - **Purpose**: Sets a new password using a valid reset token.
  - **Logic**: Verifies token, hashes new password (via model middleware), and updates user.

- **`refreshToken(req, res)`**
  - **Purpose**: Issues a new access token.
  - **Logic**: Verifies existing valid token and issues a fresh one (typically used for extending sessions).

- **`logout(req, res)`**
  - **Purpose**: Client-side logout helper (stateless API usually handles this on client, but this endpoint acknowledges the action).

---

## 3. `cartController.js`
**Purpose**: Manages the shopping cart for customers, including adding items and converting recipes to cart items.

### Methods:
- **`getCart(req, res)`**
  - **Purpose**: Retrieves the current user's cart.
  - **Logic**: Fetches cart, populates product details, recalculates totals on read to ensure accuracy.

- **`addToCart(req, res)`**
  - **Purpose**: Adds a product to the cart.
  - **Logic**: Checks stock availability. If item exists, increments quantity; otherwise, pushes new item. Recalculates total.

- **`updateCartItem(req, res)`**
  - **Purpose**: Updates quantity of a specific item.
  - **Logic**: Modifies quantity. If quantity is 0, removes item. Recalculates total.

- **`removeFromCart(req, res)`**
  - **Purpose**: Removes a specific product from the cart.
  - **Logic**: Filters out the target product ID and saves.

- **`clearCart(req, res)`**
  - **Purpose**: Empties the cart.
  - **Logic**: Sets items array to empty and total to 0.

- **`addRecipeToCart(req, res)`**
  - **Purpose**: Smart feature to add all ingredients from a recipe to the cart.
  - **Logic**:
    1. Fetches recipe and scales ingredients based on desired `servings`.
    2. Matches ingredients to actual Products in DB.
    3. Checks stock for each ingredient.
    4. Adds available items to the cart automatically.

---

## 4. `merchantController.js`
**Purpose**: Allows merchants to manage their business profile and view dashboard data.

### Methods:
- **`getProfile(req, res)`**
  - **Purpose**: Fetches merchant details.

- **`updateProfile(req, res)`**
  - **Purpose**: Updates business details (address, operating hours, delivery rules).
  - **Logic**: Helper for keeping store information current.

- **`toggleStoreStatus(req, res)`**
  - **Purpose**: Opens or closes the store manually.
  - **Logic**: Toggles `isStoreOpen` boolean.

- **`getDashboardStats(req, res)`**
  - **Purpose**: Provides business analytics.
  - **Logic**: Aggregates:
    - Total Orders
    - Total Revenue (from delivered orders)
    - Low stock products count

---

## 5. `orderController.js`
**Purpose**: Central hub for order processing, handling the lifecycle from creation to delivery.

### Methods:
- **`createOrder(req, res)`**
  - **Purpose**: Places a new order.
  - **Logic**:
    - Validates stock for all items.
    - Calculates totals, delivery charges, and discounts.
    - Creates Order record.
    - **Decrements Stock** for products.
    - Clears User's Cart.
    - **Real-time**: Emits `new_order` socket event to Merchant.
    - Sends Notification.

- **`getMyOrders(req, res)`** & **`getMerchantOrders(req, res)`**
  - **Purpose**: Lists orders for Customer or Merchant respectively, with pagination and filtering.

- **`updateOrderStatus(req, res)`**
  - **Purpose**: Merchant updates order state (e.g., 'preparing', 'delivered').
  - **Logic**:
    - Updates status and history logs.
    - **Real-time**: Emits `order_status_update` to Customer.
    - Sends Notification to Customer.

- **`cancelOrder(req, res)`**
  - **Purpose**: Customer cancels an order.
  - **Logic**: Checks if cancellation is allowed (not already delivered). Restores product stock. Notifies Merchant.

- **`addReview(req, res)`**
  - **Purpose**: Adds a rating and review to a completed order.
  - **Logic**: Updates Order document with rating/review from the customer's perspective.

---

## 6. `productController.js`
**Purpose**: Manages product catalog, inventory, and search.

### Methods:
- **`getAllProducts`**, **`getProductById`**, **`getMyProducts`**
  - Standard CRUD operations with pagination, filtering (category, merchant), and population of relational data.

- **`createProduct`** & **`updateProduct`**
  - **Merchant Only**. Handles text data and **multiple image uploads** (via `uploadService`).

- **`deleteProduct`**
  - **Logic**: Removes product from DB and deletes associated images from Cloudinary.

- **`updateStock`**
  - **Purpose**: Quick inventory adjustment.
  - **Logic**: Updates count. Automatically sets status to 'out-of-stock' if 0, or 'active' if > 0.

- **`searchProducts`**
  - **Purpose**: Text-based search.
  - **Logic**: Uses MongoDB text indexes on name/description.

---

## 7. `recipeController.js`
**Purpose**: Manages recipes and the specific logic for ingredient modification.

### Methods:
- **`getAllRecipes`** & **`getRecipeById`**
  - Standard fetch operations with filters (cuisine, difficulty, category).

- **`calculateIngredients(req, res)`**
  - **Purpose**: Dynamic ingredient scaler.
  - **Logic**:
    - Takes `servings` input.
    - Uses `recipeCalculator` service to scale quantities.
    - **Smart Match**: Tries to find buyable `Product`s in the DB that match the ingredient names (fuzzy search).
    - Returns scaled list + estimated total price.

- **`createRecipe`**, **`updateRecipe`**, **`deleteRecipe`**
  - **Admin Only**. Content management for the recipe blog/section.

---

## 8. `reviewController.js`
**Purpose**: Handles retrieval and deletion of reviews.

### Methods:
- **`getProductReviews`** & **`getMerchantReviews`**
  - Fetches paginated reviews for display on product/merchant pages.

- **`deleteReview`**
  - **Admin/Owner Only**. Moderation tool to remove inappropriate content.

---

## 9. `subscriptionController.js`
**Purpose**: Manages recurring delivery subscriptions.

### Methods:
- **`createSubscription`**: Sets up a new recurring schedule (daily/weekly) for items.
- **`getMySubscriptions`**: Lists user's active/paused subscriptions.
- **`updateSubscriptionStatus`**: Pause, Resume, or Cancel a subscription.

---

## 10. `userController.js`
**Purpose**: Manages consumer profiles and address books.

### Methods:
- **`getProfile`** & **`updateProfile`**
  - Manage personal info (name, phone) and preferences (dietary, notifications).

- **`getAddresses`**, **`addAddress`**, **`updateAddress`**, **`deleteAddress`**
  - **Logic**: CRUD for shipping addresses.
  - **Note**: When `addAddress` or `updateAddress` sets `isDefault: true`, it automatically unsets the flag on all other addresses for that user.
