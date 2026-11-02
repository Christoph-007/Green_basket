const mongoose = require('mongoose');
const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Product = require('../models/Product');
const Offer = require('../models/Offer');
const User = require('../models/User');
const Merchant = require('../models/Merchant');
const Wallet = require('../models/Wallet');
const OrderSocket = require('../sockets/orderSocket');
const notificationService = require('../services/notificationService');
const notify = require('../services/notify');
const { debitWalletForOrder, creditWalletForOrder } = require('../utils/walletHelpers');
const lifecycle = require('../services/orderLifecycle');
const { priceOrder } = require('../services/orderPricing');
const { reserveCouponUse, releaseCouponUse } = require('../utils/coupon');
const { CUSTOMER_CANCELLABLE, ADMIN_CANCELLABLE, canMerchantTransition, allowedMerchantNextStatuses } = require('../utils/orderStatus');
const { parseQuantity, reserveStock, restoreStock, recordDailySales, MAX_QUANTITY_PER_ITEM } = require('../utils/stock');

// Who may see / act on an order: its customer, its merchant, or an admin.
// (Compared with the caller's role so ids from other collections never match.)
const idOf = (v) => (v && v._id ? v._id : v);
const canAccessOrder = (req, order, { allowCustomer = true } = {}) => {
    if (!order) return false;
    if (req.userType === 'admin') return true;
    const me = req.user._id.toString();
    if (req.userType === 'merchant') return String(idOf(order.merchant)) === me;
    if (req.userType === 'user') return allowCustomer && String(idOf(order.customer)) === me;
    return false;
};

// Items from the request body, or else from the customer's cart (null if none)
async function resolveOrderItems(userId, items) {
    if (Array.isArray(items) && items.length > 0) return items;
    const cart = await Cart.findOne({ user: userId });
    if (!cart || cart.items.length === 0) return null;
    return cart.items.map(item => ({
        product: item.product,
        quantity: item.quantity,
        preparation: item.preparation
    }));
}

