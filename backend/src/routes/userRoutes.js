const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate } = require('../middlewares/authMiddleware');

router.use(authenticate);

router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);

router.get('/addresses', userController.getAddresses);
router.post('/addresses', userController.addAddress);
router.put('/addresses/:id', userController.updateAddress);
router.delete('/addresses/:id', userController.deleteAddress);

// Notification Preferences
router.get('/notification-preferences', userController.getNotificationPreferences);
router.put('/notification-preferences', userController.updateNotificationPreferences);

// FCM Tokens
router.post('/fcm-token', userController.registerFCMToken);
router.delete('/fcm-token', userController.removeFCMToken);

module.exports = router;
