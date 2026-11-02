const express = require('express');
const router = express.Router();
const disputeController = require('../controllers/disputeController');
const { protect, restrictTo, isAdmin } = require('../middlewares/authMiddleware');

router.use(protect);

// User routes
router.post('/', restrictTo('user'), disputeController.raiseDispute);
router.get('/my-disputes', restrictTo('user'), disputeController.getMyDisputes);
router.get('/:id', disputeController.getDisputeById);
router.post('/:id/message', disputeController.addMessage);
router.patch('/:id/escalate', restrictTo('user'), disputeController.escalateDispute);

// Merchant routes
router.get('/merchant/all', restrictTo('merchant'), disputeController.getMerchantDisputes);
router.put('/merchant/:id/resolve', restrictTo('merchant'), disputeController.resolveMerchantDispute);

// Admin routes
router.get('/admin/all', isAdmin, disputeController.getAllDisputes);
router.put('/admin/:id/resolve', isAdmin, disputeController.resolveDispute);
router.patch('/admin/:id/status', isAdmin, disputeController.updateDisputeStatus);

module.exports = router;
