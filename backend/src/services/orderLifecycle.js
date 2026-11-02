/**
 * Order lifecycle operations shared by customers, merchants, admins and
 * background jobs: cancelling (with stock/coupon/loyalty/payment unwinding),
 * refunding, and awarding loyalty points exactly once.
 */
const Order = require('../models/Order');
const Offer = require('../models/Offer');
const User = require('../models/User');
const LoyaltyLog = require('../models/LoyaltyLog');
const paymentService = require('./paymentService');
const { restoreStock } = require('../utils/stock');
const { creditWalletForOrder } = require('../utils/walletHelpers');
const { LOYALTY_TIERS, getTierFromPoints } = require('../config/loyaltyTiers');

const isPaid = (order) => ['completed', 'paid'].includes(order.paymentStatus);
const refundInFlight = (order) => order.refund && ['initiated', 'processing', 'completed'].includes(order.refund.status);

/**
 * Refund what the customer paid for an order: wallet orders go back to the
 * wallet, Razorpay orders are refunded through Razorpay, COD needs nothing.
 * Mutates `order` (refund, paymentStatus, paymentEvents); the caller saves.
 *
 * @returns {{ refunded: boolean, method?: string, amount?: number, error?: string }}
 */
async function refundOrderPayment(order, { reason, amount } = {}) {
    if (!isPaid(order)) return { refunded: false, method: 'none' };
    if (refundInFlight(order)) return { refunded: false, method: 'already-refunded' };

    const refundAmount = amount !== undefined ? amount : order.totalAmount;
    const provider = order.paymentGateway && order.paymentGateway.provider;
    order.refund = order.refund || {};
    order.refund.amount = refundAmount;
    order.refund.reason = reason;
    order.refund.initiatedAt = new Date();

    if (order.paymentMethod === 'wallet' || provider === 'wallet') {
        await creditWalletForOrder(order.customer, refundAmount, order._id, `Refund for order ${order.orderId}`);
        order.refund.status = 'completed';
        order.refund.completedAt = new Date();
        order.paymentStatus = 'refunded';
        return { refunded: true, method: 'wallet', amount: refundAmount };
    }

    if (provider === 'razorpay' && order.razorpayPaymentId) {
        try {
            const refund = await paymentService.processRazorpayRefund(order.razorpayPaymentId, refundAmount, reason);
            order.refund.status = 'processing';
            order.paymentStatus = 'refunded';
            order.paymentEvents.push({ event: 'refund_initiated', data: { refundId: refund && refund.id, amount: refundAmount } });
            return { refunded: true, method: 'razorpay', amount: refundAmount };
        } catch (error) {
            // Keep the order cancelled; an admin can retry via POST /api/payment/refund
            order.refund.status = 'failed';
            order.refund.failureReason = error.message;
            console.error(`[Refund] Razorpay refund failed for ${order.orderId}:`, error.message);
            return { refunded: false, method: 'razorpay', error: error.message };
        }
    }

    return { refunded: false, method: 'none' };
}

/** Give a reserved coupon use back. */
async function releaseCoupon(order) {
    if (!order.appliedOffer) return;
    await Offer.findByIdAndUpdate(order.appliedOffer, {
        $inc: { usedCount: -1 },
        $pull: { usedBy: { user: order.customer, ...(order.couponUsedAt ? { usedAt: order.couponUsedAt } : {}) } }
    }).catch(err => console.error('[Order] coupon release failed:', err.message));
}

/** Take back loyalty points that were awarded for this order (at most once). */
async function reverseLoyalty(order) {
    const points = order.loyaltyPointsAwarded || 0;
    if (points <= 0) return 0;
    const claim = await Order.updateOne(
        { _id: order._id, loyaltyPointsAwarded: { $gt: 0 } },
        { $set: { loyaltyPointsAwarded: 0 } }
    );
    if (claim.modifiedCount !== 1) return 0;
    order.loyaltyPointsAwarded = 0;

    const customerId = order.customer._id || order.customer;
    const user = await User.findByIdAndUpdate(
        customerId,
        [{ $set: { loyaltyPoints: { $max: [0, { $subtract: [{ $ifNull: ['$loyaltyPoints', 0] }, points] }] } } }],
        { new: true }
    );
    if (user) {
        await User.updateOne({ _id: user._id }, { $set: { loyaltyTier: getTierFromPoints(user.loyaltyPoints) } });
    }
    await LoyaltyLog.create({
        user: customerId,
        type: 'reversed',
        points: -points,
        description: `Reversed ${points} points for cancelled/refunded order ${order.orderId}`,
        order: order._id
    }).catch(() => {});
    return points;
}

