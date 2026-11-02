const Order = require('../models/Order');
const User = require('../models/User');
const paymentService = require('../services/paymentService');
const notificationService = require('../services/notification');
const notify = require('../services/notify');
const lifecycle = require('../services/orderLifecycle');
const crypto = require('crypto');
const { ensureWallet, creditWalletTopup } = require('../utils/walletHelpers');

exports.createPaymentOrder = async (req, res) => {
    try {
        const { orderId, amount, gateway, method } = req.body;
        const selectedGateway = gateway || method;

        console.log('[Payment] Request:', { orderId, amount, selectedGateway, userId: req.user?.id });

        if (!orderId || !amount) {
            console.log('[Payment] Missing orderId or amount');
            return res.status(400).json({
                success: false,
                error: 'Order ID and amount are required'
            });
        }

        const order = await Order.findOne({
            orderId
        }).populate('customer');

        if (!order) {
            console.log('[Payment] Order not found:', orderId);
            return res.status(404).json({
                success: false,
                error: `Order ${orderId} not found`
            });
        }

        // Check ownership
        if (order.customer._id.toString() !== req.user.id.toString()) {
            console.log('[Payment] Ownership mismatch:', { orderCustomer: order.customer._id, requestUser: req.user.id });
            return res.status(403).json({
                success: false,
                error: 'You are not authorized to pay for this order'
            });
        }

        if (order.paymentStatus === 'completed' || order.paymentStatus === 'paid') {
            const errorMsg = `Order ${orderId} is already paid (status: ${order.paymentStatus})`;
            console.log('[Payment] Error:', errorMsg);
            return res.status(400).json({
                success: false,
                error: errorMsg
            });
        }

        // Verify amount
        const requestedAmount = parseFloat(amount);
        if (Math.abs(order.totalAmount - requestedAmount) > 0.1) {
            const errorMsg = `Amount mismatch. Order: ${order.totalAmount}, Requested: ${requestedAmount}`;
            console.log('[Payment] Error:', errorMsg);
            return res.status(400).json({
                success: false,
                error: errorMsg
            });
        }

        if (selectedGateway === 'razorpay') {
            const razorpayOrder = await paymentService.createRazorpayOrder(
                amount,
                order.orderId,
                req.user._id.toString(),
                {
                    customerName: order.customer.name,
                    customerEmail: order.customer.email
                }
            );

            order.paymentGateway.provider = 'razorpay';
            order.razorpayOrderId = razorpayOrder.id;
            order.paymentGateway.orderId = razorpayOrder.id;

            order.paymentEvents.push({
                event: 'order_created',
                data: {
                    status: razorpayOrder.status,
                    amount: razorpayOrder.amount,
                    currency: razorpayOrder.currency,
                    id: razorpayOrder.id
                }
            });
            await order.save();

            return res.json({
                success: true,
                data: {
                    key: process.env.KEY_ID, // Frontend needs key
                    orderId: razorpayOrder.id,
                    amount: razorpayOrder.amount, // in paise
                    currency: razorpayOrder.currency,
                    order: {
                        orderId: order.orderId,
                        totalAmount: order.totalAmount
                    },
                    customer: {
                        name: order.customer.name,
                        email: order.customer.email,
                        phone: order.customer.phone
                    },
                    provider: 'razorpay'
                }
            });
        }

        return res.status(400).json({
            success: false,
            error: 'Invalid or unsupported payment gateway'
        });
    } catch (error) {
        console.error('Payment order creation error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create payment order',
            details: error.message
        });
    }
};

// Verify payment handles the confirmation from the frontend.
// The backend confirms via Razorpay signature verification.
// The frontend calls this to check status immediately after payment.
/**
 * Side effects once an online order is paid (from /verify, the webhook or the
 * expiry check): clear the cart, tell the merchant about the (now real) order,
 * send the customer their payment receipt. Never throws.
 */
