# Auth Controller Documentation

## Overview
**File**: `src/controllers/authController.js`  
**Purpose**: Manages authentication and authorization for all user types (Users, Merchants, Admins).

## Dependencies
```javascript
const User = require('../models/User');
const Merchant = require('../models/Merchant');
const Admin = require('../models/Admin');
const generateToken = require('../utils/generateToken');
const { sendEmail } = require('../services/emailService');
const jwt = require('jsonwebtoken');
```

---

## Methods

### 1. `userSignup(req, res)`

**Purpose**: Registers a new customer account.

**Access**: Public

**Request**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "9876543210",
  "password": "securePassword123"
}
```

**Logic Flow**:
1. **Validation**: Checks if user already exists with email or phone
2. **User Creation**: Creates new user document (password auto-hashed by model middleware)
3. **Verification Token**: Generates JWT token valid for 24 hours
4. **Email Sending**: Sends verification email with link
5. **Auth Token**: Generates main authentication JWT
6. **Response**: Returns user data and token

**Response**:
```json
{
  "success": true,
  "message": "User registered successfully. Please verify your email.",
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "9876543210"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Handling**:
- 400: User already exists
- 500: Database or email service error

**Security Features**:
- Password hashing via bcrypt (in User model pre-save hook)
- Email verification required for full access
- JWT token for stateless authentication

---

### 2. `userLogin(req, res)`

**Purpose**: Authenticates an existing customer.

**Access**: Public

**Request**:
```json
{
  "email": "john@example.com",
  "password": "securePassword123"
}
```

**Logic Flow**:
1. **Find User**: Queries user with password field (normally excluded)
2. **Password Verification**: Uses bcrypt comparison via model method
3. **Block Check**: Verifies account is not blocked
4. **Update Login Time**: Sets `lastLoginAt` timestamp
5. **Token Generation**: Creates JWT with user ID and type
6. **Response**: Returns user profile and token

**Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "9876543210",
      "profileImage": "https://...",
      "isPremium": false,
      "loyaltyPoints": 150
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Handling**:
- 401: Invalid credentials
- 403: Account blocked
- 500: Server error

**Security Checks**:
- Constant-time password comparison
- Account status verification
- Session tracking via lastLoginAt

---

### 3. `merchantSignup(req, res)`

**Purpose**: Registers a new merchant/farmer account.

**Access**: Public

**Request**:
```json
{
  "name": "Farmer Name",
  "email": "farmer@example.com",
  "phone": "9876543210",
  "password": "securePassword123",
  "businessName": "Green Valley Farm",
  "merchantType": "organic-farmer"
}
```

**Merchant Types**:
- `home-grower`: Home-based vegetable growers
- `organic-farmer`: Certified organic farmers
- `local-farmer`: Local traditional farmers

**Logic Flow**:
1. Checks for existing merchant with email/phone
2. Creates merchant with `verificationStatus: 'pending'`
3. Generates authentication token
4. Returns merchant data (access restricted until admin approval)

**Response**:
```json
{
  "success": true,
  "message": "Merchant registered. Waiting for admin approval.",
  "data": {
    "merchant": {
      "id": "merchant_id",
      "name": "Farmer Name",
      "businessName": "Green Valley Farm",
      "verificationStatus": "pending"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Business Rules**:
- Merchant can login but cannot access protected routes until approved
- Admin notification should be triggered (TODO in code)
- Verification typically takes 24-48 hours

---

### 4. `merchantLogin(req, res)`

**Purpose**: Authenticates a merchant account.

**Access**: Public

**Request**:
```json
{
  "email": "farmer@example.com",
  "password": "securePassword123"
}
```

**Logic Flow**:
1. Finds merchant with password field
2. Verifies password
3. Checks if account is blocked
4. Updates last login timestamp
5. Generates JWT token
6. Returns merchant profile with store status

**Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "merchant": {
      "id": "merchant_id",
      "name": "Farmer Name",
      "businessName": "Green Valley Farm",
      "verificationStatus": "approved",
      "isStoreOpen": true
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Access Control**:
- Middleware checks `verificationStatus === 'approved'` for protected routes
- Blocked merchants cannot login

---

### 5. `adminLogin(req, res)`

**Purpose**: Authenticates an administrator.

**Access**: Public (but credentials are strictly controlled)

**Request**:
```json
{
  "email": "admin@greenbasket.com",
  "password": "adminSecurePassword"
}
```

**Logic Flow**:
1. Finds admin by email
2. Verifies password
3. Updates last login
4. Generates admin JWT
5. Returns admin profile with permissions

**Response**:
```json
{
  "success": true,
  "message": "Admin login successful",
  "data": {
    "admin": {
      "id": "admin_id",
      "name": "Admin Name",
      "role": "super-admin",
      "permissions": ["manage_users", "manage_merchants", "manage_orders"]
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Security Considerations**:
- Admin accounts should have 2FA (future enhancement)
- IP whitelisting recommended
- Audit logging for all admin actions

---

### 6. `verifyEmail(req, res)`

**Purpose**: Verifies user's email address using token from verification email.

**Access**: Public

**Request**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Logic Flow**:
1. Decodes and verifies JWT token
2. Finds user by ID from token payload
3. Sets `isEmailVerified: true`
4. Saves user document

**Response**:
```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

**Error Handling**:
- 400: Invalid or expired token
- 404: User not found

**Token Expiry**: 24 hours

---

### 7. `forgotPassword(req, res)`

**Purpose**: Initiates password reset process.

**Access**: Public

**Request**:
```json
{
  "email": "john@example.com"
}
```

**Logic Flow**:
1. Finds user by email
2. Generates password reset token (1 hour validity)
3. Sends email with reset link
4. Returns success message (doesn't reveal if email exists for security)

**Response**:
```json
{
  "success": true,
  "message": "Password reset link sent to your email"
}
```

**Email Content**:
- Reset link: `${FRONTEND_URL}/reset-password?token=${resetToken}`
- Token expires in 1 hour
- One-time use only

**Security**:
- Doesn't confirm if email exists (prevents enumeration)
- Short token expiry
- Token invalidated after use

---

### 8. `resetPassword(req, res)`

**Purpose**: Sets new password using valid reset token.

**Access**: Public

**Request**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "newPassword": "newSecurePassword123"
}
```

**Logic Flow**:
1. Verifies reset token
2. Finds user from token payload
3. Updates password (auto-hashed by model)
4. Sets `passwordChangedAt` timestamp
5. Saves user

**Response**:
```json
{
  "success": true,
  "message": "Password reset successful"
}
```

**Error Handling**:
- 400: Invalid or expired token
- 404: User not found

**Security Features**:
- Old sessions should be invalidated (implement token blacklist)
- Password strength validation (implement in middleware)
- Notification email sent to user

---

### 9. `refreshToken(req, res)`

**Purpose**: Issues a new access token without requiring re-login.

**Access**: Requires valid (possibly expired) token

**Request**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Logic Flow**:
1. Verifies existing token
2. Extracts user ID and type
3. Generates new token with fresh expiry
4. Returns new token

**Response**:
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Use Case**:
- Extend user session without re-login
- Implement sliding session expiry
- Mobile app token refresh

---

### 10. `logout(req, res)`

**Purpose**: Acknowledges logout (client-side token removal).

**Access**: Public

**Logic**:
- Since JWT is stateless, actual logout happens client-side
- This endpoint can be used for logging/analytics
- Future: Implement token blacklist for immediate revocation

**Response**:
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## JWT Token Structure

```javascript
{
  "id": "user_id",
  "userType": "user", // or "merchant" or "admin"
  "iat": 1234567890,
  "exp": 1234654290
}
```

**Token Types**:
- **Access Token**: Main authentication (7 days default)
- **Verification Token**: Email verification (24 hours)
- **Reset Token**: Password reset (1 hour)

---

## Security Best Practices

1. **Password Hashing**: bcrypt with salt rounds (12+)
2. **Token Security**: Strong secret, appropriate expiry
3. **Rate Limiting**: Prevent brute force attacks
4. **HTTPS Only**: All auth endpoints must use HTTPS
5. **Input Validation**: Sanitize all inputs
6. **Error Messages**: Don't reveal if email exists
7. **Session Management**: Track active sessions

---

## Error Response Format

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error (only in development)"
}
```

---

## Future Enhancements

1. **OAuth Integration**: Google, Facebook login
2. **Two-Factor Authentication**: SMS/Email OTP
3. **Biometric Authentication**: For mobile apps
4. **Token Blacklist**: Immediate logout capability
5. **Password Policies**: Strength requirements, expiry
6. **Account Recovery**: Security questions, backup codes
7. **Login History**: Track devices and locations
