const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { authenticate, isMerchant, optionalAuthenticate, restrictTo } = require('../middlewares/authMiddleware');
const { uploadProductImages } = require('../middlewares/uploadMiddleware');

// Merchant routes (Moved up to prevent collision with :id)
router.get('/merchant/my-products', authenticate, isMerchant, productController.getMyProducts);

// Public routes
router.get('/', optionalAuthenticate, productController.getAllProducts);
router.get('/nearby', optionalAuthenticate, productController.getNearbyProducts);
router.get('/search', optionalAuthenticate, productController.searchProducts);
router.get('/:id', optionalAuthenticate, productController.getProductById);

// Protected routes (Merchant & Admin)
router.post('/', authenticate, isMerchant, uploadProductImages, productController.createProduct);
router.put('/:id', authenticate, restrictTo('merchant', 'admin'), uploadProductImages, productController.updateProduct);
router.delete('/:id', authenticate, restrictTo('merchant', 'admin'), productController.deleteProduct);
router.patch('/:id/stock', authenticate, isMerchant, productController.updateStock);

module.exports = router;
