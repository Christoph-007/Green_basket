# Green Basket Backend

A comprehensive backend API for the Green Basket marketplace platform connecting farmers with consumers.

## 🚀 Features

- **User Authentication**: JWT-based authentication for Users, Merchants, and Admins
- **Real-time Updates**: Socket.IO integration for live order tracking and notifications
- **Product Management**: Complete CRUD operations for products with image uploads
- **Order Management**: Order creation, tracking, and status updates
- **Recipe System**: Recipe-to-cart feature with automatic ingredient calculation
- **Payment Integration**: Razorpay payment gateway integration
- **Email Notifications**: Automated email notifications using Nodemailer
- **Image Storage**: Cloudinary integration for image uploads and optimization

## 📋 Prerequisites

- Node.js v18+ LTS
- MongoDB (local or Atlas)
- Cloudinary account (for image uploads)
- Gmail account (for email notifications)
- Razorpay account (for payments)

## 🛠️ Installation

1. **Clone the repository**
```bash
cd backend
```

2. **Install dependencies**
```bash
npm install
```

3. **Configure environment variables**

Copy `.env.example` to `.env` and update the values:

```bash
cp .env.example .env
```

Update the following in `.env`:
- `MONGODB_URI`: Your MongoDB connection string
- `JWT_SECRET`: A secure random string (min 32 characters)
- `CLOUDINARY_*`: Your Cloudinary credentials
- `EMAIL_*`: Your Gmail credentials (use App Password)
- `KEY_ID` / `KEY_SECRET`: Your Razorpay API keys (the server will not start without `KEY_ID`)

4. **Start the server**

Development mode:
```bash
npm run dev
```

The server listens on port **5002** by default (`PORT` in `.env`); the Flutter app expects that port.

Production mode:
```bash
npm start
```

## 📁 Project Structure

```
backend/
├── src/
│   ├── config/          # Configuration files
│   ├── models/          # Mongoose models
│   ├── controllers/     # Route controllers
│   ├── routes/          # API routes
│   ├── middlewares/     # Custom middlewares
│   ├── services/        # Business logic services
│   ├── sockets/         # Socket.IO handlers
│   └── utils/           # Utility functions
├── .env                 # Environment variables
├── server.js            # Main server file
└── package.json         # Dependencies
```

## 🔑 API Endpoints

### Authentication
- `POST /api/auth/user/signup` - User registration
- `POST /api/auth/user/login` - User login
- `POST /api/auth/merchant/signup` - Merchant registration
- `POST /api/auth/merchant/login` - Merchant login
- `POST /api/auth/admin/login` - Admin login

### Products
- `GET /api/products` - Get all products
- `GET /api/products/:id` - Get product by ID
- `POST /api/products` - Create product (Merchant)
- `PUT /api/products/:id` - Update product (Merchant)
- `DELETE /api/products/:id` - Delete product (Merchant)

### Orders
- `POST /api/orders` - Create order
- `GET /api/orders/my-orders` - Get user orders
- `GET /api/orders/merchant/orders` - Get merchant orders
- `PATCH /api/orders/merchant/:id/status` - Update order status

### Cart
- `GET /api/cart` - Get cart
- `POST /api/cart/add` - Add to cart
- `PUT /api/cart/update/:productId` - Update cart item
- `DELETE /api/cart/remove/:productId` - Remove from cart
- `POST /api/cart/recipe-to-cart` - Add recipe ingredients to cart

### Recipes
- `GET /api/recipes` - Get all recipes
- `GET /api/recipes/:id` - Get recipe by ID
- `POST /api/recipes/:id/calculate-ingredients` - Calculate ingredients for servings
- `POST /api/recipes` - Create recipe (Admin)

## 🔌 Socket.IO Events

### Client → Server
- `connection` - Establish connection with JWT token

### Server → Client
- `new_order` - New order notification (Merchant)
- `order_status_update` - Order status changed (Customer)
- `notification` - General notification
- `low_stock_alert` - Low stock alert (Merchant)

## 🗄️ Database Models

- **User**: Customer accounts with loyalty points and wallet
- **Merchant**: Farmer/grower accounts with verification
- **Product**: Product catalog with inventory
- **Order**: Order management with status tracking
- **Recipe**: Recipes with ingredient linking
- **Cart**: Shopping cart management
- **Category**: Product categorization
- **Address**: User delivery addresses
- **Review**: Product and merchant reviews
- **Notification**: User notifications

## 🔐 Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_token>
```

## 📧 Email Configuration

For Gmail, you need to:
1. Enable 2-Factor Authentication
2. Generate an App Password
3. Use the App Password in `EMAIL_APP_PASSWORD`

## 🖼️ Image Upload

Images are uploaded to Cloudinary and optimized using Sharp:
- Max file size: 5MB
- Automatic optimization
- Multiple image support for products

## 🚀 Deployment

### Deploy to Render.com

1. Push code to GitHub
2. Create new Web Service on Render
3. Connect your repository
4. Add environment variables
5. Deploy!

The server will automatically use the `PORT` environment variable provided by Render.

## 🧪 Testing

Test the API using:
- Postman
- Thunder Client (VS Code)
- cURL

Example:
```bash
curl http://localhost:5000/api/health
```

## 📝 Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `PORT` | Server port | No (default: 5000) |
| `MONGODB_URI` | MongoDB connection string | Yes |
| `JWT_SECRET` | JWT secret key | Yes |
| `FRONTEND_URL` | Frontend URL for CORS | No |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name | Yes |
| `CLOUDINARY_API_KEY` | Cloudinary API key | Yes |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | Yes |
| `EMAIL_USER` | Gmail address | Yes |
| `EMAIL_APP_PASSWORD` | Gmail app password | Yes |
| `KEY_ID` | Razorpay key ID | Yes |
| `KEY_SECRET` | Razorpay key secret | Yes |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License

## 👥 Support

For support, email support@greenbasket.com or open an issue in the repository.

---

Built with ❤️ by the Green Basket Team
