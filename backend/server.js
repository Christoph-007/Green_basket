const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

// Import config
const connectDB = require('./src/config/database');
const { initializeSocket } = require('./src/config/socket');

// Import routes
const authRoutes = require('./src/routes/authRoutes');
const productRoutes = require('./src/routes/productRoutes');
const homeRoutes = require('./src/routes/homeRoutes');
const categoryRoutes = require('./src/routes/categoryRoutes');
const orderRoutes = require('./src/routes/orderRoutes');
const cartRoutes = require('./src/routes/cartRoutes');
const recipeRoutes = require('./src/routes/recipeRoutes');
const userRoutes = require('./src/routes/userRoutes');
const merchantRoutes = require('./src/routes/merchantRoutes');
const adminRoutes = require('./src/routes/adminRoutes');
const reviewRoutes = require('./src/routes/reviewRoutes');
const paymentRoutes = require('./src/routes/paymentRoutes');
const notificationRoutes = require('./src/routes/notificationRoutes');
const wishlistRoutes = require('./src/routes/wishlistRoutes');
const loyaltyRoutes = require('./src/routes/loyaltyRoutes');
const offerRoutes = require('./src/routes/offerRoutes');
const merchantAnalyticsRoutes = require('./src/routes/merchantAnalyticsRoutes');
const deliveryZoneRoutes = require('./src/routes/deliveryZoneRoutes');
const preBookingRoutes = require('./src/routes/preBookingRoutes');
const disputeRoutes = require('./src/routes/disputeRoutes');
const financialRoutes = require('./src/routes/financialRoutes');
const bulkOperationsRoutes = require('./src/routes/bulkOperationsRoutes');
const searchRoutes = require('./src/routes/searchRoutes');
const returnRoutes = require('./src/routes/returnRoutes');
const walletRoutes = require('./src/routes/walletRoutes');
const referralRoutes = require('./src/routes/referralRoutes');

// Import middlewares
const { notFound, errorHandler } = require('./src/middlewares/errorMiddleware');
const { apiLimiter } = require('./src/middlewares/rateLimitMiddleware');

// Refuse to run in production with a missing or example JWT secret
if (process.env.NODE_ENV === 'production') {
    const secret = process.env.JWT_SECRET || '';
    if (!secret || /change-this|your-super-secret/i.test(secret)) {
        console.error('❌ JWT_SECRET is missing or still the example value. Set a long random secret.');
        process.exit(1);
    }
    if (secret.length < 32) console.warn('⚠️  JWT_SECRET is shorter than 32 characters; use a longer random secret.');
    if (!process.env.REFRESH_TOKEN_SECRET) console.warn('⚠️  REFRESH_TOKEN_SECRET is not set; set a separate secret for refresh tokens.');
}

// Initialize express app
const app = express();
const server = http.createServer(app);

// Initialize Socket.IO
initializeSocket(server);

// Middleware
app.use(helmet());
app.use(cors({
    origin: require('./src/config/cors').corsOrigin,
    credentials: true
}));

// Webhook route (must be before express.json to handle raw body)
app.use(
    '/api/payment/webhook',
    express.raw({ type: 'application/json' }),
    require('./src/routes/paymentWebhookRoute')
);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Performance profiling middleware
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        console.log(`[PERF] ${req.method} ${req.url} - ${res.statusCode} (${duration}ms)`);
    });
    next();
});

// Rate limiting
app.use('/api/', apiLimiter);

// Number of routes actually mounted (the /api listing used to hard-code it)
const countRoutes = (expressApp) => {
    let count = 0;
    const walk = (stack) => (stack || []).forEach(layer => {
        if (layer.route) count += Object.keys(layer.route.methods).length;
        else if (layer.handle && layer.handle.stack) walk(layer.handle.stack);
    });
    walk(expressApp._router && expressApp._router.stack);
    return count;
};

// Health check route
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'Green Basket API is running',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});

