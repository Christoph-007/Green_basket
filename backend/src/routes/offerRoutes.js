const express = require('express');
const router = express.Router();
const offerController = require('../controllers/offerController');
const { protect, restrictTo, optionalAuthenticate } = require('../middlewares/authMiddleware');
const { uploadOfferImage } = require('../middlewares/uploadMiddleware');

// Public routes
router.get('/', optionalAuthenticate, offerController.getAvailableOffers);
router.get('/flash-sales', offerController.getFlashSales);
router.get('/available', optionalAuthenticate, offerController.getAvailableOffers);

// Protected routes
router.use(protect);

// User routes
router.post('/cart/apply-coupon', offerController.applyCoupon);
router.delete('/cart/remove-coupon', offerController.removeCoupon);

// Merchant routes
router.get('/merchant',
    restrictTo('merchant'),
    offerController.getMerchantOffers
);
router.post('/',
    restrictTo('merchant', 'admin'),
    offerController.createOffer
);
router.get('/:id/analytics',
    restrictTo('merchant', 'admin'),
    offerController.getOfferAnalytics
);
router.put('/:id',
    restrictTo('merchant', 'admin'),
    offerController.updateOffer
);
router.delete('/:id',
    restrictTo('merchant', 'admin'),
    offerController.deleteOffer
);

// Admin routes
router.get('/admin/all',
    restrictTo('admin'),
    offerController.getAllOffers
);

module.exports = router;
