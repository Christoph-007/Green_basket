const { getIO } = require('../config/socket');

class NotificationSocket {
    // Send notification to specific user
    static sendNotification(userId, userType, notification) {
        const io = getIO();
        io.to(`${userType}_${userId}`).emit('notification', {
            id: notification._id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            timestamp: notification.createdAt
        });
    }

    // Broadcast notification to all users of a type
    static broadcastNotification(userType, notification) {
        const io = getIO();
        io.to(userType).emit('broadcast_notification', notification);
    }

    // Mark notification as read (acknowledge from client)
    static acknowledgeNotification(socket) {
        socket.on('notification_read', async (notificationId) => {
            // Update notification status in database
            // This is handled in the controller
            socket.emit('notification_acknowledged', { id: notificationId });
        });
    }
}

module.exports = NotificationSocket;