/**
 * Cancel an order and unwind everything it reserved.
 *
 * The status change is atomic and conditional on the current status being in
 * `allowedFrom`, so two concurrent cancels can't both restore stock or refund.
 *
 * @returns {{ ok: true, order, refund } | { ok: false, order: currentOrNull }}
 */
async function cancelOrder(orderId, { by, actorId, actorModel, reason, allowedFrom }) {
    const now = new Date();
    const order = await Order.findOneAndUpdate(
        { _id: orderId, status: { $in: allowedFrom } },
        {
            $set: { status: 'cancelled', cancelledBy: by, cancellationReason: reason, cancelledAt: now },
            $push: {
                statusHistory: {
                    status: 'cancelled',
                    timestamp: now,
                    note: reason ? `Cancelled by ${by}: ${reason}` : `Cancelled by ${by}`,
                    updatedBy: actorId,
                    updatedByModel: actorModel
                }
            }
        },
        { new: true }
    );
    if (!order) return { ok: false, order: await Order.findById(orderId) };

    await restoreStock(order.items).catch(err => console.error('[Order] stock restore failed:', err.message));
    await releaseCoupon(order);
    await reverseLoyalty(order);
    const refund = await refundOrderPayment(order, { reason: reason || `Order cancelled by ${by}` });
    await order.save();
    return { ok: true, order, refund };
}

/**
 * Award loyalty points for a finished order, exactly once.
 * Rate: 1 point per ₹10, plus the tier bonus from config/loyaltyTiers.js.
 *
 * @returns {null | { points, newTier, tierUpgraded, newTotalPoints }}
 */
async function awardLoyaltyOnce(order) {
    if (order.loyaltyAwardedAt || !isPaid(order)) return null;
    const customerId = order.customer._id || order.customer;
    const customer = await User.findById(customerId);
    if (!customer) return null;

    const currentTier = customer.loyaltyTier || 'bronze';
    const bonusPct = (LOYALTY_TIERS[currentTier] && LOYALTY_TIERS[currentTier].benefits.extraPointsPercentage) || 0;
    const points = Math.floor(Math.floor(order.totalAmount / 10) * (1 + bonusPct / 100));
    if (points <= 0) return null;

    const claim = await Order.updateOne(
        { _id: order._id, loyaltyAwardedAt: null },
        { $set: { loyaltyAwardedAt: new Date(), loyaltyPointsAwarded: points } }
    );
    if (claim.modifiedCount !== 1) return null; // someone else already awarded
    order.loyaltyAwardedAt = new Date();
    order.loyaltyPointsAwarded = points;

    const updated = await User.findByIdAndUpdate(customerId, { $inc: { loyaltyPoints: points } }, { new: true });
    const newTier = getTierFromPoints(updated.loyaltyPoints);
    if (newTier !== updated.loyaltyTier) {
        await User.updateOne({ _id: customerId }, { $set: { loyaltyTier: newTier } });
    }
    await LoyaltyLog.create({
        user: customerId,
        type: 'earned',
        points,
        description: `Earned ${points} points for order ${order.orderId}`,
        order: order._id,
        metadata: { orderTotal: order.totalAmount, tier: currentTier, bonusPercentage: bonusPct }
    });
    return { points, newTier, tierUpgraded: newTier !== currentTier, newTotalPoints: updated.loyaltyPoints };
}

/**
 * Mark an online (Razorpay) order paid, exactly once. Used by both
 * POST /api/payment/verify and the Razorpay webhook, whichever comes first.
 *
 * The update is conditional on the order still being unpaid and not
 * cancelled. If the payment arrives for an order that was cancelled
 * meanwhile (e.g. expired) or already paid another way, the captured
 * Razorpay payment is refunded so the customer is never charged for nothing.
 *
 * @returns {{ confirmed: boolean, order, alreadyPaid?: boolean, refundedLatePayment?: boolean }}
 */
