/**
 * Price an order without writing anything. Shared by POST /api/orders (which
 * then reserves stock/coupon/wallet) and POST /api/orders/quote (which the app
 * shows at checkout), so the quoted total is exactly what gets charged.
 */
const mongoose = require('mongoose');
const Product = require('../models/Product');
const Merchant = require('../models/Merchant');
const Address = require('../models/Address');
const Offer = require('../models/Offer');
const { parseQuantity, MAX_QUANTITY_PER_ITEM } = require('../utils/stock');
const { unitPrice, round2 } = require('../utils/pricing');
const { validateCoupon } = require('../utils/coupon');
const { computeDelivery } = require('../utils/delivery');

const fail = (status, message, code) => ({ ok: false, status, message, code });

/**
 * @param {Object} p
 * @param {Object} p.user          the customer (User document)
 * @param {Array}  p.items         [{ product, quantity, preparation }]
 * @param {string} p.deliveryType  'pickup' | 'home-delivery'
 * @param {string} p.addressId     required for home delivery
 * @param {string} p.couponCode    optional
 */
async function priceOrder({ user, items, deliveryType, addressId, couponCode }) {
    if (!Array.isArray(items) || items.length === 0) {
        return fail(400, 'Order must have at least one item');
    }
    const type = deliveryType === 'pickup' ? 'pickup' : 'home-delivery';

    // ─── Items ────────────────────────────────────────────────────────────
    const orderItems = [];
    for (const item of items) {
        const quantity = parseQuantity(item.quantity);
        if (quantity === null) {
            return fail(400, `Invalid quantity for product ${item.product}: must be a number between 1 and ${MAX_QUANTITY_PER_ITEM}`);
        }
        if (!mongoose.Types.ObjectId.isValid(String(item.product))) {
            return fail(404, `Product ${item.product} not found`);
        }
        const product = await Product.findById(item.product);
        if (!product) return fail(404, `Product ${item.product} not found`);
        if (product.isActive === false || ['discontinued', 'coming-soon'].includes(product.status)) {
            return fail(400, `${product.name} is not available`);
        }
        if (product.stock < quantity) return fail(400, `Insufficient stock for ${product.name}`);

        const { unitPrice: price, preparation } = unitPrice(product, item.preparation);
        orderItems.push({
            product: product._id,
            merchant: product.merchant,
            category: product.category,
            name: product.name,
            price,
            quantity,
            unit: product.unit,
            preparation,
            subtotal: round2(price * quantity)
        });
    }

    // ─── One merchant per order (Issue 11) ────────────────────────────────
    const merchantIds = [...new Set(orderItems.map(i => String(i.merchant)))];
    if (merchantIds.length > 1) {
        return fail(400, 'An order can only contain products from one store. Please place separate orders.', 'MULTIPLE_MERCHANTS');
    }
    const merchant = await Merchant.findById(merchantIds[0]);
    if (!merchant || merchant.verificationStatus !== 'approved') return fail(400, 'This store is not available');
    if (merchant.isStoreOpen === false) {
        return fail(400, 'This store is currently closed and not accepting orders', 'STORE_CLOSED');
    }

    const itemsTotal = round2(orderItems.reduce((sum, i) => sum + i.subtotal, 0));

    // ─── Delivery (Issue 14) ──────────────────────────────────────────────
    let address = null;
    if (type === 'home-delivery') {
        if (!addressId || !mongoose.Types.ObjectId.isValid(String(addressId))) {
            return fail(400, 'Please choose a delivery address', 'ADDRESS_REQUIRED');
        }
        // The address must belong to this customer
        address = await Address.findOne({ _id: addressId, user: user._id });
        if (!address) return fail(400, 'Delivery address not found', 'ADDRESS_REQUIRED');
    }
    const delivery = computeDelivery({ deliveryType: type, merchant, address, itemsTotal, user });
    if (!delivery.ok) return fail(400, delivery.reason, delivery.code);
    const deliveryCharges = delivery.charge;

    // ─── Coupon (Issue 13) ────────────────────────────────────────────────
    let discount = 0;
    let offer = null;
    let couponError = null;
    if (couponCode && typeof couponCode === 'string') {
        offer = await Offer.findOne({ couponCode: couponCode.toUpperCase().trim() });
        const result = validateCoupon(offer, {
            userId: user._id,
            merchantId: merchant._id,
            items: orderItems,
            itemsTotal,
            deliveryCharges
        });
        if (result.ok) {
            discount = result.discount;
        } else {
            couponError = result.reason;
            offer = null;
        }
    }

    const totalAmount = Math.max(0, round2(itemsTotal + deliveryCharges - discount));

    return {
        ok: true,
        orderItems,
        merchant,
        merchantId: merchant._id,
        deliveryType: type,
        address,
        delivery,
        itemsTotal,
        deliveryCharges,
        discount,
        totalAmount,
        offer,
        couponCode: offer ? offer.couponCode : null,
        couponError
    };
}

module.exports = { priceOrder };