// Quote an order: the exact totals POST /api/orders would charge, no writes.
// POST /api/orders/quote { items?, deliveryType, addressId, couponCode }
exports.quoteOrder = async (req, res) => {
    try {
        if (req.userType !== 'user') {
            return res.status(403).json({ success: false, message: 'Only customers can place orders' });
        }
        const { deliveryType, addressId, deliveryAddress, couponCode } = req.body;
        const items = await resolveOrderItems(req.user._id, req.body.items);
        if (!items) return res.status(400).json({ success: false, message: 'Your cart is empty' });

        const cart = await Cart.findOne({ user: req.user._id });
        const pricing = await priceOrder({
            user: req.user,
            items,
            deliveryType,
            addressId: addressId || deliveryAddress,
            couponCode: couponCode || (cart && cart.appliedCoupon && cart.appliedCoupon.code) || null
        });
        if (!pricing.ok) {
            return res.status(pricing.status).json({ success: false, deliverable: false, message: pricing.message, code: pricing.code });
        }
        res.json({
            success: true,
            data: {
                deliverable: true,
                deliveryType: pricing.deliveryType,
                itemsTotal: pricing.itemsTotal,
                deliveryCharges: pricing.deliveryCharges,
                discount: pricing.discount,
                totalAmount: pricing.totalAmount,
                couponCode: pricing.couponCode,
                couponError: pricing.couponError,
                distanceKm: pricing.delivery.distanceKm,
                zone: pricing.delivery.zone,
                items: pricing.orderItems.map(({ merchant, category, ...i }) => i)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error quoting order', error: error.message });
    }
};

// Create Order
exports.createOrder = async (req, res) => {
    try {
        const userId = req.user.id;
        let {
            items,
            deliveryAddress,
            deliveryType,
            paymentMethod,
            deliveryTimeSlot,
            specialRequests,
            couponCode,
            addressId // Support addressId as well
        } = req.body;

        if (req.userType !== 'user') {
            return res.status(403).json({ success: false, message: 'Only customers can place orders' });
        }

        // If items not provided, use the cart
        items = await resolveOrderItems(userId, items);
        if (!items) {
            return res.status(400).json({
                success: false,
                message: 'Cannot place order with an empty cart'
            });
        }

        // If deliveryAddress not provided but addressId is, use it
        if (!deliveryAddress && addressId) {
            deliveryAddress = addressId;
        }

        // ─── Phase 1: price & validate everything. Nothing is written here. ─────
        // Same function as POST /api/orders/quote, so the app's checkout total
        // is exactly what is charged (items, preparation, delivery, coupon).
        const cart = await Cart.findOne({ user: userId });
        const explicitCoupon = typeof couponCode === 'string' && couponCode.trim() ? couponCode : null;
        const cartCoupon = cart && cart.appliedCoupon && cart.appliedCoupon.code;

        const pricing = await priceOrder({
            user: req.user,
            items,
            deliveryType,
            addressId: deliveryAddress,
            couponCode: explicitCoupon || cartCoupon || null
        });
        if (!pricing.ok) {
            return res.status(pricing.status).json({ success: false, message: pricing.message, code: pricing.code });
        }
        // A coupon the customer typed must be valid; a stale one left in the
        // cart is simply dropped
        if (pricing.couponError && explicitCoupon) {
            return res.status(400).json({ success: false, message: pricing.couponError, code: 'COUPON_INVALID' });
        }

        const { orderItems, merchantId, itemsTotal, deliveryCharges, discount, totalAmount } = pricing;
        const appliedOfferId = pricing.offer ? pricing.offer._id : null;
        const cartCouponCode = pricing.couponCode;
        let couponUsedAt = null;
        deliveryType = pricing.deliveryType;
        deliveryAddress = pricing.address ? pricing.address._id : undefined;

        const sanitizedItems = orderItems.map(({ merchant, category, ...item }) => item);

        const isWalletPayment = paymentMethod === 'wallet';
        const isOnlinePayment = paymentMethod === 'online' || paymentMethod === 'razorpay';

        // ─── Phase 2: reserve stock, coupon use and wallet money. ───────────────
        // Each step is atomic; if a later step (or creating the order) fails,
        // everything reserved so far is released again in reverse order.
        let stockReserved = false;
        let couponReserved = false;
        let walletDebited = false;
        let walletOrderIds = {};

        const releaseReservations = async () => {
            if (walletDebited) {
                try {
                    await creditWalletForOrder(
                        userId,
                        totalAmount,
                        walletOrderIds._id,
                        `Refund: order ${walletOrderIds.orderId} could not be created`
                    );
                } catch (refundError) {
                    console.error(`[Order] CRITICAL: wallet refund failed for user ${userId}, amount ${totalAmount}:`, refundError.message);
                }
            }
            if (couponReserved) {
                await releaseCouponUse(appliedOfferId, userId, couponUsedAt).catch(() => {});
            }
            if (stockReserved) {
                await restoreStock(orderItems).catch(err =>
                    console.error('[Order] stock release failed:', err.message));
            }
        };

        const stock = await reserveStock(orderItems);
        if (!stock.ok) {
            return res.status(400).json({
                success: false,
                message: `Insufficient stock for ${stock.failedItem.name}`
            });
        }
        stockReserved = true;

        if (appliedOfferId) {
            // Atomic: respects total and per-user limits even under concurrency
            couponUsedAt = await reserveCouponUse(appliedOfferId, userId);
            if (!couponUsedAt) {
                await releaseReservations();
                return res.status(400).json({ success: false, message: 'This coupon has just reached its usage limit', code: 'COUPON_INVALID' });
            }
            couponReserved = true;
        }

        if (isWalletPayment) {
            // Generate the order's ids up front so the wallet debit is linked to it
            const orderObjectId = new mongoose.Types.ObjectId();
            const orderNumber = 'GB' + Date.now() + Math.floor(Math.random() * 1000);
            walletOrderIds = { _id: orderObjectId, orderId: orderNumber };

            if (totalAmount > 0) {
                const wallet = await debitWalletForOrder(userId, totalAmount, orderObjectId, orderNumber);
                if (!wallet) {
                    await releaseReservations();
                    const existing = await Wallet.findOne({ user: userId });
                    if (existing && existing.isLocked) {
                        return res.status(403).json({
                            success: false,
                            message: 'Wallet is locked',
                            reason: existing.lockedReason
                        });
                    }
                    return res.status(400).json({
                        success: false,
                        message: 'Insufficient wallet balance',
                        available: existing ? existing.balance : 0,
                        required: totalAmount
                    });
                }
                walletDebited = true;
            }
        }

        const initialStatus = isWalletPayment ? 'confirmed' : (isOnlinePayment ? 'payment_pending' : 'pending');
        const initialNote = isWalletPayment
            ? 'Order placed and paid from wallet'
            : (isOnlinePayment ? 'Order drafted, waiting for payment.' : 'Order placed successfully');

        // ─── Phase 3: create the order ─────────────────────────────────────────
        let order;
        try {
            order = await Order.create({
                ...walletOrderIds,
                customer: userId,
                merchant: merchantId,
                items: sanitizedItems,
                itemsTotal,
                deliveryCharges,
                discount,
                totalAmount,
                deliveryType,
                deliveryAddress,
                deliveryTimeSlot,
                paymentMethod: ['cod', 'online', 'wallet'].includes(paymentMethod) ? paymentMethod : 
                              (['razorpay', 'phonepe'].includes(paymentMethod) ? 'online' : 'cod'),
                paymentStatus: isWalletPayment ? 'completed' : 'pending',
                status: initialStatus,
                ...(isWalletPayment ? { confirmedAt: new Date() } : {}),
                paymentGateway: {
                    provider: ['phonepe', 'cod', 'razorpay', 'wallet'].includes(paymentMethod) ? paymentMethod : 'cod'
                },
                specialRequests,
                couponCode: cartCouponCode,
                ...(couponReserved ? { appliedOffer: appliedOfferId, couponUsedAt } : {}),
                statusHistory: [{
                    status: initialStatus,
                    timestamp: new Date(),
                    note: initialNote,
                    updatedBy: userId,
                    updatedByModel: 'User'
                }]
            });
        } catch (createError) {
            await releaseReservations();
            throw createError;
        }

        recordDailySales(orderItems).catch(() => {});

        // Clear cart ONLY for COD or Wallet (Online payments clear cart after verification)
        if (paymentMethod === 'cod' || paymentMethod === 'wallet') {
            await Cart.findOneAndUpdate(
                { user: userId },
                { 
                    items: [], 
                    total: 0, 
                    discount: 0, 
                    finalTotal: 0, 
                    appliedCoupon: { code: null, offerId: null, discount: 0 } 
                }
            );
        } else {
            // For online payments, we keep the cart until payment is verified.
            // However, we might want to mark the cart as 'checking_out' or similar
            // to prevent double-spending, but for this mini-project, keeping it simple is fine.
            console.log(`[Order] Online payment initiated for order ${order.orderId}. Cart NOT cleared yet.`);
        }

        // Online orders are announced (to merchant and customer) only once paid:
        // see paymentController.afterOrderPaid. Announcing unpaid drafts showed
        // merchants orders they couldn't act on and told customers an
        // abandoned checkout was "placed".
        if (!isOnlinePayment) {
            // Real-time notification to merchant
            OrderSocket.notifyNewOrder(merchantId, {
                orderId: order.orderId,
                customerName: req.user.name,
                totalAmount: order.totalAmount,
                itemsCount: order.items.length
            });

            // Create notification
            await notificationService.createNotification({
                recipient: merchantId,
                recipientModel: 'Merchant',
                type: 'order',
                title: 'New Order Received',
                message: `New order ${order.orderId} from ${req.user.name}`,
                data: { orderId: order._id }
            });

            // ── Customer confirmation: inApp + email + SMS + push ─────────────
            const customer = await User.findById(userId);
            const merchant = await Merchant.findById(merchantId);
            if (customer) {
                await notificationService.send(userId, 'User', {
                    type: 'order_placed',
                    title: '📦 Order Placed!',
                    message: `Your order ${order.orderId} (\u20b9${order.totalAmount}) has been placed successfully.`,
                    data: { 
                        orderId: order._id.toString(),
                        customerName: customer.name,
                        merchantName: merchant?.businessName || 'Merchant',
                        totalAmount: order.totalAmount.toFixed(2)
                    },
                    channels: ['push', 'email', 'sms', 'inApp'],
                    priority: 'high'
                });
            }

            // Merchant SMS for new order (non-blocking)
            if (merchant && merchant.phone) {
                notify.sms(merchant.phone, `New order ${order.orderId} from ${req.user.name}! Total: \u20b9${order.totalAmount}. ${order.items.length} item(s). Open the app to accept.`).catch(() => {});
            }
        }
        // ───────────────────────────────────────────────────────────────────

        res.status(201).json({
            success: true,
            message: 'Order placed successfully',
            data: { order }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error creating order',
            error: error.message
        });
    }
};

// Get My Orders (Customer)
exports.getMyOrders = async (req, res) => {
    try {
        const userId = req.user.id;
        const { page = 1, limit = 10, status } = req.query;

        const query = { customer: userId };
        if (status) query.status = status;

        const orders = await Order.find(query)
            .populate('merchant', 'businessName profileImage')
            .populate('items.product', 'name primaryImage')
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit);

        const total = await Order.countDocuments(query);

        res.json({
            success: true,
            data: {
                orders,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching orders',
            error: error.message
        });
    }
};

// Get Merchant Orders
exports.getMerchantOrders = async (req, res) => {
    try {
        const merchantId = req.user.id;
        const { page = 1, limit = 10, status } = req.query;

        const query = { merchant: merchantId, status: { $ne: 'payment_pending' } };
        if (status) {
            query.status = status;
        }

        const orders = await Order.find(query)
            .populate('customer', 'name phone profileImage')
            .populate('deliveryAddress')
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit);

        const total = await Order.countDocuments(query);

        res.json({
            success: true,
            data: {
                orders,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching orders',
            error: error.message
        });
    }
};

// Update Order Status (Merchant)
exports.updateOrderStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, note } = req.body;
        const merchantId = req.user.id;

        if (!status) {
            return res.status(400).json({
                success: false,
                message: 'Status is required'
            });
        }

        const query = mongoose.Types.ObjectId.isValid(id)
            ? { _id: id, merchant: merchantId }
            : { orderId: id, merchant: merchantId };

        const order = await Order.findOne(query)
            .populate('customer', 'name email phone')
            .populate('items.product', 'name primaryImage')
            .populate('deliveryAddress');

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        // ─── Only allowed transitions (see src/utils/orderStatus.js) ────────────
        if (!canMerchantTransition(order.status, status, order.deliveryType)) {
            const allowed = allowedMerchantNextStatuses(order);
            return res.status(400).json({
                success: false,
                message: allowed.length
                    ? `Cannot change a ${order.status} order to ${status}. Allowed: ${allowed.join(', ')}`
                    : `A ${order.status} order can no longer be changed`,
                allowedNextStatuses: allowed
            });
        }

        if (status === 'cancelled') {
            // Restores stock, releases the coupon, refunds prepaid orders
            const result = await lifecycle.cancelOrder(order._id, {
                by: 'merchant',
                actorId: req.user._id,
                actorModel: 'Merchant',
                reason: note,
                allowedFrom: [order.status]
            });
            if (!result.ok) {
                return res.status(409).json({ success: false, message: 'Order status changed meanwhile; please refresh' });
            }
            Object.assign(order, { status: 'cancelled' });
        } else {
            // Update status with history
            order.status = status;

            const statusEntry = {
                status,
                timestamp: new Date(),
                note: note || getStatusMessage(status),
                updatedBy: req.user._id,
                updatedByModel: 'Merchant'
            };

            order.statusHistory.push(statusEntry);

            // Update specific timestamps
            if (status === 'confirmed' && !order.confirmedAt) {
                order.confirmedAt = new Date();
            }
            if (status === 'out-for-delivery') order.outForDeliveryAt = new Date();
            if (status === 'delivered' || (status === 'completed' && !order.deliveredAt)) order.deliveredAt = new Date();

            // Cash on delivery is collected when the order is handed over
            if ((status === 'delivered' || status === 'completed') && order.paymentMethod === 'cod'
                && order.paymentStatus === 'pending') {
                order.paymentStatus = 'completed';
            }

            await order.save();
        }

        // ─── Loyalty points: once per order, when it is handed over ─────────────
        if (status === 'delivered' || status === 'completed') {
            try {
                const award = await lifecycle.awardLoyaltyOnce(order);
                if (award) {
                    await notificationService.createNotification({
                        recipient: order.customer._id,
                        recipientModel: 'User',
                        type: 'loyalty',
                        title: award.tierUpgraded
                            ? `🎉 Tier Upgrade! You're now ${award.newTier.toUpperCase()}`
                            : '⭐ Loyalty Points Earned',
                        message: award.tierUpgraded
                            ? `You earned ${award.points} points and reached ${award.newTier} tier!`
                            : `You earned ${award.points} loyalty points for order ${order.orderId}`,
                        data: { orderId: order._id, pointsEarned: award.points, newTotalPoints: award.newTotalPoints, tier: award.newTier }
                    });
                }
            } catch (loyaltyError) {
                console.error('⚠️ Loyalty points award failed (non-blocking):', loyaltyError.message);
            }
        }
        // ────────────────────────────────────────────────────────────────────

        // Real-time update to customer & Notifications
        try {
            OrderSocket.notifyOrderStatusUpdate(order.customer._id, {
                orderId: order.orderId,
                status: order.status,
                statusMessage: getStatusMessage(status)
            });

            await notificationService.createNotification({
                recipient: order.customer._id,
                recipientModel: 'User',
                type: 'order',
                title: 'Order Status Updated',
                message: `Your order ${order.orderId} is now ${status}`,
                data: { orderId: order._id, status }
            });

            // ── Multi-channel notifications per status ──────────────────
            const statusMap = {
                'confirmed':        { emoji: '✅', label: 'Confirmed',        class: 'confirmed',        msg: 'Your order has been confirmed by the merchant and is being prepared.' },
                'preparing':        { emoji: '👩‍🍳', label: 'Preparing',        class: 'preparing',        msg: 'The merchant is currently preparing your fresh produce.' },
                'ready':            { 
                    emoji: '📦', 
                    label: order.deliveryType === 'pickup' ? 'Ready for Pick Up' : 'Ready',            
                    class: 'ready',            
                    msg: order.deliveryType === 'pickup' 
                        ? 'Your order is ready for pick up at the store! Please visit and collect your fresh products.' 
                        : 'Your order is ready! Wait for delivery personnel.' 
                },
                'out-for-delivery': { emoji: '🚚', label: 'Out for Delivery', class: 'out-for-delivery', msg: 'Your order is on its way to you!' },
                'delivered':        { emoji: '🎉', label: 'Delivered',        class: 'delivered',        msg: 'Your order has been delivered. Enjoy your fresh produce!' },
                'completed':        { emoji: '✅', label: 'Completed',        class: 'completed',        msg: 'Your order has been completed. Thank you for shopping with Green Basket!' },
                'cancelled':        { emoji: '❌', label: 'Cancelled',        class: 'cancelled',        msg: 'Your order has been cancelled by the merchant.' }
            };
            const info = statusMap[status] || { emoji: '📦', label: status, class: status, msg: getStatusMessage(status) };

            const customerData = order.customer; // already populated
            if (customerData && customerData.email) {
                notify.all({
                    user: { _id: customerData._id, email: customerData.email, phone: customerData.phone },
                    subject: `Order ${order.orderId} — ${info.label}`,
                    template: 'orderStatusUpdate',
                    templateData: {
                        customerName: customerData.name,
                        orderId: order.orderId,
                        statusEmoji: info.emoji,
                        statusLabel: info.label,
                        statusClass: info.class,
                        statusMessage: info.msg,
                        note: note || '',
                        year: new Date().getFullYear()
                    },
                    smsBody: `Green Basket: Order ${order.orderId} is now ${info.label}. ${info.msg}`,
                    pushTitle: `${info.emoji} Order ${info.label}`,
                    pushBody: `Order ${order.orderId}: ${info.msg}`,
                    pushData: { orderId: order._id.toString(), status, type: 'order_status' }
                }).catch(() => {});
            }
            // ────────────────────────────────────────────────────────────
        } catch (error) {
            console.error('⚠️ Error sending status update notification:', error.message);
            // Don't fail the whole request for notification errors
        }

        res.json({
            success: true,
            message: 'Order status updated',
            data: order,
            allowedNextStatuses: allowedMerchantNextStatuses(order)
        });
    } catch (error) {
        console.error('❌ Status update failed:', error);
        res.status(500).json({
            success: false,
            message: 'Error updating order status',
            error: error.message
        });
    }
};

