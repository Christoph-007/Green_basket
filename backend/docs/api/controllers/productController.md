# Product Controller Documentation

## Overview
**File**: `src/controllers/productController.js`  
**Purpose**: Manages product catalog, inventory, search functionality, and image uploads.

## Dependencies
```javascript
const Product = require('../models/Product');
const uploadService = require('../services/uploadService');
```

---

## Methods

### 1. `getAllProducts(req, res)`

**Purpose**: Fetches paginated product catalog with filtering and sorting.

**Access**: Public

**Request Query Parameters**:
```
GET /api/products?page=1&limit=12&category=vegetables&merchant=merchant_id&search=tomato&sort=-createdAt
```

**Parameters**:
- `page` (default: 1): Page number
- `limit` (default: 12): Items per page
- `category`: Filter by category ID
- `merchant`: Filter by merchant ID
- `search`: Text search (uses MongoDB text index)
- `sort` (default: '-createdAt'): Sort field
  - `-createdAt`: Newest first
  - `price`: Price low to high
  - `-price`: Price high to low
  - `-averageRating`: Highest rated first

**Logic**:
1. Builds query object with filters
2. Only shows active products
3. Populates merchant and category details
4. Applies sorting
5. Implements pagination
6. Counts total for pagination metadata

**Response**:
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "_id": "product_id",
        "name": "Organic Tomatoes",
        "description": "Fresh farm tomatoes",
        "price": 60,
        "unit": "kg",
        "stock": 50,
        "primaryImage": "https://cloudinary.com/...",
        "merchant": {
          "businessName": "Green Valley Farm",
          "profileImage": "https://...",
          "averageRating": 4.5
        },
        "category": {
          "name": "Vegetables"
        },
        "averageRating": 4.7,
        "totalReviews": 23,
        "tags": ["organic", "farm-fresh"]
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 12,
      "total": 156,
      "pages": 13
    }
  }
}
```

---

### 2. `getProductById(req, res)`

**Purpose**: Fetches detailed product information and increments view count.

**Access**: Public

**Request**:
```
GET /api/products/:id
```

**Logic**:
1. Finds product by ID
2. Populates merchant with full address
3. Populates category
4. Increments view counter (analytics)
5. Returns product details

**Response**:
```json
{
  "success": true,
  "data": {
    "product": {
      "_id": "product_id",
      "name": "Organic Tomatoes",
      "description": "Fresh, juicy tomatoes grown without pesticides",
      "price": 60,
      "comparePrice": 80,
      "unit": "kg",
      "stock": 50,
      "lowStockThreshold": 10,
      "images": [
        {
          "url": "https://cloudinary.com/image1.jpg",
          "publicId": "green-basket/products/abc123"
        }
      ],
      "primaryImage": "https://cloudinary.com/image1.jpg",
      "merchant": {
        "businessName": "Green Valley Farm",
        "profileImage": "https://...",
        "averageRating": 4.5,
        "address": {
          "city": "Bangalore",
          "state": "Karnataka"
        }
      },
      "category": {
        "name": "Vegetables"
      },
      "nutritionalInfo": {
        "calories": 18,
        "protein": 0.9,
        "carbohydrates": 3.9,
        "fiber": 1.2
      },
      "preparationOptions": [
        { "type": "whole", "additionalPrice": 0 },
        { "type": "chopped", "additionalPrice": 5 }
      ],
      "averageRating": 4.7,
      "totalReviews": 23,
      "totalSales": 450,
      "views": 1234
    }
  }
}
```

**Analytics Impact**:
- View count helps identify popular products
- Used for trending/recommended products
- Merchant can see product performance

---

### 3. `createProduct(req, res)` 📸

**Purpose**: Merchant creates a new product with image uploads.

**Access**: Authenticated merchants only

**Request**:
- Content-Type: `multipart/form-data`
- Body Fields:
```json
{
  "name": "Organic Tomatoes",
  "description": "Fresh farm tomatoes",
  "category": "category_id",
  "price": 60,
  "comparePrice": 80,
  "unit": "kg",
  "stock": 100,
  "lowStockThreshold": 10,
  "tags": ["organic", "farm-fresh"],
  "nutritionalInfo": {
    "calories": 18,
    "protein": 0.9
  },
  "preparationOptions": [
    { "type": "whole", "additionalPrice": 0 },
    { "type": "chopped", "additionalPrice": 5 }
  ]
}
```
- Files: `images[]` (up to 5 images)

**Logic Flow**:
1. **Image Upload**:
   ```javascript
   if (req.files && req.files.length > 0) {
     images = await uploadService.uploadMultipleImages(req.files, 'products');
     // Returns: [{ url, publicId }, ...]
   }
   ```

2. **Product Creation**:
   - Merchant ID from JWT token
   - First image becomes primary
   - Auto-generates slug from name

3. **Validation**:
   - Required fields checked by schema
   - Price must be positive
   - Stock cannot be negative

**Response**:
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "product": {
      "_id": "new_product_id",
      "name": "Organic Tomatoes",
      "slug": "organic-tomatoes-1706001234",
      "merchant": "merchant_id",
      "images": [
        {
          "url": "https://cloudinary.com/...",
          "publicId": "green-basket/products/xyz789"
        }
      ],
      "primaryImage": "https://cloudinary.com/...",
      "status": "active"
    }
  }
}
```

**Image Processing**:
- Uploaded to Cloudinary
- Optimized with Sharp (800x800, 85% quality)
- Auto-format (WebP for modern browsers)
- Stored with publicId for deletion

---

### 4. `updateProduct(req, res)`

**Purpose**: Merchant updates product details and/or adds new images.

**Access**: Authenticated merchants only (own products)

**Request**:
```
PUT /api/products/:id
Content-Type: multipart/form-data
```

