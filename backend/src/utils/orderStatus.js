/**
 * Order status rules shared by the API (and mirrored in the Flutter app).
 *
 *   pickup:        pending → confirmed → preparing → ready → completed
 *   home-delivery: pending → confirmed → preparing → ready → out-for-delivery → delivered → completed
 *
 * payment_pending (unpaid online order), cancelled, completed and refunded
 * cannot be changed by a merchant.
 */

const MERCHANT_TRANSITIONS = {
    pending: ['confirmed', 'cancelled'],
    confirmed: ['preparing', 'ready', 'cancelled'], // 'preparing' is optional
    preparing: ['ready', 'cancelled'],
    ready: ['out-for-delivery', 'delivered', 'completed', 'cancelled'],
    'out-for-delivery': ['delivered'],
    delivered: ['completed']
};

// Orders that count as fulfilled for revenue, payouts and analytics.
// Pickup orders go ready -> completed and never become 'delivered', and
// delivery orders end as 'completed' after 'delivered', so both must count.
const FULFILLED_STATUSES = ['delivered', 'completed'];

// Customers may cancel until the merchant starts preparing
const CUSTOMER_CANCELLABLE = ['payment_pending', 'pending', 'confirmed'];

// Admins may cancel anything not yet handed over / finished
const ADMIN_CANCELLABLE = ['payment_pending', 'pending', 'confirmed', 'preparing', 'ready', 'out-for-delivery'];

// Statuses from which a merchant may cancel
const MERCHANT_CANCELLABLE = Object.keys(MERCHANT_TRANSITIONS)
    .filter(s => MERCHANT_TRANSITIONS[s].includes('cancelled'));

/**
 * Can a merchant move an order from `from` to `to`?
 * Delivery-type rules: pickup orders never go out for delivery; delivery
 * orders must be delivered before they are completed.
 */
function canMerchantTransition(from, to, deliveryType = 'home-delivery') {
    const allowed = MERCHANT_TRANSITIONS[from] || [];
    if (!allowed.includes(to)) return false;
    const isPickup = deliveryType === 'pickup';
    if (isPickup && (to === 'out-for-delivery' || to === 'delivered')) return false;
    if (!isPickup && from === 'ready' && to === 'completed') return false;
    return true;
}

/** Next statuses a merchant may choose for this order (for UIs and errors). */
function allowedMerchantNextStatuses(order) {
    return (MERCHANT_TRANSITIONS[order.status] || [])
        .filter(to => canMerchantTransition(order.status, to, order.deliveryType));
}

module.exports = {
    FULFILLED_STATUSES,
    MERCHANT_TRANSITIONS,
    CUSTOMER_CANCELLABLE,
    ADMIN_CANCELLABLE,
    MERCHANT_CANCELLABLE,
    canMerchantTransition,
    allowedMerchantNextStatuses
};
