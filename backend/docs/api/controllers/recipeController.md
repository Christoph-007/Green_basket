# Recipe Controller Documentation

## Overview
**File**: `src/controllers/recipeController.js`  
**Purpose**: Manages recipe catalog and the intelligent ingredient calculator for recipe-to-cart conversion.

## Dependencies
```javascript
const Recipe = require('../models/Recipe');
const Product = require('../models/Product');
const recipeCalculator = require('../services/recipeCalculator');
```

---

## Methods

### 1. `getAllRecipes(req, res)`

**Purpose**: Fetches paginated recipe catalog with filtering.

**Access**: Public

**Request Query Parameters**:
```
GET /api/recipes?page=1&limit=12&category=lunch&cuisine=south-indian&difficulty=easy&search=curry
```

**Parameters**:
- `page` (default: 1)
- `limit` (default: 12)
- `category`: breakfast, lunch, dinner, snack, dessert, beverage
- `cuisine`: south-indian, north-indian, kerala, chinese, continental, italian
- `difficulty`: easy, medium, hard
- `search`: Text search on name/description

**Response**:
```json
{
  "success": true,
  "data": {
    "recipes": [
      {
        "_id": "recipe_id",
        "name": "Vegetable Curry",
        "description": "Delicious mixed vegetable curry",
        "image": "https://cloudinary.com/...",
        "cuisine": "south-indian",
        "category": "lunch",
        "difficulty": "medium",
        "servings": 4,
        "prepTime": 15,
        "cookTime": 30,
        "totalTime": 45,
        "averageRating": 4.8,
        "totalRatings": 156,
        "timesCooked": 523
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 12,
      "total": 87,
      "pages": 8
    }
  }
}
```

---

### 2. `getRecipeById(req, res)`

**Purpose**: Fetches complete recipe details with ingredients.

**Access**: Public

**Request**:
```
GET /api/recipes/:id
```

**Response**:
```json
{
  "success": true,
  "data": {
    "recipe": {
      "_id": "recipe_id",
      "name": "Vegetable Curry",
      "description": "A flavorful curry with fresh vegetables",
      "image": "https://cloudinary.com/recipe.jpg",
      "videoUrl": "https://youtube.com/watch?v=...",
      "cuisine": "south-indian",
      "category": "lunch",
      "servings": 4,
      "prepTime": 15,
      "cookTime": 30,
      "totalTime": 45,
      "difficulty": "medium",
      "ingredients": [
        {
          "name": "Tomatoes",
          "quantity": 200,
          "unit": "g",
          "product": {
            "_id": "product_id",
            "name": "Organic Tomatoes",
            "price": 60,
            "stock": 50
          },
          "isOptional": false
        },
        {
          "name": "Onions",
          "quantity": 150,
          "unit": "g",
          "product": null,
          "isOptional": false
        }
      ],
      "instructions": [
        {
          "stepNumber": 1,
          "instruction": "Heat oil in a pan",
          "image": "https://cloudinary.com/step1.jpg"
        },
        {
          "stepNumber": 2,
          "instruction": "Add chopped onions and sauté",
          "image": null
        }
      ],
      "nutritionalInfo": {
        "calories": 250,
        "protein": 8,
        "carbohydrates": 35,
        "fat": 10,
        "fiber": 6
      },
      "dietaryTags": ["vegetarian", "gluten-free"],
      "tags": ["curry", "vegetables", "healthy"]
    }
  }
}
```

---

### 3. `calculateIngredients(req, res)` ⭐

**Purpose**: Intelligent ingredient calculator that scales recipe quantities and matches them to available products.

**Access**: Public

**Request**:
```json
{
  "servings": 6
}
```

**Logic Flow**:

1. **Fetch Recipe**:
   ```javascript
   const recipe = await Recipe.findById(id).populate('ingredients.product');
   ```

2. **Scale Ingredients**:
   ```javascript
   const scaledIngredients = recipeCalculator.scaleIngredients(
     recipe.ingredients,  // Original: 200g tomatoes for 4 servings
     recipe.servings,     // 4
     servings            // 6
   );
   // Result: 300g tomatoes (200 * 6/4)
   ```

