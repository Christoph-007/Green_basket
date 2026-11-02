const express = require('express');
const router = express.Router();
const walletController = require('../controllers/walletController');
const { authenticate: protect, isAdmin } = require('../middlewares/authMiddleware');

router.use(protect);

// User routes
router.get('/', walletController.getWallet);
router.get('/transactions', walletController.getTransactionHistory);
router.post('/add-money', walletController.addMoney);
router.post('/verify-topup', walletController.verifyTopup);
router.post('/use-for-payment', walletController.useForPayment);

// Admin routes
router.post('/admin/credit', isAdmin, walletController.adminCredit);
router.patch('/admin/:userId/lock', isAdmin, walletController.lockUnlockWallet);

// System routes (internal use)
router.post('/credit-refund', isAdmin, walletController.creditRefund);

module.exports = router;
