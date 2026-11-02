const mongoose = require('mongoose');
const Offer = require('../models/Offer');
const { round2 } = require('./pricing');

/**
 * Validate a coupon for a cart/order and compute its discount. Used by both
 * POST /api/cart/apply-coupon and order creation, so they always agree.
 *
 * @param {Object} offer   Offer document (or null)
 * @param {Object} ctx     { userId, merchantId, items: [{ product, category, subtotal }], itemsTotal, deliveryCharges }
 * @returns {{ ok: true, discount } | { ok: false, reason }}
 */
function validateCoupon(offer, { userId, merchantId, items = [], itemsTotal = 0, deliveryCharges = 0, now = new Date() }) {
    if (!offer) return { ok: false, reason: 'Invalid or expired coupon' };
    if (offer.status !== 'active') return { ok: false, reason: 'This coupon is not active' };
    if (offer.startDate && now < offer.startDate) return { ok: false, reason: 'This coupon is not active yet' };
    if (offer.endDate && now > offer.endDate) return { ok: false, reason: 'This coupon has expired' };

    if (offer.restrictedTo && String(offer.restrictedTo) !== String(userId)) {
        return { ok: false, reason: 'Invalid or expired coupon' };
    }
    // A merchant's coupon only works on that merchant's products
    if (offer.createdBy === 'merchant' && offer.merchant && merchantId && String(offer.merchant) !== String(merchantId)) {
        return { ok: false, reason: "This coupon isn't valid for this store" };
    }

    if (offer.totalUsageLimit && offer.usedCount >= offer.totalUsageLimit) {
        return { ok: false, reason: 'Coupon usage limit reached' };
    }
    const usedByMe = (offer.usedBy || []).filter(u => String(u.user) === String(userId)).length;
    if (usedByMe >= (offer.usagePerUser || 1)) {
        return { ok: false, reason: 'You have already used this coupon' };
    }

    // Which items the offer applies to
    let eligible = itemsTotal;
    if (offer.applicableOn === 'products' && (offer.products || []).length) {
        const ids = new Set(offer.products.map(String));
        eligible = items.filter(i => ids.has(String(i.product))).reduce((s, i) => s + i.subtotal, 0);
    } else if (offer.applicableOn === 'categories' && (offer.categories || []).length) {
        const ids = new Set(offer.categories.map(String));
        eligible = items.filter(i => ids.has(String(i.category))).reduce((s, i) => s + i.subtotal, 0);
    }
    if (eligible <= 0) return { ok: false, reason: "This coupon doesn't apply to the items in your cart" };

    if (itemsTotal < (offer.minOrderValue || 0)) {
        return { ok: false, reason: `Minimum order value for this coupon is ₹${offer.minOrderValue}` };
    }

    let discount;
    if (offer.type === 'percentage' && offer.discountPercentage) {
        discount = (eligible * offer.discountPercentage) / 100;
        if (offer.maxDiscountCap) discount = Math.min(discount, offer.maxDiscountCap);
    } else if (offer.type === 'flat' && offer.discountAmount) {
        discount = Math.min(offer.discountAmount, eligible);
    } else if (offer.type === 'free_delivery') {
        discount = deliveryCharges;
    } else {
        // bogo / bundle offers are automatic promotions, not checkout coupons
        return { ok: false, reason: "This offer can't be used as a coupon code" };
    }
    return { ok: true, discount: round2(Math.max(0, discount)) };
}

/**
 * Atomically record one use of a coupon, but only while it is still active
 * and within its total and per-user limits. Two concurrent orders can't both
 * take the last use.
 * @returns {Date|null} the usedAt timestamp (needed to release it), or null
 */
async function reserveCouponUse(offerId, userId) {
    const usedAt = new Date();
    const uid = new mongoose.Types.ObjectId(String(userId));
    const updated = await Offer.findOneAndUpdate(
        {
            _id: offerId,
            status: 'active',
            $expr: {
                $and: [
                    { $or: [
                        { $lte: [{ $ifNull: ['$totalUsageLimit', 0] }, 0] },
                        { $lt: ['$usedCount', '$totalUsageLimit'] }
                    ] },
                    { $lt: [
                        { $size: { $filter: { input: { $ifNull: ['$usedBy', []] }, cond: { $eq: ['$$this.user', uid] } } } },
                        { $ifNull: ['$usagePerUser', 1] }
                    ] }
                ]
            }
        },
        { $inc: { usedCount: 1 }, $push: { usedBy: { user: uid, usedAt } } },
        { new: true }
    );
    return updated ? usedAt : null;
}

async function releaseCouponUse(offerId, userId, usedAt) {
    await Offer.findByIdAndUpdate(offerId, {
        $inc: { usedCount: -1 },
        $pull: { usedBy: { user: userId, ...(usedAt ? { usedAt } : {}) } }
    });
}

module.exports = { validateCoupon, reserveCouponUse, releaseCouponUse };
