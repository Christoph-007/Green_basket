const express = require('express');
const router = express.Router();
const referralController = require('../controllers/referralController');
const { authenticate: protect, isAdmin } = require('../middlewares/authMiddleware');

/**
 * Public Routes
 */

// Validate referral code
router.get('/validate/:code', referralController.validateReferralCode);

/**
 * Protected Routes (User)
 */
router.use(protect);

// Generate referral code
router.post('/generate', referralController.generateReferralCode);

// Get referral stats
router.get('/stats', referralController.getReferralStats);

// Apply referral code (during signup)
router.post('/apply', referralController.applyReferralCode);

// Process referral reward (system/admin only)
router.post('/process-reward',
    isAdmin,
    referralController.processReferralReward
);

module.exports = router;
