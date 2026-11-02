const razorpay = require('../config/razorpay');
const crypto = require('crypto');

class PaymentService {
    /**
     * Create Razorpay Order
     * @param {number} amount - Amount in INR
     * @param {string} orderId - Internal Order ID
     * @param {string} customerId - Customer ID
     * @param {Object} metadata - Additional metadata
     */
    async createRazorpayOrder(amount, orderId, customerId, metadata = {}) {
        try {
            const options = {
                amount: Math.round(amount * 100), // Convert to paise
                currency: 'INR',
                receipt: orderId,
                notes: {
                    orderId,
                    customerId,
                    ...metadata
                }
            };
            const order = await razorpay.orders.create(options);
            return order;
        } catch (error) {
            console.error('Razorpay order creation error:', error);
            throw error;
        }
    }

    /**
     * Verify Razorpay Payment Signature
     * @param {string} orderId - Razorpay Order ID
     * @param {string} paymentId - Razorpay Payment ID
     * @param {string} signature - Razorpay Signature
     */
    verifyRazorpaySignature(orderId, paymentId, signature) {
        const body = orderId + "|" + paymentId;
        const expectedSignature = crypto
            .createHmac('sha256', process.env.KEY_SECRET)
            .update(body.toString())
            .digest('hex');
            
        return expectedSignature === signature;
    }

    /**
     * Retrieve a Razorpay Order (amount, notes, status)
     */
    async getRazorpayOrder(razorpayOrderId) {
        try {
            return await razorpay.orders.fetch(razorpayOrderId);
        } catch (error) {
            console.error('Razorpay fetch order error:', error);
            throw error;
        }
    }

    /**
     * All payments made against a Razorpay order
     */
    async getRazorpayOrderPayments(razorpayOrderId) {
        const result = await razorpay.orders.fetchPayments(razorpayOrderId);
        return (result && result.items) || [];
    }

    /**
     * Retrieve Razorpay Payment
     */
    async getRazorpayPayment(paymentId) {
        try {
            const payment = await razorpay.payments.fetch(paymentId);
            return payment;
        } catch (error) {
            console.error('Razorpay fetch payment error:', error);
            throw error;
        }
    }
    
    /**
     * Process Razorpay Refund
     */
    async processRazorpayRefund(paymentId, amount, reason = 'requested_by_customer') {
        try {
            const refund = await razorpay.payments.refund(paymentId, {
                amount: Math.round(amount * 100), // refunds.create takes amount in smallest currency unit
                notes: {
                    reason: reason
                }
            });
            return refund;
        } catch (error) {
            console.error('Razorpay refund error:', error);
            throw error;
        }
    }
}

module.exports = new PaymentService();
