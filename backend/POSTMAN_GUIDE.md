# Green Basket Postman Guide

This guide will help you test the entire Green Basket backend using Postman.

## 1. Import the Collection
1. Open **Postman**.
2. Click **Import** (top left).
3. Drag and drop `postman/GreenBasket.postman_collection.json` (regenerate it with `node scripts/generate-postman.js`).
4. You should see a generic collection named "Green Basket API Backup Test" (or similar).

## 2. Set Up Environment Variables
To make the requests work seamlessly, you need to set up an **Environment** in Postman.

1. Click on **Environments** (left sidebar).
2. Click **+** to create a new environment. Name it `Green Basket Dev`.
3. Add the following variables:

| Variable | Initial Value | Current Value | Description |
|---|---|---|---|
| `base_url` | `http://localhost:5001` | `http://localhost:5001` | Your backend URL |
| `token` | *(Leave Empty)* | *(Leave Empty)* | **Active Token**. Update this with the token of the user/merchant you are currently testing as. |
| `user_token` | *(Leave Empty)* | *(Leave Empty)* | Backup variable to store a User token. |
| `merchant_token` | *(Leave Empty)* | *(Leave Empty)* | Backup variable to store a Merchant token. |
| `admin_token` | *(Leave Empty)* | *(Leave Empty)* | Backup variable to store an Admin token. |
| `id` | *(Leave Empty)* | *(Leave Empty)* | Common ID variable used in routes like `/api/products/{{id}}`. |
| `productId` | *(Leave Empty)* | *(Leave Empty)* | Specific ID variable for Cart/Review routes. |
| `orderId` | *(Leave Empty)* | *(Leave Empty)* | Specific ID variable for Order routes. |

4. **Select the Environment**: In the top right corner dropdown (next to the "Send" button), select `Green Basket Dev`.

## 3. Testing Flow

### Step 1: Authentication
1. Go to the **Authentication** folder.
2. Open `userSignup` or `merchantSignup`.
3. **Body**: Update the JSON body with a new email/password.
   ```json
   {
       "name": "Test User",
       "email": "test@example.com",
       "password": "password123",
       "phone": "9876543210"
   }
   ```
4. **Send**: You should get a success response.
5. Open `userLogin` or `merchantLogin`. Use the credentials you just created.
6. **Copy the Token**: In the response `data.token`, verify you received a JWT string.
   - **Manual**: Copy this string and paste it into your Environment's `token` current value.
   - **Automatic (Advanced)**: Add this to the "Tests" tab of the Login request:
     ```javascript
     var jsonData = pm.response.json();
     pm.environment.set("token", jsonData.data.token);
     ```

### Step 2: Testing Features
Now that you have the `token` variable set, all other requests will automatically use it because they are configured with `Authorization: Bearer {{token}}`.

- **Products**: Use `create` (as merchant) to add products. Note that you may need to switch tokens (create a `merchant_token` variable if testing both simultaneously).
- **Cart**: Use `addToCart` with a valid `productId` (copy an ID from the `getAll` products response).
- **Orders**: Create an order after adding items to the cart.

#### New Integration Verifications
1.  **SendGrid Contact Sync**:
    - Sign up a **new user** via `userSignup`.
    - Check your SendGrid Dashboard -> Marketing -> Contacts.
    - The new user should appear in your list automatically.

2.  **Redis Cache (Implicit)**:
    - Redis is now active. While there isn't a direct "Test Redis" API, it handles session management and caching internally.
    - If APIs are responding fast and stable, Redis is doing its job!

3.  **SMS Notifications**:
    - Trigger an event (like placing an order).
    - If you used a verified phone number, you should receive an SMS via Twilio.

## 4. Troubleshooting
- **401 Unauthorized**: Your token is missing or expired. Login again and update the `token` variable.
- **403 Forbidden**: You are trying to access a route with the wrong role (e.g., accessing Merchant routes as a User). Login as the correct role.
- **404 Not Found**: The ID you used in the URL (`:id` or `{{id}}`) is incorrect. Make sure to replace it with a real MongoDB ID from a previous response.

## 5. Notes
- The collection uses `{{base_url}}` so you can easily switch to a production URL later.
- Some endpoints require specific IDs (like `:productId`). You must manually replace these in the URL bar or creating variables for them.

Happy Testing! 🚀