// Get Order By ID
exports.getOrderById = async (req, res) => {
    try {
        const { id } = req.params;

        const query = mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { orderId: id };

        const order = await Order.findOne(query)
            .populate('customer', 'name email phone')
            .populate('merchant', 'businessName phone')
            .populate('items.product', 'name primaryImage')
            .populate('deliveryAddress');

        // 404 (not 403) so order numbers can't be probed
        if (!order || !canAccessOrder(req, order)) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        res.json({
            success: true,
            data: order
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching order',
            error: error.message
        });
    }
};

// Cancel Order
exports.cancelOrder = async (req, res) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;
        const userId = req.user.id;
        const isAdmin = req.userType === 'admin';

        if (req.userType === 'merchant') {
            return res.status(403).json({
                success: false,
                message: 'Merchants cancel orders via PATCH /api/orders/merchant/:id/status'
            });
        }

        // Customers can only cancel their own orders; admins any order
        const idQuery = mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { orderId: id };
        const existing = await Order.findOne(isAdmin ? idQuery : { ...idQuery, customer: userId });

        if (!existing) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        const allowedFrom = isAdmin ? ADMIN_CANCELLABLE : CUSTOMER_CANCELLABLE;
        const result = await lifecycle.cancelOrder(existing._id, {
            by: isAdmin ? 'admin' : 'customer',
            actorId: req.user._id,
            actorModel: isAdmin ? 'Admin' : 'User',
            reason,
            allowedFrom
        });

        if (!result.ok) {
            const status = result.order ? result.order.status : existing.status;
            return res.status(400).json({
                success: false,
                message: isAdmin
                    ? `Cannot cancel an order that is ${status}`
                    : `This order can no longer be cancelled (status: ${status}). Please raise a return or dispute instead.`
            });
        }
        const order = result.order;

        // Notify merchant
        OrderSocket.notifyOrderCancellation(order.merchant, 'merchant', {
            orderId: order.orderId,
            reason
        });

        // ── Cancellation notifications to both parties ───────────────────
        // Merchant notification (in-app + email/SMS)
        await notificationService.createNotification({
            recipient: order.merchant,
            recipientModel: 'Merchant',
            type: 'order_cancelled',
            title: 'Order Cancelled',
            message: `Order ${order.orderId} has been cancelled by ${isAdmin ? 'Green Basket support' : 'the customer'}.${reason ? ' Reason: ' + reason : ''}`,
            data: { orderId: order._id }
        });

        // Customer confirmation
        const cancelCustomer = await User.findById(order.customer);
        const cancelMerchant = await Merchant.findById(order.merchant);
        if (cancelCustomer) {
            notify.all({
                user: cancelCustomer,
                subject: `Order ${order.orderId} — Cancelled`,
                template: 'orderStatusUpdate',
                templateData: {
                    customerName: cancelCustomer.name,
                    orderId: order.orderId,
                    statusEmoji: '❌',
                    statusLabel: 'Cancelled',
                    statusClass: 'cancelled',
                    statusMessage: isAdmin ? 'Your order has been cancelled by Green Basket support.' : 'Your order has been cancelled as requested.',
                    note: reason || '',
                    year: new Date().getFullYear()
                },
                smsBody: `Green Basket: Order ${order.orderId} cancelled.${reason ? ' Reason: ' + reason : ''} Any prepaid amount will be refunded.`,
                pushTitle: '❌ Order Cancelled',
                pushBody: `Order ${order.orderId} has been cancelled.`,
                pushData: { orderId: order._id.toString(), type: 'order_cancelled' }
            }).catch(() => {});
        }
        // SMS to merchant about cancellation
        if (cancelMerchant && cancelMerchant.phone) {
            notify.sms(cancelMerchant.phone, `Order ${order.orderId} cancelled by ${isAdmin ? 'Green Basket support' : 'customer'}.${reason ? ' Reason: ' + reason : ''}`).catch(() => {});
        }
        // ─────────────────────────────────────────────────────────────────

        res.json({
            success: true,
            message: result.refund && result.refund.refunded
                ? `Order cancelled. ₹${result.refund.amount} will be refunded to your ${result.refund.method === 'wallet' ? 'wallet' : 'original payment method'}.`
                : 'Order cancelled successfully',
            data: { order, refund: result.refund }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error cancelling order',
            error: error.message
        });
    }
};

