# Cart Controller Documentation

## Overview
**File**: `src/controllers/cartController.js`  
**Purpose**: Manages shopping cart operations including adding/removing items and the unique recipe-to-cart feature.

## Dependencies
```javascript
const Cart = require('../models/Cart');
const Product = require('../models/Product');
const Recipe = require('../models/Recipe');
const recipeCalculator = require('../services/recipeCalculator');
```

---

## Methods

### 1. `getCart(req, res)`

**Purpose**: Retrieves the current user's shopping cart with all items and calculated total.

**Access**: Authenticated users only

**Request**:
- Method: `GET`
- No parameters required
- User ID extracted from JWT token

**Logic Flow**:
1. Finds cart by user ID
2. Populates product details for each cart item
3. If no cart exists, creates an empty cart
4. Calculates total using cart model method
5. Saves and returns cart

**Response**:
```json
{
  "success": true,
  "data": {
    "cart": {
      "_id": "cart_id",
      "user": "user_id",
      "items": [
        {
          "product": {
            "_id": "product_id",
            "name": "Organic Tomatoes",
            "price": 60,
            "primaryImage": "https://...",
            "stock": 50
          },
          "quantity": 2,
          "preparation": "whole",
          "price": 60,
          "addedAt": "2024-01-20T10:30:00.000Z"
        }
      ],
      "total": 120
    }
  }
}
```

**Business Logic**:
- Cart is automatically created on first access
- Total is recalculated on every fetch to ensure accuracy
- Product details are populated for display

---

### 2. `addToCart(req, res)`

**Purpose**: Adds a product to the cart or updates quantity if already present.

**Access**: Authenticated users only

**Request**:
```json
{
  "productId": "product_id_123",
  "quantity": 2,
  "preparation": "chopped" // optional: whole, cut, chopped, diced, sliced
}
```

**Logic Flow**:
1. **Product Validation**: Checks if product exists and is available
2. **Stock Check**: Verifies sufficient stock
3. **Cart Retrieval**: Finds or creates user's cart
4. **Duplicate Check**: Searches for existing item in cart
5. **Update/Add**:
   - If exists: Increments quantity
   - If new: Pushes new item to array
6. **Recalculation**: Updates total price
7. **Population**: Loads product details
8. **Response**: Returns updated cart

**Response**:
```json
{
  "success": true,
  "message": "Product added to cart",
  "data": {
    "cart": {
      "items": [...],
      "total": 180
    }
  }
}
```

**Error Handling**:
- 404: Product not found
- 400: Insufficient stock
- 500: Database error

**Business Rules**:
- Quantity is additive (adding 2 when 3 exist = 5 total)
- Price is captured at add time (protects against price changes)
- Preparation option may affect pricing (future enhancement)

---

### 3. `updateCartItem(req, res)`

**Purpose**: Modifies the quantity of a specific cart item.

**Access**: Authenticated users only

**Request**:
- URL Parameter: `productId`
- Body:
```json
{
  "quantity": 5
}
```

**Logic Flow**:
1. Finds user's cart
2. Locates item by product ID
3. **Special Case**: If quantity is 0, removes item completely
4. Otherwise: Updates quantity
5. Recalculates total
6. Returns updated cart

**Response**:
```json
{
  "success": true,
  "message": "Cart updated",
  "data": {
    "cart": {...}
  }
}
```

**Error Handling**:
- 404: Cart or item not found
- 500: Update failed

**Use Cases**:
- User increases/decreases quantity from cart page
- Setting quantity to 0 removes item
- Useful for quick adjustments

---

### 4. `removeFromCart(req, res)`

**Purpose**: Completely removes a product from the cart.

**Access**: Authenticated users only

**Request**:
- URL Parameter: `productId`

**Logic Flow**:
1. Finds user's cart
2. Filters out the specified product
3. Recalculates total
4. Saves and returns cart

**Response**:
```json
{
  "success": true,
  "message": "Item removed from cart",
  "data": {
    "cart": {...}
  }
}
```

**Difference from updateCartItem**:
- Direct removal vs setting quantity to 0
- Clearer intent in code
- Better for UI "Remove" buttons

---

### 5. `clearCart(req, res)`

**Purpose**: Empties the entire cart.

**Access**: Authenticated users only

**Request**:
- Method: `DELETE`
- No parameters

**Logic Flow**:
1. Finds cart by user ID
2. Sets items array to empty
3. Sets total to 0
4. Returns empty cart

**Response**:
```json
{
  "success": true,
  "message": "Cart cleared",
  "data": {
    "cart": {
      "items": [],
      "total": 0
    }
  }
}
```

**Use Cases**:
- After successful order placement
- User wants to start fresh
- Session cleanup

---

### 6. `addRecipeToCart(req, res)` ⭐

**Purpose**: Intelligent feature that adds all ingredients from a recipe to the cart, scaled to desired servings.

**Access**: Authenticated users only

**Request**:
```json
{
  "recipeId": "recipe_id_123",
  "servings": 6
}
```