async function confirmRazorpayPayment(orderDoc, { razorpayOrderId, razorpayPaymentId, source = 'verify' }) {
    const now = new Date();
    const order = await Order.findOneAndUpdate(
        {
            _id: orderDoc._id,
            paymentStatus: { $nin: ['completed', 'paid', 'refunded'] },
            status: { $nin: ['cancelled', 'refunded'] }
        },
        {
            $set: {
                paymentStatus: 'completed',
                status: 'confirmed',
                confirmedAt: orderDoc.confirmedAt || now,
                razorpayPaymentId,
                'paymentGateway.provider': 'razorpay',
                'paymentGateway.paymentIntentId': razorpayOrderId,
                'paymentGateway.transactionId': razorpayPaymentId
            },
            $push: {
                statusHistory: {
                    status: 'confirmed', timestamp: now,
                    note: `Payment verified via Razorpay (${source}). Order confirmed.`,
                    updatedByModel: 'System'
                },
                paymentEvents: { event: 'payment_captured', data: { razorpayPaymentId, razorpayOrderId, source } }
            }
        },
        { new: true }
    );
    if (order) return { confirmed: true, order };

    const current = await Order.findById(orderDoc._id);
    if (!current) return { confirmed: false, order: null };

    // Same payment already recorded → idempotent success
    if (isPaid(current) && current.razorpayPaymentId === razorpayPaymentId) {
        return { confirmed: false, alreadyPaid: true, order: current };
    }

    // Paid for an order that is cancelled, or was already paid another way:
    // give this payment back.
    const alreadyRefunded = (current.paymentEvents || []).some(e =>
        e.event === 'refund_initiated' && e.data && e.data.razorpayPaymentId === razorpayPaymentId);
    if (!alreadyRefunded) {
        try {
            const amount = current.totalAmount;
            const refund = await paymentService.processRazorpayRefund(razorpayPaymentId, amount,
                `Automatic refund: order ${current.orderId} is ${current.status}`);
            current.paymentEvents.push({
                event: 'refund_initiated',
                data: { razorpayPaymentId, refundId: refund && refund.id, amount, reason: 'late_or_duplicate_payment' }
            });
            await current.save();
        } catch (error) {
            console.error(`[Payment] CRITICAL: could not refund late payment ${razorpayPaymentId} for ${current.orderId}:`, error.message);
        }
    }
    return { confirmed: false, refundedLatePayment: true, order: current };
}

/**
 * Cancel online orders whose payment never completed, releasing their stock.
 * Before cancelling, Razorpay is asked whether the order was actually paid
 * (in case the app died before /verify and the webhook was missed).
 */
async function expireUnpaidOrders({ olderThanMinutes = 30 } = {}) {
    const cutoff = new Date(Date.now() - olderThanMinutes * 60 * 1000);
    const stale = await Order.find({
        status: 'payment_pending',
        paymentStatus: { $nin: ['completed', 'paid', 'refunded'] },
        createdAt: { $lt: cutoff }
    }).limit(200);

    const summary = { checked: stale.length, cancelled: 0, confirmed: 0 };
    for (const order of stale) {
        if (order.razorpayOrderId && paymentService.getRazorpayOrderPayments) {
            try {
                const payments = await paymentService.getRazorpayOrderPayments(order.razorpayOrderId);
                const captured = (payments || []).find(p =>
                    ['captured', 'authorized'].includes(p.status) && p.amount === Math.round(order.totalAmount * 100));
                if (captured) {
                    const r = await confirmRazorpayPayment(order, {
                        razorpayOrderId: order.razorpayOrderId, razorpayPaymentId: captured.id, source: 'expiry-check'
                    });
                    if (r.confirmed) { summary.confirmed++; continue; }
                }
            } catch (error) {
                // Razorpay unreachable: don't cancel an order that might be paid; retry next run
                console.error(`[Expiry] could not check Razorpay for ${order.orderId}:`, error.message);
                continue;
            }
        }
        const result = await cancelOrder(order._id, {
            by: 'system', actorModel: 'System',
            reason: `Payment not completed within ${olderThanMinutes} minutes`,
            allowedFrom: ['payment_pending']
        });
        if (result.ok) summary.cancelled++;
    }
    return summary;
}

module.exports = {
    cancelOrder, refundOrderPayment, releaseCoupon, reverseLoyalty, awardLoyaltyOnce, isPaid,
    confirmRazorpayPayment, expireUnpaidOrders
};
