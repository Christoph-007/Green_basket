const fs = require('fs');

const endpoints = {
    Authentication: {
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
    Products: {
        getAll: 'GET /api/products',
        search: 'GET /api/products/search',
        getById: 'GET /api/products/:id',
        create: 'POST /api/products (Merchant)',
        update: 'PUT /api/products/:id (Merchant)',
        delete: 'DELETE /api/products/:id (Merchant)',
        updateStock: 'PATCH /api/products/:id/stock (Merchant)',
        getMyProducts: 'GET /api/products/merchant/my-products (Merchant)'
    },
    Categories: {
        getAll: 'GET /api/categories',
        getById: 'GET /api/categories/:id',
        create: 'POST /api/categories (Admin)',
        update: 'PUT /api/categories/:id (Admin)',
        delete: 'DELETE /api/categories/:id (Admin)'
    },
    Cart: {
        getCart: 'GET /api/cart',
        addToCart: 'POST /api/cart/add',
        updateItem: 'PUT /api/cart/update/:productId',
        removeItem: 'DELETE /api/cart/remove/:productId',
        clearCart: 'DELETE /api/cart/clear',
        addRecipe: 'POST /api/cart/recipe-to-cart'
    },
    Orders: {
        create: 'POST /api/orders',
        getMyOrders: 'GET /api/orders/my-orders',
        getById: 'GET /api/orders/:id',
        cancel: 'PATCH /api/orders/:id/cancel',
        trackOrder: 'GET /api/orders/:id/track',
        getOrderTracking: 'GET /api/orders/:orderId/tracking',
        updateLocation: 'PATCH /api/orders/:id/location (User/Merchant)',
        getMerchantOrders: 'GET /api/orders/merchant/orders (Merchant)',
        updateStatus: 'PATCH /api/orders/merchant/:id/status (Merchant)'
    },
    Recipes: {
        getAll: 'GET /api/recipes',
        search: 'GET /api/recipes/search',
        getById: 'GET /api/recipes/:id',
        calculateIngredients: 'POST /api/recipes/:id/calculate-ingredients',
        create: 'POST /api/recipes (Admin)',
        update: 'PUT /api/recipes/:id (Admin)',
        patchUpdate: 'PATCH /api/recipes/:id (Admin)',
        delete: 'DELETE /api/recipes/:id (Admin)'
    },
    Reviews: {
        getProductReviews: 'GET /api/reviews/product/:productId',
        getMerchantReviews: 'GET /api/reviews/merchant/:merchantId',
        addReview: 'POST /api/reviews (User)',
        getMyReviews: 'GET /api/reviews/my-reviews (User)',
        updateReview: 'PUT /api/reviews/:id (User)',
        deleteReview: 'DELETE /api/reviews/:id (User/Admin)'
    },
    Subscriptions: {
        create: 'POST /api/subscriptions',
        getMySubscriptions: 'GET /api/subscriptions',
        getById: 'GET /api/subscriptions/:id',
        update: 'PUT /api/subscriptions/:id (User)',
        delete: 'DELETE /api/subscriptions/:id (User)',
        updateStatus: 'PATCH /api/subscriptions/:id/status',
        getMerchantAll: 'GET /api/subscriptions/merchant/all (Merchant)'
    },
    Users: {
        getProfile: 'GET /api/users/profile',
        updateProfile: 'PUT /api/users/profile',
        getAddresses: 'GET /api/users/addresses',
        addAddress: 'POST /api/users/addresses',
        updateAddress: 'PUT /api/users/addresses/:id',
        deleteAddress: 'DELETE /api/users/addresses/:id',
        getNotificationPrefs: 'GET /api/users/notification-preferences',
        updateNotificationPrefs: 'PUT /api/users/notification-preferences',
        registerFCMToken: 'POST /api/users/fcm-token',
        removeFCMToken: 'DELETE /api/users/fcm-token'
    },
    Merchants: {
        getProfile: 'GET /api/merchants/profile',
        updateProfile: 'PUT /api/merchants/profile',
        toggleStore: 'PATCH /api/merchants/toggle-store',
        getDashboard: 'GET /api/merchants/dashboard-stats'
    },
    Admin: {
        getPendingMerchants: 'GET /api/admin/merchants/pending (Admin)',
        verifyMerchant: 'PATCH /api/admin/merchants/:id/verify (Admin)',
        getAllMerchants: 'GET /api/admin/merchants/all (Admin)',
        getUsers: 'GET /api/admin/users (Admin)',
        toggleUserBlock: 'PATCH /api/admin/users/:id/block (Admin)',
        getPlatformStats: 'GET /api/admin/stats (Admin)',
        getAllSubscriptions: 'GET /api/admin/subscriptions/all (Admin)',
        getAllAssignments: 'GET /api/admin/assignments (Admin)'
    },
    Upload: {
        uploadImage: 'POST /api/upload/image',
        uploadMultipleImages: 'POST /api/upload/images',
        uploadDocument: 'POST /api/upload/document (Merchant/Admin)',
        getMyUploads: 'GET /api/upload/my-uploads',
        getUploadById: 'GET /api/upload/:uploadId',
        deleteUpload: 'DELETE /api/upload/:uploadId',
        bulkDelete: 'POST /api/upload/bulk-delete (Merchant/Admin)',
        updateProductImages: 'PUT /api/upload/products/:productId/images (Merchant/Admin)'
    },
    Payment: {
        createOrder: 'POST /api/payment/create-order',
        verifyPayment: 'POST /api/payment/verify',
        processRefund: 'POST /api/payment/refund',
        getMethods: 'GET /api/payment/methods',
        getHistory: 'GET /api/payment/history',
        getStatus: 'GET /api/payment/:orderId/status',
        retryPayment: 'POST /api/payment/:orderId/retry'
    },
    Notifications: {
        getNotifications: 'GET /api/notifications',
        getUnreadCount: 'GET /api/notifications/unread-count',
        markAsRead: 'PATCH /api/notifications/:id/read',
        markAllAsRead: 'PATCH /api/notifications/read-all',
        deleteNotification: 'DELETE /api/notifications/:id',
        clearAll: 'DELETE /api/notifications/clear-all'
    },
    Wishlist: {
        getWishlist: 'GET /api/wishlist',
        addToWishlist: 'POST /api/wishlist/add',
        removeFromWishlist: 'DELETE /api/wishlist/remove/:productId',
        moveToCart: 'POST /api/wishlist/move-to-cart/:productId',
        checkWishlisted: 'GET /api/wishlist/check/:productId'
    },
    Wallet: {
        getWallet: 'GET /api/wallet',
        getTransactions: 'GET /api/wallet/transactions',
        addMoney: 'POST /api/wallet/add-money',
        verifyTopup: 'POST /api/wallet/verify-topup',
        useForPayment: 'POST /api/wallet/use-for-payment',
        adminCredit: 'POST /api/wallet/admin/credit (Admin)',
        lockUnlock: 'PATCH /api/wallet/admin/:userId/lock (Admin)',
        creditRefund: 'POST /api/wallet/credit-refund (Admin)'
    },
    Loyalty: {
        redeemPoints: 'POST /api/loyalty/redeem',
        getHistory: 'GET /api/loyalty/history',
        getBenefits: 'GET /api/loyalty/benefits',
        awardPoints: 'POST /api/loyalty/award (Admin)'
    },
    Referral: {
        generateCode: 'POST /api/referral/generate',
        getStats: 'GET /api/referral/stats',
        applyCode: 'POST /api/referral/apply',
        validateCode: 'GET /api/referral/validate/:code',
        processReward: 'POST /api/referral/process-reward (Admin)'
    },
    Offers: {
        getAvailableOffers: 'GET /api/offers/available',
        applyCoupon: 'POST /api/offers/cart/apply-coupon',
        removeCoupon: 'DELETE /api/offers/cart/remove-coupon',
        getFlashSales: 'GET /api/offers/flash-sales',
        getMerchantOffers: 'GET /api/offers/merchant (Merchant)',
        createOffer: 'POST /api/offers (Merchant/Admin)',
        updateOffer: 'PUT /api/offers/:id (Merchant/Admin)',
        deleteOffer: 'DELETE /api/offers/:id (Merchant/Admin)',
        getAnalytics: 'GET /api/offers/:id/analytics (Merchant/Admin)',
        getAllAdmin: 'GET /api/offers/admin/all (Admin)'
    },
    MerchantAnalytics: {
        getSales: 'GET /api/merchants/analytics/sales (Merchant)',
        getProducts: 'GET /api/merchants/analytics/products (Merchant)',
        getCustomers: 'GET /api/merchants/analytics/customers (Merchant)',
        getInventory: 'GET /api/merchants/analytics/inventory (Merchant)',
        getForecast: 'GET /api/merchants/analytics/forecast (Merchant)',
        getReviews: 'GET /api/merchants/analytics/reviews (Merchant)'
    },
    DeliveryZones: {
        checkDelivery: 'POST /api/merchants/zones/check-delivery',
        getNearbyMerchants: 'POST /api/merchants/zones/nearby',
        setLocation: 'PUT /api/merchants/zones/location (Merchant)',
        getZones: 'GET /api/merchants/zones/delivery-zones (Merchant)',
        addZone: 'POST /api/merchants/zones/delivery-zones (Merchant)',
        updateZone: 'PUT /api/merchants/zones/delivery-zones/:zoneId (Merchant)',
        deleteZone: 'DELETE /api/merchants/zones/delivery-zones/:zoneId (Merchant)'
    },
    Membership: {
        getPlans: 'GET /api/membership/plans',
        getMembership: 'GET /api/membership',
        subscribe: 'POST /api/membership/subscribe',
        cancel: 'POST /api/membership/cancel (User)',
        getPremiumProducts: 'GET /api/membership/premium-products (User)',
        checkBenefit: 'GET /api/membership/check-benefit (User)',
        getHistory: 'GET /api/membership/history (User)',
        initiate: 'POST /api/membership/initiate (User)',
        activate: 'POST /api/membership/activate (User)',
        getAdminAll: 'GET /api/membership/admin/all (Admin)'
    },
    PreBooking: {
        create: 'POST /api/prebooking',
        getMyPreBookings: 'GET /api/prebooking/my-prebookings',
        cancel: 'DELETE /api/prebooking/:id',
        convertToOrder: 'POST /api/prebooking/:id/convert-to-order',
        markAvailable: 'PATCH /api/prebooking/products/:id/mark-available (Merchant)',
        updateStatus: 'PATCH /api/prebooking/:id/update-status (Merchant)',
        getMerchantAll: 'GET /api/prebooking/merchant/all (Merchant)',
        getAdminAll: 'GET /api/prebooking/admin/all (Admin)'
    },
    DocumentVerification: {
        upload: 'POST /api/documents/upload (Merchant)',
        getHistory: 'GET /api/documents/history (Merchant)',
        getMerchantDocs: 'GET /api/documents (Merchant)',
        deleteDoc: 'DELETE /api/documents/:documentId (Merchant)',
        getAdminPending: 'GET /api/documents/admin/pending (Admin)',
        verifyDoc: 'PUT /api/documents/admin/:merchantId/:documentId/verify (Admin)',
        getExpiring: 'GET /api/documents/admin/expiring-soon (Admin)'
    },
    Disputes: {
        raiseDispute: 'POST /api/disputes',
        getMyDisputes: 'GET /api/disputes/my-disputes',
        getDisputeById: 'GET /api/disputes/:id',
        addMessage: 'POST /api/disputes/:id/message',
        escalate: 'PATCH /api/disputes/:id/escalate (User)',
        getAdminAll: 'GET /api/disputes/admin/all (Admin)',
        resolve: 'PUT /api/disputes/admin/:id/resolve (Admin)',
        updateStatus: 'PATCH /api/disputes/admin/:id/status (Admin)'
    },
    Financial: {
        getMerchantEarnings: 'GET /api/financial/merchants/earnings (Merchant)',
        getMerchantPayouts: 'GET /api/financial/merchants/payouts (Merchant)',
        getPayoutById: 'GET /api/financial/payouts/:id (Merchant/Admin)',
        getAdminPayouts: 'GET /api/financial/admin/payouts (Admin)',
        generatePayouts: 'POST /api/financial/admin/payouts/generate (Admin)',
        processPayout: 'POST /api/financial/admin/payouts/:id/process (Admin)',
        holdPayout: 'PATCH /api/financial/admin/payouts/:id/hold (Admin)',
        getReports: 'GET /api/financial/admin/reports/financial (Admin)',
        getGSTReport: 'GET /api/financial/admin/reports/gst (Admin)',
        updateCommission: 'PUT /api/financial/admin/settings/commission (Admin)'
    },
    BulkOperations: {
        bulkUpload: 'POST /api/bulk/products/bulk-upload (Merchant)',
        bulkUpdatePrice: 'PUT /api/bulk/products/bulk-update-price (Merchant)',
        bulkUpdateStock: 'PUT /api/bulk/products/bulk-update-stock (Merchant)',
        exportProducts: 'GET /api/bulk/products/export (Merchant)'
    },
    Search: {
        advancedSearch: 'GET /api/search/products',
        suggestions: 'GET /api/search/suggestions',
        trending: 'GET /api/search/trending'
    },
    Returns: {
        requestReturn: 'POST /api/returns',
        getMyReturns: 'GET /api/returns/my-returns',
        getReturnById: 'GET /api/returns/:id',
        cancelReturn: 'DELETE /api/returns/:id (User)',
        getAdminAll: 'GET /api/returns/admin/all (Admin)',
        processReturn: 'PUT /api/returns/admin/:id/process (Admin)'
    },
    GiftCards: {
        checkBalance: 'GET /api/gift-cards/balance/:code',
        validateGiftCard: 'POST /api/gift-cards/validate',
        redeemGiftCard: 'POST /api/gift-cards/redeem',
        getMyGiftCards: 'GET /api/gift-cards/my-cards',
        initiatePurchase: 'POST /api/gift-cards/purchase/initiate (User)',
        verifyPurchase: 'POST /api/gift-cards/purchase/verify (User)',
        adminGenerate: 'POST /api/gift-cards/admin/generate (Admin)',
        adminGetAll: 'GET /api/gift-cards/admin/all (Admin)',
        adminCancel: 'PATCH /api/gift-cards/admin/:id/cancel (Admin)'
    },
    DeliveryAgents: {
        register: 'POST /api/agents/register',
        login: 'POST /api/agents/login',
        getProfile: 'GET /api/agents/me (Agent)',
        updateProfile: 'PUT /api/agents/me (Agent)',
        updateStatus: 'PUT /api/agents/me/status (Agent)',
        updateLocation: 'POST /api/agents/me/location (Agent)',
        getCurrentAssignment: 'GET /api/agents/assignments/current (Agent)',
        getAssignments: 'GET /api/agents/assignments (Agent)',
        getAssignmentById: 'GET /api/agents/assignments/:id (Agent)',
        updateAssignmentStatus: 'PUT /api/agents/assignments/:id/status (Agent)',
        getEarnings: 'GET /api/agents/earnings (Agent)',
        adminGetAllAgents: 'GET /api/admin/agents (Admin)',
        adminGetAnalytics: 'GET /api/admin/agents/analytics (Admin)',
        adminGetAgentById: 'GET /api/admin/agents/:id (Admin)',
        adminGetAgentAssignments: 'GET /api/admin/agents/:id/assignments (Admin)',
        adminVerifyAgent: 'PATCH /api/admin/agents/:id/verify (Admin)',
        adminToggleAgentActive: 'PATCH /api/admin/agents/:id/toggle-active (Admin)',
        adminManualAssign: 'POST /api/admin/orders/:orderId/assign/:agentId (Admin)',
        adminGetUnassignedOrders: 'GET /api/admin/orders/unassigned (Admin)',
        adminGetAllAssignments: 'GET /api/admin/assignments (Admin)'
    }
};

const testData = {
    userSignup: { name: "Test User", email: "user@example.com", phone: "1234567890", password: "password123" },
    userLogin: { email: "user@example.com", password: "password123" },
    verifyEmail: { token: "{{verification_token}}" },
    forgotPassword: { email: "user@example.com" },
    resetPassword: { token: "{{reset_token}}", newPassword: "newpassword123" },
    merchantSignup: { name: "Merchant One", email: "merchant@example.com", phone: "9876543210", password: "password123", businessName: "Fresh Greens", merchantType: "farmer" },
    merchantLogin: { email: "merchant@example.com", password: "password123" },
    adminLogin: { email: "admin@greenbasket.com", password: "adminpassword" },
    create: {
        name: "Organic Tomatoes",
        description: "Fresh farm tomatoes",
        price: 80,
        stock: 100,
        unit: "kg",
        category: "{{category_id}}",
        tags: ["organic", "farm-fresh"],
        primaryImage: "https://example.com/tomato.jpg",
        nutritionalInfo: {
            calories: 18,
            protein: 0.9,
            fat: 0.2,
            carbohydrates: 3.9
        }
    },
    updateStock: { stock: 150 },
    addToCart: { productId: "{{product_id}}", quantity: 2, preparation: "cut" },
    updateItem: { quantity: 5 },
    createOrder: { addressId: "{{address_id}}", paymentMethod: "stripe", deliverySlot: { date: "2026-02-25", startTime: "09:00", endTime: "11:00" } },
    updateStatus: { status: "confirmed" },
    addAddress: { label: "home", name: "John Doe", phone: "1234567890", addressLine1: "123 Green St", city: "Eco City", state: "Nature", pincode: "123456", isDefault: true },
    addReview: { productId: "{{product_id}}", rating: 5, comment: "Excellent quality!" },
    updateReview: { rating: 4, comment: "Good, but could be better." },
    updateProfile: { name: "John Doe Updated", phone: "1234567891" },
    updateNotificationPrefs: { email: { orderUpdates: true, offers: false }, push: { orderUpdates: true, offers: true } },
    addMoney: { amount: 1000 },
    applyCoupon: { code: "FRESH20" },
    raiseDispute: { orderId: "{{order_id}}", category: "damaged_item", description: "The product was damaged" },
    addMessage: { message: "I have attached photos of the damage." },
    requestReturn: { orderId: "{{order_id}}", type: "return", reason: "Wrong item", items: [{ productId: "{{product_id}}", quantity: 1, reason: "Wrong size" }] },
    register: { name: "Agent Smith", email: "agent@greenbasket.com", phone: "1122334455", password: "agentpassword", vehicleType: "bike", vehicleNumber: "ABC-123" },
    login: { email: "agent@greenbasket.com", password: "agentpassword" },
    updateLocation: { latitude: 12.9716, longitude: 77.5946 },
    updateAssignmentStatus: { status: "delivered", otp: "123456" },
    bulkUpload: { /* Array of products usually handled via File upload */ },
    bulkUpdatePrice: { updates: [{ productId: "{{id1}}", newPrice: 50 }, { productId: "{{id2}}", newPrice: 75 }] },
    bulkUpdateStock: { updates: [{ productId: "{{id1}}", newStock: 100 }, { productId: "{{id2}}", newStock: 200 }] },
    adminCredit: { userId: "{{user_id}}", amount: 500, reason: "Customer Satisfaction" },
    awardPoints: { userId: "{{user_id}}", points: 100, reason: "Promotional event" },
    resolve: { status: "resolved", resolution: "Refunded to wallet" },
    processReturn: { status: "approved", action: "refund" },
    verifyDoc: { status: "approved", comment: "Legit document" },
    verifyMerchant: { status: "approved", rejectionReason: "" },
    adminGenerate: { amount: 500, expiryDate: "2026-12-31", purchasedFor: "test@user.com" },
    initiatePurchase: { amount: 1000, purchasedFor: "friend@example.com", message: "Gift for you!" },
    validateGiftCard: { code: "GC-123456" },
    initiateMembership: { planId: "{{plan_id}}" },
    activateMembership: { paymentIntentId: "pi_123..." }
};

const collection = {
    info: {
        name: "Green Basket API - Full Audit v3",
        schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    },
    item: [],
    variable: [
        { key: "base_url", value: "http://localhost:5001", type: "string" },
        { key: "token", value: "", type: "string" },
        { key: "id", value: "", type: "string" },
        { key: "productId", value: "", type: "string" },
        { key: "orderId", value: "", type: "string" },
        { key: "category_id", value: "", type: "string" },
        { key: "address_id", value: "", type: "string" },
        { key: "uploadId", value: "", type: "string" },
        { key: "userId", value: "", type: "string" },
        { key: "code", value: "", type: "string" }
    ]
};

for (const groupName in endpoints) {
    const folder = {
        name: groupName,
        item: []
    };

    for (const requestName in endpoints[groupName]) {
        const value = endpoints[groupName][requestName];
        const [method, pathWithRole] = value.split(' ');
        const path = pathWithRole.split('(')[0].trim();

        // Convert path to Postman segments
        const postmanPath = path.replace(/^\//, '').split('/').map(segment => {
            if (segment.startsWith(':')) {
                return `{{${segment.substring(1)}}}`;
            }
            return segment;
        });

        const requestItem = {
            name: requestName,
            request: {
                method: method,
                header: [
                    { key: "Authorization", value: "Bearer {{token}}", type: "text" },
                    { key: "Content-Type", value: "application/json", type: "text" }
                ],
                url: {
                    raw: `{{base_url}}${path}`,
                    host: ["{{base_url}}"],
                    path: postmanPath
                }
            }
        };

        if (['POST', 'PUT', 'PATCH'].includes(method)) {
            const bodyData = testData[requestName] || {};
            requestItem.request.body = {
                mode: "raw",
                raw: JSON.stringify(bodyData, null, 4),
                options: { raw: { language: "json" } }
            };
        }

        folder.item.push(requestItem);
    }
    collection.item.push(folder);
}

fs.writeFileSync(require('path').join(__dirname, '..', 'postman', 'GreenBasket.postman_collection.json'), JSON.stringify(collection, null, 2));
console.log('Postman collection generated: postman/GreenBasket.postman_collection.json');