3. **Product Matching**:
   ```javascript
   for (let ingredient of scaledIngredients) {
     let product = ingredient.product;
     
     // If no linked product, search by name
     if (!product) {
       product = await Product.findOne({
         name: new RegExp(ingredient.name, 'i'),
         status: 'active'
       }).sort({ averageRating: -1 });
     }
     
     // Build response with availability
     return {
       name: ingredient.name,
       quantity: ingredient.scaledQuantity,
       unit: ingredient.unit,
       product: product ? {
         id: product._id,
         name: product.name,
         price: product.price,
         image: product.primaryImage,
         stock: product.stock
       } : null,
       isAvailable: product && product.stock > 0
     };
   }
   ```

4. **Calculate Total Price**:
   ```javascript
   const totalPrice = ingredientsWithProducts.reduce((sum, item) => {
     if (item.product && item.isAvailable) {
       return sum + (item.product.price * item.quantity);
     }
     return sum;
   }, 0);
   ```

**Response**:
```json
{
  "success": true,
  "data": {
    "recipe": {
      "id": "recipe_id",
      "name": "Vegetable Curry",
      "servings": 6,
      "originalServings": 4
    },
    "ingredients": [
      {
        "name": "Tomatoes",
        "quantity": 0.3,
        "unit": "kg",
        "product": {
          "id": "product_id",
          "name": "Organic Tomatoes",
          "price": 60,
          "image": "https://...",
          "merchant": "merchant_id",
          "stock": 50
        },
        "isAvailable": true
      },
      {
        "name": "Onions",
        "quantity": 0.225,
        "unit": "kg",
        "product": {
          "id": "product_id_2",
          "name": "Fresh Onions",
          "price": 40,
          "image": "https://...",
          "stock": 30
        },
        "isAvailable": true
      },
      {
        "name": "Curry Leaves",
        "quantity": 10,
        "unit": "g",
        "product": null,
        "isAvailable": false
      }
    ],
    "totalPrice": 220,
    "availableItemsCount": 2,
    "totalItemsCount": 3
  }
}
```

**Business Value**:
- **Convenience**: Automatic quantity calculation
- **Discovery**: Introduces products to users
- **Accuracy**: Precise ingredient amounts
- **Conversion**: Drives cart additions

**Edge Cases**:
- Ingredient without product: Returns null, marked unavailable
- Out of stock: Product shown but marked unavailable
- Unit conversion: Handled by recipeCalculator (1000g → 1kg)

---

### 4. `searchRecipes(req, res)`

**Purpose**: Search recipes by keywords, category, or cuisine.

**Access**: Public

**Request**:
```
GET /api/recipes/search?q=curry&category=lunch&cuisine=south-indian
```

**Logic**:
```javascript
const query = { status: 'published' };

if (q) {
  query.$or = [
    { name: new RegExp(q, 'i') },
    { description: new RegExp(q, 'i') },
    { tags: new RegExp(q, 'i') }
  ];
}

if (category) query.category = category;
if (cuisine) query.cuisine = cuisine;
```

**Response**:
```json
{
  "success": true,
  "data": {
    "recipes": [
      {
        "name": "Vegetable Curry",
        "image": "https://...",
        "cuisine": "south-indian",
        "difficulty": "medium",
        "totalTime": 45
      }
    ]
  }
}
```

---

### 5. `createRecipe(req, res)`

**Purpose**: Admin creates a new recipe.

**Access**: Admin only

**Request**:
```json
{
  "name": "Vegetable Curry",
  "description": "Delicious curry recipe",
  "image": "https://cloudinary.com/...",
  "videoUrl": "https://youtube.com/...",
  "cuisine": "south-indian",
  "category": "lunch",
  "servings": 4,
  "prepTime": 15,
  "cookTime": 30,
  "difficulty": "medium",
  "ingredients": [
    {
      "name": "Tomatoes",
      "quantity": 200,
      "unit": "g",
      "product": "product_id",
      "isOptional": false
    }
  ],
  "instructions": [
    {
      "stepNumber": 1,
      "instruction": "Heat oil in a pan"
    }
  ],
  "nutritionalInfo": {
    "calories": 250,
    "protein": 8
  },
  "dietaryTags": ["vegetarian"],
  "tags": ["curry", "vegetables"]
}
```

**Logic**:
- Sets `createdBy` to admin user
- Auto-calculates `totalTime` (prepTime + cookTime)
- Generates slug from name
- Sets status to 'published'

**Response**:
```json
{
  "success": true,
  "message": "Recipe created successfully",
  "data": {
    "recipe": {
      "_id": "new_recipe_id",
      "name": "Vegetable Curry",
      "slug": "vegetable-curry",
      "status": "published"
    }
  }
}
```

