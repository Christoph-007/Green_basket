const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { authenticate, isMerchant } = require('../middlewares/authMiddleware');
const { validateOrder } = require('../utils/validators');
const { validate } = require('../middlewares/validationMiddleware');

// Merchant routes
router.get('/merchant/orders', authenticate, isMerchant, orderController.getMerchantOrders);
router.patch('/merchant/:id/status', authenticate, isMerchant, orderController.updateOrderStatus);

// Customer/General routes
router.post('/', authenticate, validateOrder, validate, orderController.createOrder);
// Exact totals for checkout (same pricing as order creation, no writes)
router.post('/quote', authenticate, orderController.quoteOrder);
router.get('/my-orders', authenticate, orderController.getMyOrders);
router.get('/:id', authenticate, orderController.getOrderById);
router.patch('/:id/cancel', authenticate, orderController.cancelOrder);
router.get('/:id/track', authenticate, orderController.enhancedTrackOrder);
router.get('/:orderId/tracking', authenticate, orderController.getOrderTracking);
router.patch('/:id/location', authenticate, orderController.updateOrderLocation);

module.exports = router;
