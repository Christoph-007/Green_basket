const express = require('express');
const router = express.Router();
const merchantController = require('../controllers/merchantController');
const { authenticate, isMerchant } = require('../middlewares/authMiddleware');
const { uploadImage } = require('../middlewares/upload');

// Public routes
router.get('/', merchantController.getAllMerchants);

// Protected routes (Merchant only)
router.use(authenticate, isMerchant);

router.get('/profile', merchantController.getProfile);
router.put('/profile', merchantController.updateProfile);
router.post('/upload-image', uploadImage, merchantController.uploadImage);
router.patch('/toggle-store', merchantController.toggleStoreStatus);
router.get('/dashboard-stats', merchantController.getDashboardStats);
router.patch('/update-password', merchantController.updatePassword);
router.patch('/notification-settings', merchantController.updateNotificationSettings);

// Parameterized routes should be last
router.get('/:id', merchantController.getMerchantById);

module.exports = router;
