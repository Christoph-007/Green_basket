# User Controller Documentation

## Overview
**File**: `src/controllers/userController.js`  
**Purpose**: Manages customer profiles, preferences, and address book.

## Dependencies
```javascript
const User = require('../models/User');
const Address = require('../models/Address');
```

---

## Methods

### 1. `getProfile(req, res)`

**Purpose**: Retrieves the authenticated user's complete profile.

**Access**: Authenticated users only

**Request**:
```
GET /api/users/profile
```

**Logic**:
- Fetches user document by ID from JWT token
- Returns all profile fields (password excluded by schema)

**Response**:
```json
{
  "success": true,
  "data": {
    "_id": "user_id",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210",
    "profileImage": "https://cloudinary.com/...",
    "isEmailVerified": true,
    "isPhoneVerified": false,
    "dietaryPreferences": ["vegetarian", "organic-only"],
    "allergies": ["peanuts", "shellfish"],
    "isPremium": false,
    "premiumExpiresAt": null,
    "loyaltyPoints": 250,
    "loyaltyTier": "silver",
    "walletBalance": 150,
    "notificationSettings": {
      "email": true,
      "sms": true,
      "push": true,
      "orderUpdates": true,
      "offers": true
    },
    "isActive": true,
    "lastLoginAt": "2024-01-20T10:30:00.000Z",
    "createdAt": "2023-12-01T08:00:00.000Z"
  }
}
```

**Use Cases**:
- Profile page display
- Settings page pre-fill
- Mobile app profile screen

---

### 2. `updateProfile(req, res)`

**Purpose**: Updates user profile information and preferences.

**Access**: Authenticated users only

**Request**:
```json
{
  "name": "John Michael Doe",
  "phone": "9876543211",
  "dietaryPreferences": ["vegetarian", "gluten-free"],
  "allergies": ["peanuts"],
  "notificationSettings": {
    "email": true,
    "sms": false,
    "push": true,
    "orderUpdates": true,
    "offers": false
  }
}
```

**Updatable Fields**:
- `name`: User's full name
- `phone`: Contact number
- `dietaryPreferences`: Food preferences
- `allergies`: Allergy information
- `notificationSettings`: Communication preferences

**Protected Fields** (cannot be updated via this endpoint):
- `email`: Requires verification
- `password`: Use separate password change endpoint
- `loyaltyPoints`: System managed
- `walletBalance`: Payment system managed
- `isPremium`: Subscription system managed

**Logic**:
1. Extracts allowed fields from request
2. Builds update object with only provided fields
3. Updates user document with validation
4. Returns updated profile

**Response**:
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "_id": "user_id",
    "name": "John Michael Doe",
    "phone": "9876543211",
    "dietaryPreferences": ["vegetarian", "gluten-free"],
    "allergies": ["peanuts"],
    "notificationSettings": {
      "email": true,
      "sms": false,
      "push": true,
      "orderUpdates": true,
      "offers": false
    }
  }
}
```

**Validation**:
- Phone number format (10 digits)
- Dietary preferences from enum
- Notification settings boolean values

---

### 3. `getAddresses(req, res)`

**Purpose**: Retrieves all saved addresses for the user.

**Access**: Authenticated users only

**Request**:
```
GET /api/users/addresses
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "_id": "address_id_1",
      "user": "user_id",
      "label": "home",
      "name": "John Doe",
      "phone": "9876543210",
      "addressLine1": "123 Main Street",
      "addressLine2": "Apartment 4B",
      "landmark": "Near City Hospital",
      "city": "Bangalore",
      "state": "Karnataka",
      "pincode": "560001",
      "location": {
        "type": "Point",
        "coordinates": [77.5946, 12.9716]
      },
      "isDefault": true,
      "createdAt": "2023-12-01T08:00:00.000Z"
    },
    {
      "_id": "address_id_2",
      "label": "office",
      "addressLine1": "456 Tech Park",
      "city": "Bangalore",
      "state": "Karnataka",
      "pincode": "560100",
      "isDefault": false
    }
  ]
}
```

**Address Labels**:
- `home`: Home address
- `office`: Office/work address
- `other`: Other locations

---

### 4. `addAddress(req, res)`

**Purpose**: Adds a new delivery address to user's address book.

**Access**: Authenticated users only

**Request**:
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
  "location": {
    "coordinates": [77.5946, 12.9716]
  },
  "isDefault": true
}
```

**Logic**:
1. **Default Address Handling**:
   ```javascript
   if (req.body.isDefault) {
     // Unset all other defaults for this user
     await Address.updateMany(
       { user: req.user.id },
       { isDefault: false }
     );
   }
   ```

2. Creates new address with user ID
3. Returns created address

