const express = require('express');
const router = express.Router();
const loyaltyController = require('../controllers/loyaltyController');
const { authenticate: protect, isAdmin } = require('../middlewares/authMiddleware');

router.use(protect);

// User routes
router.post('/redeem', loyaltyController.redeemPoints);
router.get('/history', loyaltyController.getPointsHistory);
router.get('/benefits', loyaltyController.getTierBenefits);

// System/Admin routes
router.post('/award', isAdmin, loyaltyController.awardPoints);

module.exports = router;