exports.afterOrderPaid = async (order) => {
    try {
        const Cart = require('../models/Cart');
        const Merchant = require('../models/Merchant');
        const OrderSocket = require('../sockets/orderSocket');

        await Cart.findOneAndUpdate(
            { user: order.customer },
            { items: [], total: 0, discount: 0, finalTotal: 0, appliedCoupon: { code: null, offerId: null, discount: 0 } }
        );

        const customer = await User.findById(order.customer);
        const payload = {
            orderId: order.orderId,
            amount: order.totalAmount,
            totalAmount: order.totalAmount,
            customerName: customer ? customer.name : undefined,
            itemsCount: order.items ? order.items.length : undefined
        };
        // Online orders are only announced to the merchant once paid
        OrderSocket.notifyOrderPaid(order.merchant, payload);
        OrderSocket.notifyNewOrder(order.merchant, payload);
        await notificationService.createNotification({
            recipient: order.merchant,
            recipientModel: 'Merchant',
            type: 'order',
            title: 'New Paid Order',
            message: `New order ${order.orderId} paid online (₹${order.totalAmount})`,
            data: { orderId: order._id }
        }).catch(() => {});
        const merchant = await Merchant.findById(order.merchant);
        if (merchant && merchant.phone) {
            notify.sms(merchant.phone, `New paid order ${order.orderId}${customer ? ' from ' + customer.name : ''}! Total: ₹${order.totalAmount}. Open the app to accept.`).catch(() => {});
        }

        if (customer) {
            notify.all({
                user: customer,
                subject: `Payment Successful — Order ${order.orderId}`,
                template: 'paymentSuccess',
                templateData: {
                    customerName: customer.name,
                    orderId: order.orderId,
                    amount: Number(order.totalAmount).toFixed(2),
                    paymentMethod: 'Razorpay',
                    transactionId: order.razorpayPaymentId,
                    date: new Date().toLocaleDateString('en-IN'),
                    year: new Date().getFullYear()
                },
                smsBody: `Green Basket: Payment of \u20b9${order.totalAmount} for order ${order.orderId} successful! Your order is confirmed.`,
                pushTitle: '✅ Payment Successful',
                pushBody: `\u20b9${order.totalAmount} paid for order ${order.orderId}. Order confirmed!`,
                pushData: { orderId: order._id.toString(), type: 'payment_success' }
            }).catch(() => {});
        }
    } catch (error) {
        console.error('[Payment] post-payment steps failed:', error.message);
    }
};

/**
 * Fetch the payment from Razorpay and check it was made for this order's
 * Razorpay order, for the full order amount, and has been authorized/captured.
 * Returns { ok: true } or { ok: false, statusCode, error }.
 */
const checkRazorpayPayment = async (order, razorpayPaymentId) => {
    const isProduction = process.env.NODE_ENV === 'production';
    const keysMissing = !process.env.KEY_ID || !process.env.KEY_SECRET;

    if (keysMissing && !isProduction) {
        console.warn(`[Payment] Razorpay keys missing; skipping payment fetch check for order ${order.orderId} (development only)`);
        return { ok: true };
    }

    let payment;
    try {
        payment = await paymentService.getRazorpayPayment(razorpayPaymentId);
    } catch (error) {
        console.error(`[Payment] Could not fetch Razorpay payment ${razorpayPaymentId}:`, error.message);
        return { ok: false, statusCode: 502, error: 'Could not confirm payment with Razorpay. Please try again.' };
    }

    if (!payment || payment.order_id !== order.razorpayOrderId) {
        return { ok: false, statusCode: 400, error: 'Payment does not belong to this order' };
    }
    if (payment.amount !== Math.round(order.totalAmount * 100)) {
        return { ok: false, statusCode: 400, error: 'Payment amount does not match order total' };
    }
    if (!['captured', 'authorized'].includes(payment.status)) {
        return { ok: false, statusCode: 400, error: `Payment not completed (status: ${payment.status})` };
    }

    return { ok: true };
};

exports.verifyPayment = async (req, res) => {
    try {
        // Razorpay verification requires orderId, paymentId, and signature
        const { orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

        if (!orderId) {
            return res.status(400).json({
                success: false,
                error: 'Order ID is required'
            });
        }

        const order = await Order.findOne({
            orderId,
            customer: req.user._id
        });

        if (!order) {
            return res.status(404).json({
                success: false,
                error: 'Order not found'
            });
        }

        // --- Razorpay Verification ---
        if (razorpayPaymentId && razorpayOrderId && razorpaySignature) {
            // The payment must belong to the Razorpay order created for THIS order,
            // otherwise a valid payment for a cheaper order could confirm this one.
            if (!order.razorpayOrderId || order.razorpayOrderId !== razorpayOrderId) {
                return res.status(400).json({
                    success: false,
                    error: 'Payment does not belong to this order'
                });
            }

            const isValid = paymentService.verifyRazorpaySignature(razorpayOrderId, razorpayPaymentId, razorpaySignature);
            if (isValid) {
                if (order.paymentStatus !== 'completed') {
                    // Confirm with Razorpay that the payment is real, for this order, for the full amount
                    const paymentCheck = await checkRazorpayPayment(order, razorpayPaymentId);
                    if (!paymentCheck.ok) {
                        return res.status(paymentCheck.statusCode).json({
                            success: false,
                            error: paymentCheck.error
                        });
                    }

                    // Mark paid exactly once (the webhook may race us); refunds the
                    // payment automatically if the order was cancelled meanwhile
                    const result = await lifecycle.confirmRazorpayPayment(order, {
                        razorpayOrderId, razorpayPaymentId, source: 'verify'
                    });
                    if (result.refundedLatePayment) {
                        return res.status(409).json({
                            success: false,
                            error: `This order is ${result.order.status} and can no longer be paid. Your payment will be refunded.`
                        });
                    }
                    if (result.confirmed) await exports.afterOrderPaid(result.order);
                    if (result.order) {
                        order.paymentStatus = result.order.paymentStatus;
                        order.status = result.order.status;
                    }
                }
                return res.json({
                    success: true,
                    message: 'Payment verified successfully',
                    data: {
                        order: {
                            orderId: order.orderId,
                            paymentStatus: order.paymentStatus,
                            status: order.status,
                            totalAmount: order.totalAmount
                        }
                    }
                });
            } else {
                return res.status(400).json({
                    success: false,
                    error: 'Invalid Razorpay signature'
                });
            }
        }
        
        return res.status(400).json({
            success: false,
            error: 'Razorpay payment details are required for verification'
        });

    } catch (error) {
        console.error('Payment verification error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to verify payment',
            details: error.message
        });
    }
};

