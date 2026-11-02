const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');
const { authenticate } = require('../middlewares/authMiddleware');

router.use(authenticate);

router.get('/', cartController.getCart);
router.post('/add', cartController.addToCart);
router.put('/update/:productId', cartController.updateCartItem);
router.delete('/remove/:productId', cartController.removeFromCart);
router.delete('/clear', cartController.clearCart);
router.post('/recipe-to-cart', cartController.addRecipeToCart);
router.post('/coupon', cartController.applyCoupon);
router.delete('/coupon', cartController.removeCoupon);



module.exports = router;
