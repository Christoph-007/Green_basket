const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { protect, restrictTo } = require('../middlewares/authMiddleware');

router.get('/product/:productId', reviewController.getProductReviews);
router.get('/merchant/:merchantId', reviewController.getMerchantReviews);

router.post('/', protect, restrictTo('user'), reviewController.addReview);
router.get('/my-reviews', protect, restrictTo('user'), reviewController.getMyReviews);
router.put('/:id', protect, restrictTo('user'), reviewController.updateReview);
router.delete('/:id', protect, restrictTo('user', 'admin'), reviewController.deleteReview);

// Merchant: see reviews for their own store
router.get('/my-store', protect, restrictTo('merchant'), reviewController.getMyStoreReviews);

// Merchant reply to a review
router.post('/:id/reply', protect, restrictTo('merchant'), reviewController.replyToReview);

module.exports = router;