// Razorpay webhook (POST /api/payment/webhook, raw body). Configure the URL
// and RAZORPAY_WEBHOOK_SECRET in the Razorpay dashboard with the events
// payment.captured, order.paid and payment.failed. This confirms orders even
// if the app closes before calling /verify.
exports.handleWebhook = async (req, res) => {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!secret) {
        console.error('[Webhook] RAZORPAY_WEBHOOK_SECRET is not configured');
        return res.status(500).json({ success: false, error: 'Webhook not configured' });
    }

    const raw = Buffer.isBuffer(req.body)
        ? req.body
        : Buffer.from(typeof req.body === 'string' ? req.body : JSON.stringify(req.body || {}));
    const signature = String(req.headers['x-razorpay-signature'] || '');
    const expected = crypto.createHmac('sha256', secret).update(raw).digest('hex');
    const valid = signature.length === expected.length &&
        crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
    if (!valid) {
        return res.status(400).json({ success: false, error: 'Invalid webhook signature' });
    }

    let event;
    try {
        event = JSON.parse(raw.toString('utf8'));
    } catch (_) {
        return res.status(400).json({ success: false, error: 'Invalid JSON' });
    }

    const type = event.event;
    const payment = event.payload && event.payload.payment && event.payload.payment.entity;
    const rzOrder = event.payload && event.payload.order && event.payload.order.entity;
    const razorpayOrderId = (payment && payment.order_id) || (rzOrder && rzOrder.id);

    try {
        if ((type === 'payment.captured' || type === 'order.paid') && payment && razorpayOrderId) {
            const order = await Order.findOne({ razorpayOrderId });
            if (order) {
                if (payment.amount !== Math.round(order.totalAmount * 100)) {
                    console.error(`[Webhook] amount mismatch for ${order.orderId}: paid ${payment.amount}, expected ${Math.round(order.totalAmount * 100)}`);
                } else {
                    const result = await lifecycle.confirmRazorpayPayment(order, {
                        razorpayOrderId, razorpayPaymentId: payment.id, source: 'webhook'
                    });
                    if (result.confirmed) await exports.afterOrderPaid(result.order);
                }
            } else {
                // Not a checkout order: maybe a wallet top-up created by /wallet/add-money
                const notes = (rzOrder && rzOrder.notes) ||
                    (await paymentService.getRazorpayOrder(razorpayOrderId)).notes || {};
                if (notes.type === 'wallet_topup' && notes.userId) {
                    await ensureWallet(notes.userId);
                    await creditWalletTopup(notes.userId, payment.amount / 100, payment.id, razorpayOrderId);
                }
            }
        } else if (type === 'payment.failed' && razorpayOrderId) {
            await Order.updateOne(
                { razorpayOrderId },
                { $push: { paymentEvents: { event: 'payment_failed', data: {
                    razorpayPaymentId: payment && payment.id,
                    reason: payment && (payment.error_description || payment.error_reason)
                } } } }
            );
        }
    } catch (error) {
        // 5xx makes Razorpay retry the webhook later
        console.error('[Webhook] processing failed:', error);
        return res.status(500).json({ success: false, error: 'Webhook processing failed' });
    }

    res.json({ success: true });
};

