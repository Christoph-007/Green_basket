const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticate: protect, isAdmin } = require('../middlewares/authMiddleware');

router.use(protect);

// Admin routes (Put first to avoid conflict with generic routes)
router.get('/admin/all', isAdmin, notificationController.getAllSentNotifications);
router.post('/admin/test', isAdmin, notificationController.sendTestNotification);
router.post('/admin/bulk-send', isAdmin, notificationController.bulkSendNotifications);

router.get('/', notificationController.getNotifications);
router.get('/unread-count', notificationController.getUnreadCount);
router.patch('/read-all', notificationController.markAllAsRead);
router.patch('/:id/read', notificationController.markAsRead);
router.delete('/clear-all', notificationController.clearAllNotifications);
router.delete('/:id', notificationController.deleteNotification);

// FCM Token management
router.post('/fcm-token', notificationController.registerFCMToken);
router.delete('/fcm-token', notificationController.removeFCMToken);

module.exports = router;
