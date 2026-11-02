const { getIO } = require('../config/socket');

class InventorySocket {
    // Notify merchant of low stock
    static notifyLowStock(merchantId, productData) {
        const io = getIO();
        io.to(`merchant_${merchantId}`).emit('low_stock_alert', {
            type: 'LOW_STOCK',
            product: productData,
            currentStock: productData.stock,
            threshold: productData.lowStockThreshold,
            timestamp: new Date()
        });
    }

    // Update stock in real-time
    static updateStock(merchantId, productId, newStock) {
        const io = getIO();
        io.to(`merchant_${merchantId}`).emit('stock_updated', {
            productId,
            newStock,
            timestamp: new Date()
        });
    }

    // Notify out of stock
    static notifyOutOfStock(merchantId, productData) {
        const io = getIO();
        io.to(`merchant_${merchantId}`).emit('out_of_stock', {
            type: 'OUT_OF_STOCK',
            product: productData,
            timestamp: new Date()
        });
    }
}

module.exports = InventorySocket;