exports.processRefund = async (req, res) => {
    try {
        const { orderId, amount, reason } = req.body;

        if (!orderId || !reason) {
            return res.status(400).json({ success: false, error: 'Order ID and reason are required' });
        }

        // Accept the human order number (GB…) or the Mongo _id
        const mongoose = require('mongoose');
        const order = await Order.findOne(
            mongoose.Types.ObjectId.isValid(orderId) ? { _id: orderId } : { orderId }
        );
        if (!order) return res.status(404).json({ success: false, error: 'Order not found' });

        if (!lifecycle.isPaid(order)) {
            return res.status(400).json({ success: false, error: `Order is not refundable (payment status: ${order.paymentStatus})` });
        }
        if (order.refund && ['initiated', 'processing', 'completed'].includes(order.refund.status)) {
            return res.status(400).json({ success: false, error: 'A refund has already been issued for this order' });
        }

        const refundAmount = amount !== undefined ? Number(amount) : order.totalAmount;
        if (!(refundAmount > 0) || refundAmount > order.totalAmount) {
            return res.status(400).json({ success: false, error: `Refund amount must be between 0 and ${order.totalAmount}` });
        }

        // Wallet orders are refunded to the wallet, Razorpay orders via Razorpay
        const result = await lifecycle.refundOrderPayment(order, { reason, amount: refundAmount });
        if (!result.refunded) {
            await order.save();
            return res.status(result.error ? 502 : 400).json({
                success: false,
                error: result.error ? `Refund failed: ${result.error}` : 'This order was not prepaid (cash on delivery); nothing to refund'
            });
        }

        if (refundAmount >= order.totalAmount && order.status !== 'refunded') {
            order.statusHistory.push({
                status: 'refunded',
                timestamp: new Date(),
                note: `Refunded by admin: ${reason}`,
                updatedBy: req.user._id,
                updatedByModel: 'Admin'
            });
            order.status = 'refunded';
        }
        await order.save();
        if (order.status === 'refunded') await lifecycle.reverseLoyalty(order);

        // ── Refund notifications to customer ───────────────────────────
        const refundCustomer = await User.findById(order.customer);
        if (refundCustomer) {
            notify.all({
                user: refundCustomer,
                subject: `Refund Initiated — Order ${order.orderId}`,
                template: 'refundInitiated',
                templateData: {
                    customerName: refundCustomer.name,
                    orderId: order.orderId,
                    amount: refundAmount.toFixed(2),
                    reason,
                    year: new Date().getFullYear()
                },
                smsBody: `Green Basket: Refund of \u20b9${refundAmount} for order ${order.orderId} has been initiated. It will reflect in 5-7 business days.`,
                pushTitle: '💰 Refund Initiated',
                pushBody: `\u20b9${refundAmount} refund initiated for order ${order.orderId}.`,
                pushData: { orderId: order._id.toString(), type: 'refund_processed' }
            }).catch(() => {});
        }
        // ─────────────────────────────────────────────────────────────

        res.json({
            success: true,
            message: 'Refund initiated successfully',
            data: {
                method: result.method,
                amount: refundAmount,
                status: order.refund.status
            }
        });

    } catch (error) {
        console.error('Refund processing error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to process refund',
            details: error.message
        });
    }
};

exports.getPaymentMethods = async (req, res) => {
    try {
        const methods = [
            { id: 'cod', name: 'Cash on Delivery', icon: 'cash', available: true },
            { id: 'razorpay', name: 'Razorpay', icon: 'card', available: true }
        ];

        if (req.user) {
            const Wallet = require('../models/Wallet');
            const wallet = await Wallet.findOne({ user: req.user._id });
            const balance = wallet?.balance || 0;

            methods.push({
                id: 'wallet',
                name: 'Green Basket Wallet',
                icon: 'wallet',
                available: !wallet?.isLocked && balance > 0,
                balance,
                isLocked: wallet?.isLocked || false
            });
        }

        res.json({ success: true, data: { methods } });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// ... keep getPaymentHistory as it queries DB generic fields ...
exports.getPaymentHistory = async (req, res) => {
    try {
        const { status, page = 1, limit = 10 } = req.query;

        const query = { customer: req.user._id };
        if (status) query.paymentStatus = status;

        const skip = (page - 1) * limit;

        const [orders, total] = await Promise.all([
            Order.find(query)
                .select('orderId totalAmount paymentStatus paymentGateway createdAt status merchant')
                .populate('merchant', 'businessName')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Order.countDocuments(query)
        ]);

        res.json({
            success: true,
            data: {
                payments: orders.map(o => ({
                    orderId: o.orderId,
                    amount: o.totalAmount,
                    paymentStatus: o.paymentStatus,
                    paymentMethod: o.paymentGateway?.provider || 'unknown',
                    transactionId: o.paymentGateway?.transactionId,
                    orderStatus: o.status,
                    merchant: o.merchant?.businessName,
                    date: o.createdAt
                })),
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getPaymentStatus = async (req, res) => {
    try {
        const { orderId } = req.params;
        const order = await Order.findOne({ orderId, customer: req.user._id });

        if (!order) return res.status(404).json({ success: false, error: 'Order not found' });

        res.json({
            success: true,
            data: {
                orderId: order.orderId,
                paymentStatus: order.paymentStatus
            }
        });

    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.retryPayment = async (req, res) => {
    // Retry logic is essentially creating a new payment order/intent
    // Reuse createPaymentOrder logic or redirect
    return exports.createPaymentOrder(req, res);
};
