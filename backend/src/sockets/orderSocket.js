const { getIO } = require('../config/socket');

class OrderSocket {
    // Emit new order to merchant
    static notifyNewOrder(merchantId, orderData) {
        const io = getIO();
        io.to(`merchant_${merchantId}`).emit('new_order', {
            type: 'NEW_ORDER',
            order: orderData,
            timestamp: new Date()
        });
    }

    // Emit to the merchant when an online order has been paid
    static notifyOrderPaid(merchantId, orderData) {
        const io = getIO();
        io.to(`merchant_${merchantId}`).emit('order_paid', {
            type: 'ORDER_PAID',
            order: orderData,
            timestamp: new Date()
        });
    }

    // Emit order status update to customer
    static notifyOrderStatusUpdate(customerId, orderData) {
        const io = getIO();
        io.to(`user_${customerId}`).emit('order_status_update', {
            type: 'ORDER_STATUS_UPDATE',
            order: orderData,
            timestamp: new Date()
        });
    }

    // Real-time order tracking
    static updateOrderLocation(orderId, customerId, locationData) {
        const io = getIO();
        io.to(`user_${customerId}`).emit('order_location_update', {
            orderId,
            location: locationData,
            timestamp: new Date()
        });
    }

    // Notify order cancellation
    static notifyOrderCancellation(userId, userType, orderData) {
        const io = getIO();
        io.to(`${userType}_${userId}`).emit('order_cancelled', {
            type: 'ORDER_CANCELLED',
            order: orderData,
            timestamp: new Date()
        });
    }

    // Live order count for merchant dashboard
    static updateMerchantOrderCount(merchantId, count) {
        const io = getIO();
        io.to(`merchant_${merchantId}`).emit('order_count_update', {
            pendingOrders: count.pending,
            activeOrders: count.active,
            timestamp: new Date()
        });
    }
}

module.exports = OrderSocket;