**Response**:
```json
{
  "success": true,
  "message": "Address added successfully",
  "data": {
    "_id": "new_address_id",
    "user": "user_id",
    "label": "home",
    "addressLine1": "123 Main Street",
    "city": "Bangalore",
    "pincode": "560001",
    "isDefault": true
  }
}
```

**Validation**:
- Required: addressLine1, city, state, pincode
- Pincode format: 6 digits
- Coordinates: [longitude, latitude]

---

### 5. `updateAddress(req, res)`

**Purpose**: Updates an existing address.

**Access**: Authenticated users only (own addresses)

**Request**:
```
PUT /api/users/addresses/:id
```

**Body**:
```json
{
  "addressLine1": "789 New Street",
  "landmark": "Opposite Park",
  "isDefault": true
}
```

**Logic**:
1. **Ownership Validation**:
   ```javascript
   const address = await Address.findOne({ 
     _id: id, 
     user: req.user.id 
   });
   
   if (!address) {
     return res.status(404).json({
       message: 'Address not found'
     });
   }
   ```

2. **Default Handling**:
   ```javascript
   if (req.body.isDefault) {
     await Address.updateMany(
       { user: req.user.id },
       { isDefault: false }
     );
   }
   ```

3. Updates address with validation
4. Returns updated address

**Response**:
```json
{
  "success": true,
  "message": "Address updated successfully",
  "data": {
    "_id": "address_id",
    "addressLine1": "789 New Street",
    "landmark": "Opposite Park",
    "isDefault": true
  }
}
```

---

### 6. `deleteAddress(req, res)`

**Purpose**: Removes an address from the address book.

**Access**: Authenticated users only (own addresses)

**Request**:
```
DELETE /api/users/addresses/:id
```

**Logic**:
1. Finds and deletes address in one operation
2. Validates user ownership
3. Returns success message

**Response**:
```json
{
  "success": true,
  "message": "Address deleted successfully"
}
```

**Business Rules**:
- Cannot delete if it's the only address (add validation)
- If default address deleted, auto-set another as default (enhancement)
- Check for active orders using this address (enhancement)

---

## Address Model Schema

```javascript
{
  user: ObjectId,              // Owner
  label: String,               // home, office, other
  name: String,                // Recipient name
  phone: String,               // Contact number
  addressLine1: String,        // Street address
  addressLine2: String,        // Apartment/suite
  landmark: String,            // Nearby landmark
  city: String,                // City
  state: String,               // State
  pincode: String,             // 6-digit pincode
  location: {
    type: 'Point',
    coordinates: [Number]      // [longitude, latitude]
  },
  isDefault: Boolean,          // Default delivery address
  createdAt: Date,
  updatedAt: Date
}
```

---

## User Preferences

### Dietary Preferences
- `vegetarian`: No meat
- `vegan`: No animal products
- `non-vegetarian`: All foods
- `gluten-free`: No gluten
- `organic-only`: Only organic products

### Notification Settings
```javascript
{
  email: true,           // Email notifications
  sms: true,             // SMS notifications
  push: true,            // Push notifications
  orderUpdates: true,    // Order status updates
  offers: true           // Promotional offers
}
```

---

## API Endpoints Summary

| Method | Endpoint | Purpose | Access |
|--------|----------|---------|--------|
| GET | `/api/users/profile` | Get profile | User |
| PUT | `/api/users/profile` | Update profile | User |
| GET | `/api/users/addresses` | Get addresses | User |
| POST | `/api/users/addresses` | Add address | User |
| PUT | `/api/users/addresses/:id` | Update address | User |
| DELETE | `/api/users/addresses/:id` | Delete address | User |

---

## Loyalty System

The loyalty system is managed automatically:

```javascript
// After order delivery
const awardLoyaltyPoints = async (userId, orderAmount) => {
  const points = Math.floor(orderAmount / 10); // 1 point per ₹10
  
  const user = await User.findByIdAndUpdate(userId, {
    $inc: { loyaltyPoints: points }
  });
  
  // Update tier based on points
  let tier = 'bronze';
  if (user.loyaltyPoints >= 1000) tier = 'platinum';
  else if (user.loyaltyPoints >= 500) tier = 'gold';
  else if (user.loyaltyPoints >= 200) tier = 'silver';
  
  user.loyaltyTier = tier;
  await user.save();
};
```

**Loyalty Tiers**:
- Bronze: 0-199 points
- Silver: 200-499 points
- Gold: 500-999 points
- Platinum: 1000+ points

---

## Future Enhancements

1. **Profile Picture Upload**: Cloudinary integration
2. **Email Change**: With verification
3. **Phone Verification**: OTP system
4. **Privacy Settings**: Data sharing preferences
5. **Account Deletion**: GDPR compliance
6. **Export Data**: Download user data
7. **Linked Accounts**: Family/shared accounts
8. **Saved Payment Methods**: Card management
9. **Order History Export**: CSV/PDF download
10. **Preference Learning**: AI-based recommendations
