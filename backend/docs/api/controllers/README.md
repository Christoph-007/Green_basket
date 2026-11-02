# Controllers Documentation

This directory contains detailed documentation for each controller in the Green Basket backend application.

## 📁 Documentation Files

### Core Controllers

1. **[Admin Controller](./adminController.md)**
   - Merchant verification and approval
   - User management (blocking/unblocking)
   - Platform-wide statistics and analytics
   - Administrative operations

2. **[Auth Controller](./authController.md)**
   - User, Merchant, and Admin authentication
   - Registration and login flows
   - Email verification
   - Password reset functionality
   - JWT token management

3. **[User Controller](./userController.md)**
   - User profile management
   - Dietary preferences and allergies
   - Address book (CRUD operations)
   - Notification settings
   - Loyalty points tracking

4. **[Merchant Controller](./merchantController.md)**
   - Merchant profile management
   - Store status (open/closed)
   - Dashboard statistics
   - Business settings and hours

### Product & Catalog

5. **[Product Controller](./productController.md)**
   - Product catalog management
   - Image upload (Cloudinary integration)
   - Inventory/stock management
   - Product search functionality
   - Merchant product listings

6. **[Recipe Controller](./recipeController.md)**
   - Recipe catalog browsing
   - **Intelligent ingredient calculator** ⭐
   - Recipe-to-cart conversion
   - Admin recipe management

### Shopping & Orders

7. **[Cart Controller](./cartController.md)**
   - Shopping cart operations
   - Add/update/remove items
   - **Recipe-to-cart feature** ⭐
   - Cart total calculation

8. **[Order Controller](./orderController.md)**
   - Order creation and processing
   - **Real-time Socket.IO notifications** 🔔
   - Order status updates
   - Order cancellation
   - Stock management integration

9. **[Subscription Controller](./subscriptionController.md)**
   - Recurring delivery subscriptions
   - Subscription management (pause/resume/cancel)
   - Automated order processing (cron jobs)

### Reviews & Feedback

10. **[Review Controller](./reviewController.md)**
    - Product and merchant reviews
    - Verified purchase reviews
    - Review moderation
    - Rating calculations

---

## 🎯 Quick Reference

### Controller Responsibilities

| Controller | Primary Purpose | Key Features |
|------------|----------------|--------------|
| **Admin** | Platform management | Merchant approval, user blocking, stats |
| **Auth** | Authentication | Login, signup, password reset, JWT |
| **User** | Customer profiles | Profile, addresses, preferences |
| **Merchant** | Merchant operations | Store management, dashboard |
| **Product** | Catalog management | CRUD, images, search, inventory |
| **Recipe** | Recipe system | Browse, ingredient calculator |
| **Cart** | Shopping cart | Add items, recipe-to-cart |
| **Order** | Order processing | Create, track, real-time updates |
| **Subscription** | Recurring orders | Auto-delivery, scheduling |
| **Review** | Feedback system | Ratings, reviews, moderation |

---

## 🔑 Key Features Across Controllers

### Real-Time Features (Socket.IO)
- **Order Controller**: New order notifications, status updates
- **Inventory Socket**: Stock level alerts
- **Notification Socket**: General notifications

### Image Management (Cloudinary)
- **Product Controller**: Multiple product images
- **Review Controller**: Photo reviews
- **User/Merchant Controllers**: Profile images

### Authentication & Authorization
- **JWT-based**: Stateless authentication
- **Role-based**: User, Merchant, Admin roles
- **Middleware**: Protected routes and ownership validation

### Business Intelligence
- **Merchant Dashboard**: Revenue, orders, low stock
- **Admin Dashboard**: Platform statistics
- **Product Analytics**: Views, sales, ratings

---

## 📊 Data Flow Examples

### Order Creation Flow
```
Customer → Cart Controller → Order Controller → Product Controller (stock update)
                                ↓
                          Socket.IO Notification
                                ↓
                            Merchant
```

### Recipe-to-Cart Flow
```
Customer → Recipe Controller (calculate ingredients)
              ↓
         Product Matching
              ↓
         Cart Controller (add items)
```

### Subscription Processing
```
Cron Job → Subscription Controller → Order Controller
                                          ↓
                                    Auto-create order
```

---

## 🔒 Security Patterns

All controllers implement:

1. **Authentication**: JWT token validation
2. **Authorization**: Role-based access control
3. **Ownership Validation**: Users can only access their own data
4. **Input Validation**: Express-validator middleware
5. **Error Handling**: Consistent error responses

---

## 📝 Response Format

All controllers follow a consistent response structure:

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { /* response data */ }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error (development only)"
}
```

### Paginated Response
```json
{
  "success": true,
  "data": {
    "items": [ /* array of items */ ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 156,
      "pages": 16
    }
  }
}
```

---

## 🚀 Future Enhancements

### Planned Features
- [ ] Advanced search and filtering
- [ ] Bulk operations for merchants
- [ ] Analytics dashboard
- [ ] Multi-language support
- [ ] Advanced notification system
- [ ] AI-based recommendations
- [ ] Inventory forecasting
- [ ] Dynamic pricing

### Performance Optimizations
- [ ] Redis caching layer
- [ ] Database query optimization
- [ ] CDN integration
- [ ] Rate limiting per user tier
- [ ] Background job processing

---

## 📚 Related Documentation

- **Models**: `/backend/src/models/` - Database schemas
- **Routes**: `/backend/src/routes/` - API endpoints
- **Middleware**: `/backend/src/middleware/` - Authentication, validation
- **Services**: `/backend/src/services/` - Business logic helpers
- **Sockets**: `/backend/src/sockets/` - Real-time features

---

## 🛠️ Development Guidelines

### Adding a New Controller

1. Create controller file in `src/controllers/`
2. Implement methods with try-catch error handling
3. Add JSDoc comments for documentation
4. Create corresponding routes
5. Add authentication/authorization middleware
6. Write unit tests
7. Document in this directory

### Controller Best Practices

- **Single Responsibility**: Each method should do one thing
- **Error Handling**: Always use try-catch blocks
- **Validation**: Validate input before processing
- **Logging**: Log important operations
- **Performance**: Use pagination for large datasets
- **Security**: Never trust user input

---

## 📞 Support

For questions or issues related to controllers:
- Review the specific controller documentation
- Check the implementation in `src/controllers/`
- Refer to the API route definitions
- Test endpoints using the provided examples

---

**Last Updated**: January 2024  
**Version**: 1.0.0