**Logic Flow**:

1. **Recipe Retrieval**: Fetches recipe with populated product references
2. **Ingredient Scaling**: Uses `recipeCalculator.scaleIngredients()` to adjust quantities
   - Original recipe: 4 servings
   - User wants: 6 servings
   - Scale factor: 6/4 = 1.5
   - Example: 200g tomatoes → 300g tomatoes

3. **Product Matching**: For each ingredient:
   - If recipe has linked product, use it
   - Otherwise, search for matching product by name

4. **Stock Validation**: Checks if sufficient stock available

5. **Cart Update**: For each available ingredient:
   - Checks if product already in cart
   - If yes: Adds to existing quantity
   - If no: Adds new cart item

6. **Total Calculation**: Recalculates cart total

7. **Response**: Returns updated cart with all ingredients

**Response**:
```json
{
  "success": true,
  "message": "Recipe ingredients added to cart",
  "data": {
    "cart": {
      "items": [
        {
          "product": {
            "name": "Tomatoes",
            "price": 60
          },
          "quantity": 0.3, // 300g scaled from recipe
          "price": 60
        },
        {
          "product": {
            "name": "Onions",
            "price": 40
          },
          "quantity": 0.2,
          "price": 40
        }
      ],
      "total": 220
    }
  }
}
```

**Business Value**:
- **Convenience**: One-click shopping from recipes
- **Accuracy**: Automatic quantity calculation
- **Discovery**: Introduces users to products
- **Conversion**: Increases average order value

**Edge Cases Handled**:
- Ingredient without linked product (searches by name)
- Out of stock items (skipped with notification)
- Duplicate ingredients (quantities merged)
- Unit conversions (handled by recipeCalculator)

**Example User Journey**:
1. User browses "Vegetable Curry" recipe (serves 4)
2. User wants to cook for 6 people
3. Clicks "Add to Cart" with servings = 6
4. System calculates: 300g tomatoes, 200g onions, etc.
5. All available ingredients added to cart
6. User proceeds to checkout

---

## Cart Model Methods

The cart controller relies on the Cart model's `calculateTotal()` method:

```javascript
cartSchema.methods.calculateTotal = async function() {
  await this.populate('items.product');
  
  let total = 0;
  this.items.forEach(item => {
    if (item.product) {
      total += item.product.price * item.quantity;
    }
  });
  
  this.total = total;
  return total;
};
```

**Why Recalculate?**
- Product prices may change
- Ensures accuracy before checkout
- Handles deleted products gracefully

---

## API Endpoints Summary

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/cart` | Get user's cart |
| POST | `/api/cart/add` | Add item to cart |
| PUT | `/api/cart/update/:productId` | Update item quantity |
| DELETE | `/api/cart/remove/:productId` | Remove item |
| DELETE | `/api/cart/clear` | Clear entire cart |
| POST | `/api/cart/recipe-to-cart` | Add recipe ingredients |

---

## Error Handling Patterns

All methods follow consistent error handling:

```javascript
try {
  // Logic here
} catch (error) {
  res.status(500).json({
    success: false,
    message: 'Error description',
    error: error.message
  });
}
```

**HTTP Status Codes**:
- 200: Success
- 400: Bad request (insufficient stock, invalid data)
- 404: Resource not found
- 500: Server error

---

## Performance Considerations

1. **Population**: Cart items are populated with product details
   - Consider caching frequently accessed products
   - Limit populated fields to reduce payload

2. **Recalculation**: Total recalculated on every operation
   - Ensures accuracy but adds DB queries
   - Consider optimistic updates with periodic sync

3. **Recipe-to-Cart**: Multiple DB queries for ingredient matching
   - Could be optimized with bulk operations
   - Consider caching recipe-product mappings

---

## Security Considerations

1. **User Isolation**: Cart operations use `req.user.id` from JWT
   - Users can only access their own cart
   - No cart ID in URL prevents enumeration

2. **Stock Validation**: Prevents overselling
   - Checked at add time
   - Re-checked at checkout

3. **Price Integrity**: Prices captured at add time
   - Protects against manipulation
   - Ensures consistent checkout experience

---

## Future Enhancements

1. **Guest Carts**: Allow anonymous users to build carts
   - Merge with user cart on login
   - Cookie-based session management

2. **Save for Later**: Wishlist functionality
   - Move items between cart and wishlist
   - Price drop notifications

3. **Cart Expiry**: Auto-clear old carts
   - Release reserved stock
   - Cleanup inactive sessions

4. **Multi-Merchant Carts**: Support items from different merchants
   - Split into sub-carts
   - Separate checkout flows

5. **Smart Suggestions**: Recommend complementary products
   - "Frequently bought together"
   - Recipe-based suggestions

6. **Quantity Limits**: Per-product purchase limits
   - Prevent hoarding
   - Fair distribution of limited items

7. **Price Alerts**: Notify if cart total changes
   - Price increases/decreases
   - Out of stock notifications
