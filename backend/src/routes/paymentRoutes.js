const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticate: protect, isAdmin } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/create-order', paymentController.createPaymentOrder);
router.post('/verify', paymentController.verifyPayment);
// Refunds are an admin action (customers request returns/disputes instead)
router.post('/refund', isAdmin, paymentController.processRefund);

router.get('/methods', paymentController.getPaymentMethods);
router.get('/history', paymentController.getPaymentHistory);
router.get('/:orderId/status', paymentController.getPaymentStatus);
router.post('/:orderId/retry', paymentController.retryPayment);

module.exports = router;
