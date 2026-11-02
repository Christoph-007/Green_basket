const express = require('express');
const router = express.Router();
const wishlistController = require('../controllers/wishlistController');
const { authenticate: protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.get('/', wishlistController.getWishlist);
router.post('/add', wishlistController.addToWishlist);
router.delete('/remove/:productId', wishlistController.removeFromWishlist);
router.post('/move-to-cart/:productId', wishlistController.moveToCart);
router.get('/check/:productId', wishlistController.checkWishlisted);

module.exports = router;