**Logic**:
1. Validates merchant owns the product
2. Handles new image uploads
3. Appends new images to existing array
4. Updates all provided fields
5. Maintains existing data for unprovided fields

**Image Handling**:
```javascript
if (req.files && req.files.length > 0) {
  const newImages = await uploadService.uploadMultipleImages(req.files, 'products');
  updates.images = [...product.images, ...newImages];
  if (!updates.primaryImage) {
    updates.primaryImage = newImages[0]?.url;
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "Product updated successfully",
  "data": {
    "product": { /* updated product */ }
  }
}
```

---

### 5. `deleteProduct(req, res)`

**Purpose**: Permanently removes a product and its images.

**Access**: Authenticated merchants only (own products)

**Request**:
```
DELETE /api/products/:id
```

**Logic Flow**:
1. Finds and deletes product (atomic operation)
2. Validates merchant ownership
3. **Cleanup Images**:
   ```javascript
   if (product.images && product.images.length > 0) {
     const publicIds = product.images.map(img => img.publicId).filter(Boolean);
     await uploadService.deleteMultipleImages(publicIds);
   }
   ```

**Response**:
```json
{
  "success": true,
  "message": "Product deleted successfully"
}
```

**Considerations**:
- Cannot delete if active orders exist (add validation)
- Consider soft delete (status: 'deleted') instead
- Cloudinary cleanup prevents orphaned files

---

### 6. `updateStock(req, res)`

**Purpose**: Quick inventory adjustment with automatic status management.

**Access**: Authenticated merchants only

**Request**:
```json
{
  "stock": 25
}
```

**Logic**:
1. Updates stock quantity
2. **Auto Status Management**:
   ```javascript
   if (stock === 0) {
     product.status = 'out-of-stock';
   } else if (product.status === 'out-of-stock') {
     product.status = 'active';
   }
   ```

**Response**:
```json
{
  "success": true,
  "message": "Stock updated successfully",
  "data": {
    "product": {
      "stock": 25,
      "status": "active"
    }
  }
}
```

**Business Rules**:
- Stock 0 → Auto mark out-of-stock
- Restocking → Auto mark active
- Low stock alerts (handled elsewhere)

---

### 7. `getMyProducts(req, res)`

**Purpose**: Merchant views their product catalog.

**Access**: Authenticated merchants only

**Request**:
```
GET /api/products/my/products?page=1&limit=12&status=active
```

**Response**:
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "_id": "product_id",
        "name": "Organic Tomatoes",
        "price": 60,
        "stock": 50,
        "status": "active",
        "totalSales": 450,
        "views": 1234,
        "category": {
          "name": "Vegetables"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 12,
      "total": 45,
      "pages": 4
    }
  }
}
```

**Use Cases**:
- Merchant dashboard product list
- Inventory management
- Performance tracking

---

### 8. `searchProducts(req, res)`

**Purpose**: Text-based product search using MongoDB text indexes.

**Access**: Public

**Request**:
```
GET /api/products/search?q=organic+tomato
```

**Logic**:
- Uses MongoDB `$text` search on indexed fields
- Searches: name, description
- Limits to 20 results
- Only active products

**Response**:
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "name": "Organic Tomatoes",
        "merchant": {
          "businessName": "Green Valley Farm"
        },
        "price": 60,
        "primaryImage": "https://..."
      }
    ]
  }
}
```

**Search Index Setup**:
```javascript
// In Product model
productSchema.index({ name: 'text', description: 'text' });
```

---

## Product Status States

```
┌─────────────┐
│   active    │ ← Default for new products
└──────┬──────┘
       │
       ├──→ out-of-stock (stock = 0)
       │
       ├──→ coming-soon (pre-launch)
       │
       └──→ discontinued (no longer sold)
```

---

## Image Upload Flow

```
Client                  Controller              UploadService           Cloudinary
  |                         |                         |                      |
  |--[POST with files]----->|                         |                      |
  |                         |--[uploadMultiple]------>|                      |
  |                         |                         |--[optimize]          |
  |                         |                         |--[upload]----------->|
  |                         |                         |<--[url, publicId]----|
  |                         |<--[images array]--------|                      |
  |                         |--[save to DB]           |                      |
  |<--[product with URLs]---|                         |                      |
```

---

## API Endpoints Summary

| Method | Endpoint | Purpose | Access |
|--------|----------|---------|--------|
| GET | `/api/products` | List products | Public |
| GET | `/api/products/search` | Search products | Public |
| GET | `/api/products/:id` | Product details | Public |
| GET | `/api/products/my/products` | Merchant's products | Merchant |
| POST | `/api/products` | Create product | Merchant |
| PUT | `/api/products/:id` | Update product | Merchant |
| DELETE | `/api/products/:id` | Delete product | Merchant |
| PATCH | `/api/products/:id/stock` | Update stock | Merchant |

---

## Performance Optimizations

1. **Indexes**:
   ```javascript
   productSchema.index({ name: 'text', description: 'text' });
   productSchema.index({ merchant: 1, status: 1 });
   productSchema.index({ category: 1, status: 1 });
   ```

2. **Pagination**: Prevents large result sets
3. **Selective Population**: Only needed fields
4. **Image Optimization**: Sharp processing
5. **CDN**: Cloudinary for fast image delivery

---

## Future Enhancements

1. **Advanced Search**: Filters, price range, ratings
2. **Bulk Operations**: Import/export products
3. **Product Variants**: Sizes, colors, packaging
4. **Inventory Alerts**: Email when low stock
5. **Price History**: Track price changes
6. **Related Products**: ML-based recommendations
7. **Product Analytics**: Views, conversion rates
8. **Seasonal Availability**: Auto-activate/deactivate