// Helper function
const getStatusMessage = (status) => {
    const messages = {
        'confirmed': 'Your order has been confirmed',
        'preparing': 'Merchant is preparing your order',
        'ready': 'Your order is ready',
        'out-for-delivery': 'Your order is out for delivery',
        'delivered': 'Your order has been delivered',
        'completed': 'Your order has been completed',
        'cancelled': 'Your order has been cancelled'
    };
    return messages[status] || 'Order status updated';
};

// Add Review
exports.addReview = async (req, res) => {
    try {
        const { id } = req.params;
        const { rating, comment, images } = req.body;
        const userId = req.user.id;

        const order = await Order.findOne({ _id: id, customer: userId });

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        if (order.status !== 'delivered') {
            return res.status(400).json({
                success: false,
                message: 'Can only review delivered orders'
            });
        }

        // Check if already reviewed (naive check on order level, though usually reviews are per product)
        // User schema snippet implies review is linked to order, product, etc.
        // But here we are reviewing the ORDER or the PRODUCTS?
        // User schema for Review: order, customer, merchant, product.
        // So a review is per product in an order.
        // But the endpoint is `/api/orders/:id/review`.
        // This suggests reviewing the whole order OR submitting multiple reviews for items.
        // Let's assume it reviews the *Order* (maybe Merchant interaction) AND/OR *Products*.
        // The Review model has `product` field required.
        // This endpoint likely needs to handle creating reviews for each product in the order?

        // Actually, looking at the Review Schema:
        // product: linked to product.
        // So we likely need to iterate over items and create reviews, OR this endpoint receives a specific product ID?
        // Usually `/api/orders/:id/review` implies "Review this order". But if Review requires Product, it's ambiguous.

        // Let's look at `reviewRoutes.js` or descriptions.
        // "Review System" ... "Rating and review system"

        // I will assume the body contains `reviews: [{ productId, rating, comment }]` OR `productId, rating, comment`.
        // If the schema requires Product, we can't just review the Order. 
        // OR maybe the user schema implies one review per order?
        // "product: ... required: true" -> So it IS per product.

        // Let's implement creating reviews for products in the order.
        // But wait, if I use `addReview`, I need the `Review` model.

        // I'll make it simple: Body should have `productId`.

        const Review = require('../models/Review'); // lazy require or move to top

        // Validate productId is in order
        const item = order.items.find(i => i.product.toString() === req.body.productId);
        if (!item) {
            return res.status(400).json({ message: 'Product not in this order' });
        }

        const review = await Review.create({
            order: id,
            customer: userId,
            merchant: order.merchant,
            product: req.body.productId,
            rating,
            comment,
            images
        });

        // Update product average rating
        const Product = require('../models/Product');
        const stats = await Review.aggregate([
            { $match: { product: new mongoose.Types.ObjectId(req.body.productId) } },
            { $group: { _id: '$product', nRating: { $sum: 1 }, avgRating: { $avg: '$rating' } } }
        ]);

        await Product.findByIdAndUpdate(req.body.productId, {
            averageRating: stats[0].avgRating,
            totalReviews: stats[0].nRating
        });

        // Update order reviewed status if all items reviewed? 
        // Or just mark order as reviewed.
        order.rating = rating; // Assuming order also has a rating field? Schema said: rating, review reviewedAt.
        order.review = comment;
        order.reviewedAt = new Date();
        await order.save(); // This reviews the ORDER itself. 
        // The Review Model is for PRODUCTS. 
        // The Order Model has rating/review fields too!

        // Okay, Order Model has `rating` and `review` fields.
        // AND there is a `Review` model.
        // This is a bit duplicative or they serve different purposes (Order Rating vs Product Review).
        // I will implement saving to Order Model AND creating a Review document for the merchant?
        // Review model has `product` field required.
        // If the user wants to review the ORDER (Experience), they update Order model.
        // If they want to review PRODUCTS, they create Review documents.

        // Given the endpoint is `/api/orders/:id/review`, it strongly suggests updating the Order's rating/review.
        // I will do that as primary.

        // AND/OR create a Review for the products?
        // Because Review schema exists and requires Product, maybe there is a separate route for product reviews?
        // But Review also has `order` field.

        // I'll assume this endpoint updates the Order's own rating (Merchant feedback) and OPTIONALLY creates product reviews if provided?
        // Or maybe this endpoint is just for the Order/Merchant experience.

        // I'll stick to updating Order fields for now as that's safe, and maybe create a general 'Review' if product is specified.

        // Let's keep it simple: Update Order rating/review.

        order.rating = rating;
        order.review = comment;
        order.reviewedAt = new Date();
        await order.save();

        res.json({ success: true, data: order });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error adding review',
            error: error.message
        });
    }
};

