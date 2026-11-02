const mongoose = require('mongoose');

const cartSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true
    },
    items: [{
        product: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Product',
            required: true
        },
        quantity: {
            type: Number,
            required: true,
            min: 1
        },
        preparation: {
            type: String
        },
        price: Number,
        addedAt: {
            type: Date,
            default: Date.now
        }
    }],

    // Applied Coupon/Offer
    appliedCoupon: {
        code: String,
        offerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Offer'
        },
        discount: {
            type: Number,
            default: 0
        }
    },

    // Pricing
    total: {
        type: Number,
        default: 0
    },
    discount: {
        type: Number,
        default: 0
    },
    deliveryCharge: {
        type: Number,
        default: 0
    },
    finalTotal: {
        type: Number,
        default: 0
    }
}, { timestamps: true });

// Calculate cart total
cartSchema.methods.calculateTotal = async function () {
    // Lazy requires: utils/coupon requires models, avoid a load-order cycle
    const { unitPrice } = require('../utils/pricing');
    const { validateCoupon } = require('../utils/coupon');
    const Offer = require('./Offer');

    await this.populate('items.product');

    // Always price from the current product (and preparation) so the cart
    // matches what the order will charge, even if the merchant changed prices
    let total = 0;
    this.items.forEach(item => {
        if (item.product && item.product.price !== undefined) {
            item.price = unitPrice(item.product, item.preparation).unitPrice;
        }
        total += (item.price || 0) * item.quantity;
    });

    this.total = Math.round(total * 100) / 100;
    // Delivery depends on the address and the merchant's zones; it is quoted
    // at checkout (POST /api/orders/quote), not guessed here
    this.deliveryCharge = 0;

    // Re-check the applied coupon against the current cart
    this.discount = 0;
    if (this.appliedCoupon && this.appliedCoupon.offerId) {
        const offer = await Offer.findById(this.appliedCoupon.offerId);
        const first = this.items.find(i => i.product && i.product.merchant);
        const result = validateCoupon(offer, {
            userId: this.user,
            merchantId: first ? first.product.merchant : undefined,
            items: this.items.map(i => ({
                product: i.product && i.product._id,
                category: i.product && i.product.category,
                subtotal: (i.price || 0) * i.quantity
            })),
            itemsTotal: this.total
        });
        if (result.ok) {
            this.appliedCoupon.discount = result.discount;
            this.discount = result.discount;
        } else {
            this.appliedCoupon = { code: null, offerId: null, discount: 0 };
        }
    }

    this.finalTotal = Math.max(0, this.total + this.deliveryCharge - this.discount);
    return this.total;
};


module.exports = mongoose.model('Cart', cartSchema);