---

### 6. `updateRecipe(req, res)`

**Purpose**: Admin updates existing recipe.

**Access**: Admin only

**Request**:
```
PUT /api/recipes/:id
```

**Logic**:
- Updates all provided fields
- Re-calculates totalTime if prep/cook time changed
- Maintains existing data for unprovided fields

**Response**:
```json
{
  "success": true,
  "message": "Recipe updated successfully",
  "data": {
    "recipe": { /* updated recipe */ }
  }
}
```

---

### 7. `deleteRecipe(req, res)`

**Purpose**: Admin removes a recipe.

**Access**: Admin only

**Request**:
```
DELETE /api/recipes/:id
```

**Response**:
```json
{
  "success": true,
  "message": "Recipe deleted successfully"
}
```

**Considerations**:
- Consider soft delete (status: 'archived')
- Check for user favorites/bookmarks
- Preserve analytics data

---

## Recipe Calculator Service

The `recipeCalculator` service handles intelligent ingredient scaling:

### `scaleIngredients(ingredients, originalServings, targetServings)`

**Logic**:
```javascript
const scaleFactor = targetServings / originalServings;

return ingredients.map(ingredient => {
  const scaledQuantity = roundQuantity(
    ingredient.quantity * scaleFactor,
    ingredient.unit
  );
  
  return {
    ...ingredient,
    originalQuantity: ingredient.quantity,
    scaledQuantity,
    scaleFactor
  };
});
```

### `roundQuantity(quantity, unit)`

**Rounding Rules**:
```javascript
const roundingRules = {
  'kg': 2,      // 2 decimal places (0.25 kg)
  'g': 0,       // Whole numbers (250 g)
  'piece': 0,   // Whole numbers (3 pieces)
  'cup': 2,     // 2 decimals (1.25 cups)
  'tbsp': 1,    // 1 decimal (2.5 tbsp)
  'tsp': 1,     // 1 decimal (1.5 tsp)
  'liter': 2,   // 2 decimals (0.75 L)
  'ml': 0       // Whole numbers (250 ml)
};
```

### `normalizeUnit(quantity, unit)`

**Unit Conversion**:
```javascript
if (unit === 'g' && quantity >= 1000) {
  return { quantity: quantity / 1000, unit: 'kg' };
}
if (unit === 'ml' && quantity >= 1000) {
  return { quantity: quantity / 1000, unit: 'liter' };
}
```

---

## User Journey: Recipe to Cart

```
User                    System                      Database
  |                        |                            |
  |--[Browse Recipes]----->|                            |
  |<--[Recipe List]--------|                            |
  |                        |                            |
  |--[View Recipe]-------->|                            |
  |<--[Recipe Details]-----|                            |
  |                        |                            |
  |--[Calculate for 6]---->|                            |
  |                        |--[Scale Ingredients]       |
  |                        |--[Match Products]--------->|
  |                        |<--[Product Data]-----------|
  |                        |--[Calculate Price]         |
  |<--[Scaled List]--------|                            |
  |                        |                            |
  |--[Add to Cart]-------->|                            |
  |                        |--[Create Cart Items]------>|
  |<--[Cart Updated]-------|                            |
```

---

## API Endpoints Summary

| Method | Endpoint | Purpose | Access |
|--------|----------|---------|--------|
| GET | `/api/recipes` | List recipes | Public |
| GET | `/api/recipes/search` | Search recipes | Public |
| GET | `/api/recipes/:id` | Recipe details | Public |
| POST | `/api/recipes/:id/calculate-ingredients` | Scale ingredients | Public |
| POST | `/api/recipes` | Create recipe | Admin |
| PUT | `/api/recipes/:id` | Update recipe | Admin |
| DELETE | `/api/recipes/:id` | Delete recipe | Admin |

---

## Future Enhancements

1. **User-Generated Recipes**: Allow users to submit recipes
2. **Recipe Collections**: Curated meal plans
3. **Nutritional Calculator**: Adjust for servings
4. **Cooking Timer**: Step-by-step cooking mode
5. **Video Integration**: Embedded cooking videos
6. **Recipe Ratings**: User reviews and ratings
7. **Ingredient Substitutions**: Alternative ingredients
8. **Shopping List**: Multi-recipe shopping lists
9. **Meal Planning**: Weekly meal scheduler
10. **Dietary Filters**: Vegan, keto, etc.