// Enhanced Order Tracking
exports.enhancedTrackOrder = async (req, res) => {
    try {
        const { id } = req.params;
        const query = mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { orderId: id };

        const order = await Order.findOne(query)
            .populate('deliveryPersonnel', 'name phone vehicleNumber')
            .populate('merchant', 'businessName phone') // Location might not be in merchant model selection directly or needs processing
            .select('orderId status statusHistory estimatedDeliveryTime deliveryPersonnel merchant customer');

        if (!order || !canAccessOrder(req, order)) {
            return res.status(404).json({ success: false, message: 'Order not found' });
        }

        // Calculate progress percentage
        const statusSteps = ['pending', 'confirmed', 'out-for-delivery', 'delivered'];
        const currentStepIndex = statusSteps.indexOf(order.status);
        const progress = Math.max(0, Math.round(((currentStepIndex + 1) / statusSteps.length) * 100));

        // Mock current location if not available
        const currentLocation = order.deliveryPersonnel?.currentLocation ||
            (order.merchant?.location ? order.merchant.location : { lat: 12.9716, lng: 77.5946 });

        res.json({
            success: true,
            data: {
                orderId: order.orderId,
                status: order.status,
                progress,
                estimatedDelivery: order.estimatedDeliveryTime || new Date(Date.now() + 30 * 60 * 1000), // Mock 30 mins
                currentLocation,
                timeline: (order.statusHistory || []).sort((a, b) => b.timestamp - a.timestamp),
                deliveryPersonnel: order.deliveryPersonnel,
                merchant: order.merchant
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.updateOrderLocation = async (req, res) => {
    try {
        const { id } = req.params;
        const { lat, lng } = req.body;

        if (!lat || !lng) {
            return res.status(400).json({ success: false, error: 'Latitude and longitude are required' });
        }

        const query = mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { orderId: id };
        const order = await Order.findOne(query);
        // Only the merchant fulfilling the order (or an admin) may move the tracking pin
        if (!order || !canAccessOrder(req, order, { allowCustomer: false })) {
            return res.status(404).json({ success: false, error: 'Order not found' });
        }

        if (!order.deliveryPersonnel) order.deliveryPersonnel = {};

        order.deliveryPersonnel.currentLocation = {
            lat,
            lng,
            updatedAt: new Date()
        };
        await order.save();

        OrderSocket.updateOrderLocation(order._id, order.customer, { lat, lng });

        res.json({ success: true, message: 'Location updated' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

/**
 * @desc    Get comprehensive order tracking information
 * @route   GET /api/orders/:orderId/tracking
 * @access  Private (User/Merchant/Admin)
 */
exports.getOrderTracking = async (req, res) => {
    try {
        const { orderId } = req.params;

        const order = await Order.findOne({ orderId })
            .populate('merchant', 'businessName phone')
            .populate('customer', 'name phone');

        if (!order) {
            return res.status(404).json({ success: false, error: 'Order not found' });
        }

        // Access control (role comes from req.userType, not req.user)
        if (!canAccessOrder(req, order)) {
            return res.status(404).json({ success: false, error: 'Order not found' });
        }

        // Build timeline
        const statusConfig = [
            { status: 'pending', label: 'Order Placed', description: 'Your order has been placed successfully' },
            { status: 'confirmed', label: 'Order Confirmed', description: 'Merchant has confirmed your order' },
            { status: 'out-for-delivery', label: 'Out for Delivery', description: 'Your order is on the way' },
            { status: 'delivered', label: 'Delivered', description: 'Order delivered successfully' }
        ];

        if (order.status === 'cancelled') {
            statusConfig.push({
                status: 'cancelled',
                label: 'Cancelled',
                description: 'Order has been cancelled'
            });
        }

        const historyMap = {};
        (order.statusHistory || []).forEach(h => {
            historyMap[h.status] = { timestamp: h.timestamp, note: h.note };
        });

        const timeline = statusConfig.map(config => ({
            status: config.status,
            label: config.label,
            description: config.description,
            timestamp: historyMap[config.status]?.timestamp || null,
            note: historyMap[config.status]?.note || null,
            completed: !!historyMap[config.status]
        }));

        res.json({
            success: true,
            data: {
                orderId: order.orderId,
                status: order.status,
                estimatedDeliveryTime: order.estimatedDeliveryTime,
                deliveryPersonnel: order.deliveryPersonnel,
                merchant: {
                    businessName: order.merchant.businessName,
                    phone: order.merchant.phone
                },
                deliveryAddress: order.deliveryAddress,
                timeline
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch order tracking',
            details: error.message
        });
    }
};

