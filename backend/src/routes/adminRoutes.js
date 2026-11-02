const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const categoryController = require('../controllers/categoryController');
const { authenticate, isAdmin } = require('../middlewares/authMiddleware');

router.use(authenticate, isAdmin);

router.get('/merchants/pending', adminController.getPendingMerchants);
router.patch('/merchants/:id/verify', adminController.verifyMerchant);
router.get('/merchants/all', adminController.getAllMerchants);
router.get('/merchants/:id/analytics', adminController.getMerchantAnalytics);
router.patch('/merchants/:id/block', adminController.toggleMerchantBlock);


router.get('/users', adminController.getUsers);
router.patch('/users/:id/block', adminController.toggleUserBlock);

router.get('/stats', adminController.getPlatformStats);

// Order Management Routes
router.get('/orders/all', adminController.getAllOrders);

// Platform Settings
router.get('/settings', adminController.getSettings);
router.put('/settings', adminController.updateSettings);

// Category Management Routes (admin — all categories + productsCount)
router.get('/categories', categoryController.getAllCategoriesAdmin);
router.put('/categories/:id', categoryController.updateCategory);
router.delete('/categories/:id', categoryController.deleteCategory);

module.exports = router;