// API Documentation endpoint
app.get('/api', (req, res) => {
    res.json({
        success: true,
        message: 'Green Basket API',
        version: '1.0.0',
        totalAPIs: countRoutes(app), // counted from the mounted routers
        endpoints: {
            authentication: {
                userSignup: 'POST /api/auth/user/signup',
                userLogin: 'POST /api/auth/user/login',
                verifyEmail: 'POST /api/auth/user/verify-email',
                forgotPassword: 'POST /api/auth/user/forgot-password',
                resetPassword: 'POST /api/auth/user/reset-password',
                merchantSignup: 'POST /api/auth/merchant/signup',
                merchantLogin: 'POST /api/auth/merchant/login',
                adminLogin: 'POST /api/auth/admin/login',
                refreshToken: 'POST /api/auth/refresh-token',
                logout: 'POST /api/auth/logout'
            },
            products: {
                getAll: 'GET /api/products',
                search: 'GET /api/products/search',
                getById: 'GET /api/products/:id',
                create: 'POST /api/products (Merchant)',
                update: 'PUT /api/products/:id (Merchant)',
                delete: 'DELETE /api/products/:id (Merchant)',
                updateStock: 'PATCH /api/products/:id/stock (Merchant)',
                getMyProducts: 'GET /api/products/merchant/my-products (Merchant)'
            },
            categories: {
                getAll: 'GET /api/categories',
                getById: 'GET /api/categories/:id',
                create: 'POST /api/categories (Admin)',
                update: 'PUT /api/categories/:id (Admin)',
                delete: 'DELETE /api/categories/:id (Admin)'
            },
            cart: {
                getCart: 'GET /api/cart',
                addToCart: 'POST /api/cart/add',
                updateItem: 'PUT /api/cart/update/:productId',
                removeItem: 'DELETE /api/cart/remove/:productId',
                clearCart: 'DELETE /api/cart/clear',
                addRecipe: 'POST /api/cart/recipe-to-cart'
            },
            orders: {
                create: 'POST /api/orders',
                getMyOrders: 'GET /api/orders/my-orders',
                getById: 'GET /api/orders/:id',
                cancel: 'PATCH /api/orders/:id/cancel',
                getMerchantOrders: 'GET /api/orders/merchant/orders (Merchant)',
                updateStatus: 'PATCH /api/orders/merchant/:id/status (Merchant)',
                updateLocation: 'PATCH /api/orders/:id/location (User/Merchant)'
            },
            recipes: {
                getAll: 'GET /api/recipes',
                search: 'GET /api/recipes/search',
                getById: 'GET /api/recipes/:id',
                calculateIngredients: 'POST /api/recipes/:id/calculate-ingredients',
                create: 'POST /api/recipes (Admin)',
                update: 'PUT /api/recipes/:id (Admin)',
                delete: 'DELETE /api/recipes/:id (Admin)'
            },
            reviews: {
                getProductReviews: 'GET /api/reviews/product/:productId',
                getMerchantReviews: 'GET /api/reviews/merchant/:merchantId',
                deleteReview: 'DELETE /api/reviews/:id'
            },
            users: {
                getProfile: 'GET /api/users/profile',
                updateProfile: 'PUT /api/users/profile',
                getAddresses: 'GET /api/users/addresses',
                addAddress: 'POST /api/users/addresses',
                updateAddress: 'PUT /api/users/addresses/:id',
                deleteAddress: 'DELETE /api/users/addresses/:id',
                getNotificationPreferences: 'GET /api/users/notification-preferences',
                updateNotificationPreferences: 'PUT /api/users/notification-preferences',
                registerFCMToken: 'POST /api/users/fcm-token',
                removeFCMToken: 'DELETE /api/users/fcm-token'
            },
            merchants: {
                getProfile: 'GET /api/merchants/profile',
                updateProfile: 'PUT /api/merchants/profile',
                toggleStore: 'PATCH /api/merchants/toggle-store',
                getDashboard: 'GET /api/merchants/dashboard-stats'
            },
            admin: {
                getPendingMerchants: 'GET /api/admin/merchants/pending',
                verifyMerchant: 'PATCH /api/admin/merchants/:id/verify',
                getUsers: 'GET /api/admin/users',
                toggleUserBlock: 'PATCH /api/admin/users/:id/block',
                getPlatformStats: 'GET /api/admin/stats'
            },
            payment: {
                createOrder: 'POST /api/payment/create-order',
                verifyPayment: 'POST /api/payment/verify',
                processRefund: 'POST /api/payment/refund'
            },
            notifications: {
                getNotifications: 'GET /api/notifications',
                getUnreadCount: 'GET /api/notifications/unread-count',
                markAsRead: 'PATCH /api/notifications/:id/read',
                markAllAsRead: 'PATCH /api/notifications/read-all',
                deleteNotification: 'DELETE /api/notifications/:id',
                clearAll: 'DELETE /api/notifications/clear-all',
                sendTest: 'POST /api/notifications/admin/test (Admin)',
                bulkSend: 'POST /api/notifications/admin/bulk-send (Admin)'
            },
            wishlist: {
                getWishlist: 'GET /api/wishlist',
                addToWishlist: 'POST /api/wishlist/add',
                removeFromWishlist: 'DELETE /api/wishlist/remove/:productId',
                moveToCart: 'POST /api/wishlist/move-to-cart/:productId',
                checkWishlisted: 'GET /api/wishlist/check/:productId'
            },
            wallet: {
                getWallet: 'GET /api/wallet',
                getTransactions: 'GET /api/wallet/transactions',
                addMoney: 'POST /api/wallet/add-money',
                verifyTopup: 'POST /api/wallet/verify-topup',
                useForPayment: 'POST /api/wallet/use-for-payment',
                adminCredit: 'POST /api/wallet/admin/credit (Admin)',
                lockUnlock: 'PATCH /api/wallet/admin/:userId/lock (Admin)',
                creditRefund: 'POST /api/wallet/credit-refund (Admin)'
            },
            loyalty: {
                redeemPoints: 'POST /api/loyalty/redeem',
                getHistory: 'GET /api/loyalty/history',
                getBenefits: 'GET /api/loyalty/benefits',
                awardPoints: 'POST /api/loyalty/award (Admin)'
            },
            referral: {
                generateCode: 'POST /api/referral/generate (User)',
                getStats: 'GET /api/referral/stats (User)',
                applyCode: 'POST /api/referral/apply (User)',
                validateCode: 'GET /api/referral/validate/:code',
                processReward: 'POST /api/referral/process-reward (Admin)'
            },
            offers: {
                createOffer: 'POST /api/offers (Merchant/Admin)',
                getMerchantOffers: 'GET /api/offers/merchant (Merchant)',
                getAvailableOffers: 'GET /api/offers/available (User)',
                applyCoupon: 'POST /api/offers/cart/apply-coupon (User)',
                removeCoupon: 'DELETE /api/offers/cart/remove-coupon (User)',
                updateOffer: 'PUT /api/offers/:id (Merchant/Admin)',
                deleteOffer: 'DELETE /api/offers/:id (Merchant/Admin)',
                getOfferAnalytics: 'GET /api/offers/:id/analytics (Merchant/Admin)',
                getFlashSales: 'GET /api/offers/flash-sales',
                getAllOffers: 'GET /api/offers/admin/all (Admin)'
            },
            merchantAnalytics: {
                salesAnalytics: 'GET /api/merchants/analytics/sales (Merchant)',
                productAnalytics: 'GET /api/merchants/analytics/products (Merchant)',
                customerAnalytics: 'GET /api/merchants/analytics/customers (Merchant)',
                inventoryAnalytics: 'GET /api/merchants/analytics/inventory (Merchant)',
                revenueForecast: 'GET /api/merchants/analytics/forecast (Merchant)',
                reviewAnalytics: 'GET /api/merchants/analytics/reviews (Merchant)'
            },
            deliveryZones: {
                setLocation: 'PUT /api/merchants/zones/location (Merchant)',
                getZones: 'GET /api/merchants/zones/delivery-zones (Merchant)',
                addZone: 'POST /api/merchants/zones/delivery-zones (Merchant)',
                updateZone: 'PUT /api/merchants/zones/delivery-zones/:zoneId (Merchant)',
                deleteZone: 'DELETE /api/merchants/zones/delivery-zones/:zoneId (Merchant)',
                checkDelivery: 'POST /api/merchants/zones/check-delivery',
                getNearbyMerchants: 'POST /api/merchants/zones/nearby'
            },
            preBooking: {
                create: 'POST /api/prebooking (User)',
                getMyPreBookings: 'GET /api/prebooking/my-prebookings (User)',
                cancel: 'DELETE /api/prebooking/:id (User)',
                convertToOrder: 'POST /api/prebooking/:id/convert-to-order (User)',
                markAvailable: 'PATCH /api/prebooking/products/:id/mark-available (Merchant)',
                getAllPreBookings: 'GET /api/prebooking/admin/all (Admin)'
            },
            disputes: {
                raiseDispute: 'POST /api/disputes (User)',
                getMyDisputes: 'GET /api/disputes/my-disputes (User)',
                getDisputeById: 'GET /api/disputes/:id (User/Admin)',
                addMessage: 'POST /api/disputes/:id/message (User/Admin)',
                escalate: 'PATCH /api/disputes/:id/escalate (User)',
                getAllDisputes: 'GET /api/disputes/admin/all (Admin)',
                resolveDispute: 'PUT /api/disputes/admin/:id/resolve (Admin)',
                updateStatus: 'PATCH /api/disputes/admin/:id/status (Admin)'
            },
            financial: {
                getMerchantEarnings: 'GET /api/financial/merchants/earnings (Merchant)',
                getMerchantPayouts: 'GET /api/financial/merchants/payouts (Merchant)',
                getPayoutById: 'GET /api/financial/payouts/:id (Merchant/Admin)',
                getAllPayouts: 'GET /api/financial/admin/payouts (Admin)',
                generatePayouts: 'POST /api/financial/admin/payouts/generate (Admin)',
                processPayout: 'POST /api/financial/admin/payouts/:id/process (Admin)',
                holdPayout: 'PATCH /api/financial/admin/payouts/:id/hold (Admin)',
                getFinancialReports: 'GET /api/financial/admin/reports/financial (Admin)',
                getGSTReport: 'GET /api/financial/admin/reports/gst (Admin)',
                updateCommission: 'PUT /api/financial/admin/settings/commission (Admin)'
            },
            bulkOperations: {
                bulkUpload: 'POST /api/bulk/products/bulk-upload (Merchant)',
                bulkUpdatePrice: 'PUT /api/bulk/products/bulk-update-price (Merchant)',
                bulkUpdateStock: 'PUT /api/bulk/products/bulk-update-stock (Merchant)',
                exportProducts: 'GET /api/bulk/products/export (Merchant)'
            },
            search: {
                advancedSearch: 'GET /api/search/products',
                suggestions: 'GET /api/search/suggestions',
                trending: 'GET /api/search/trending'
            },
            returns: {
                requestReturn: 'POST /api/returns (User)',
                getMyReturns: 'GET /api/returns/my-returns (User)',
                getReturnById: 'GET /api/returns/:id (User/Admin)',
                cancelReturn: 'DELETE /api/returns/:id (User)',
                getAllReturns: 'GET /api/returns/admin/all (Admin)',
                processReturn: 'PUT /api/returns/admin/:id/process (Admin)'
            },
        },
        features: {
            implemented: [
                'Payment Gateway Integration (3 APIs)',
                'Comprehensive Notification System (8 APIs)',
                'Wishlist System (5 APIs)',
                'Wallet & Credits System (8 APIs)',
                'Loyalty Points Redemption (4 APIs)',
                'Referral System (5 APIs)',
                'Offers & Promotions (10 APIs)',
                'Merchant Analytics (6 APIs)',
                'Delivery Zone Management (7 APIs)',
                'Pre-Booking System (6 APIs)',
                'Dispute Management (8 APIs)',
                'Financial Management & Payouts (10 APIs)',
                'Merchant Bulk Operations (4 APIs)',
                'Advanced Search & Filters (3 APIs)',
                'Returns & Exchange System (6 APIs)'
            ],
        },
        documentation: 'See /backend/docs/ for detailed API documentation',
        health: 'GET /api/health'
    });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/home', homeRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/recipes', recipeRoutes);
app.use('/api/users', userRoutes);
app.use('/api/merchants', merchantRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/wishlist', wishlistRoutes);
app.use('/api/loyalty', loyaltyRoutes);
app.use('/api/offers', offerRoutes);
app.use('/api/merchants/analytics', merchantAnalyticsRoutes);
app.use('/api/merchants/zones', deliveryZoneRoutes);
app.use('/api/prebooking', preBookingRoutes);
app.use('/api/disputes', disputeRoutes);
app.use('/api/financial', financialRoutes);
app.use('/api/bulk', bulkOperationsRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/returns', returnRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/referral', referralRoutes);

// Error handling
app.use(notFound);
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 5002;

if (require.main === module) {
    // Database connection
    connectDB();

    // Initialize Cron Jobs
    require('./src/utils/cronJobs')();

    server.listen(PORT, '0.0.0.0', () => {
        console.log('='.repeat(50));
        console.log(`🚀 Server running on port ${PORT} (0.0.0.0)`);
        console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
        console.log(`📡 API: http://localhost:${PORT}/api`);
        console.log('='.repeat(50));
    });
}

// Handle unhandled rejections
// Graceful shutdown: stop accepting requests, close the DB, then exit.
// (Previously SIGTERM only called server.close(), and the open MongoDB
// connection kept the process alive until the host force-killed it.)
let shuttingDown = false;
const shutdown = (reason, exitCode) => {
    if (shuttingDown) return;
    shuttingDown = true;
    console.log(`👋 ${reason} received, shutting down gracefully`);
    const force = setTimeout(() => {
        console.error('⏱  Forced exit after 10s');
        process.exit(exitCode);
    }, 10000);
    force.unref();
    server.close(async () => {
        try {
            await require('mongoose').connection.close();
        } catch (_) { /* already closed */ }
        console.log('💤 Process terminated');
        process.exit(exitCode);
    });
    // Keep-alive sockets would otherwise hold server.close() open
    if (typeof server.closeIdleConnections === 'function') server.closeIdleConnections();
};

process.on('unhandledRejection', (err) => {
    console.error('❌ Unhandled Rejection:', err);
    shutdown('Unhandled rejection', 1);
});
process.on('SIGTERM', () => shutdown('SIGTERM', 0));
process.on('SIGINT', () => shutdown('SIGINT', 0));

module.exports = app;
