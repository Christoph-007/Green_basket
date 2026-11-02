const Wishlist = require('../models/Wishlist');
const Product = require('../models/Product');
const Cart = require('../models/Cart');

exports.getWishlist = async (req, res) => {
    try {
        let wishlist = await Wishlist.findOne({ user: req.user._id })
            .populate({
                path: 'items.product',
                select: 'name price primaryImage stock isActive merchant averageRating'
            });

        if (!wishlist) {
            wishlist = await Wishlist.create({
                user: req.user._id,
                items: []
            });
        }

        // Calculate price changes
        const itemsWithChanges = wishlist.items.map(item => {
            const priceDropped = item.product.price < item.priceWhenAdded;
            const priceDifference = item.product.price - item.priceWhenAdded;
            const inStock = item.product.stock > 0;

            return {
                _id: item._id,
                product: item.product,
                addedAt: item.addedAt,
                priceWhenAdded: item.priceWhenAdded,
                priceDropped,
                priceDifference,
                inStock,
                notifyOnStock: item.notifyOnStock,
                notifyOnPriceDrop: item.notifyOnPriceDrop,
                notes: item.notes
            };
        });

        res.json({
            success: true,
            data: {
                items: itemsWithChanges,
                totalItems: wishlist.items.length
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch wishlist',
            details: error.message
        });
    }
};

exports.addToWishlist = async (req, res) => {
    try {
        const { productId, notifyOnStock, notifyOnPriceDrop, notes } = req.body;

        if (!productId) {
            return res.status(400).json({
                success: false,
                error: 'Product ID is required'
            });
        }

        const product = await Product.findById(productId);

        if (!product) {
            return res.status(404).json({
                success: false,
                error: 'Product not found'
            });
        }

        let wishlist = await Wishlist.findOne({ user: req.user._id });

        if (!wishlist) {
            wishlist = await Wishlist.create({
                user: req.user._id,
                items: []
            });
        }

        // Check if already in wishlist
        const existingItem = wishlist.items.find(
            item => item.product.toString() === productId
        );

        if (existingItem) {
            return res.status(400).json({
                success: false,
                error: 'Product already in wishlist'
            });
        }

        wishlist.items.push({
            product: productId,
            priceWhenAdded: product.price,
            notifyOnStock: notifyOnStock !== undefined ? notifyOnStock : true,
            notifyOnPriceDrop: notifyOnPriceDrop !== undefined ? notifyOnPriceDrop : true,
            notes
        });

        await wishlist.save();

        await wishlist.populate('items.product', 'name price primaryImage');

        const addedItem = wishlist.items[wishlist.items.length - 1];

        res.status(201).json({
            success: true,
            message: 'Product added to wishlist',
            data: {
                itemId: addedItem._id,
                product: addedItem.product
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to add to wishlist',
            details: error.message
        });
    }
};

exports.removeFromWishlist = async (req, res) => {
    try {
        const { productId } = req.params;

        const wishlist = await Wishlist.findOne({ user: req.user._id });

        if (!wishlist) {
            return res.status(404).json({
                success: false,
                error: 'Wishlist not found'
            });
        }

        const initialLength = wishlist.items.length;
        wishlist.items = wishlist.items.filter(
            item => item.product.toString() !== productId
        );

        if (wishlist.items.length === initialLength) {
            return res.status(404).json({
                success: false,
                error: 'Product not in wishlist'
            });
        }

        await wishlist.save();

        res.json({
            success: true,
            message: 'Product removed from wishlist'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to remove from wishlist',
            details: error.message
        });
    }
};

exports.moveToCart = async (req, res) => {
    try {
        const { productId } = req.params;
        const { quantity, preparationType } = req.body;

        const product = await Product.findById(productId);

        if (!product) {
            return res.status(404).json({
                success: false,
                error: 'Product not found'
            });
        }

        if (product.stock < (quantity || 1)) {
            return res.status(400).json({
                success: false,
                error: 'Insufficient stock'
            });
        }

        // Add to cart
        let cart = await Cart.findOne({ user: req.user._id });

        if (!cart) {
            cart = await Cart.create({
                user: req.user._id,
                items: [],
                total: 0
            });
        }

        // Check merchant consistency
        if (cart.items.length > 0) {
            const firstItem = await Product.findById(cart.items[0].product);
            if (firstItem.merchant.toString() !== product.merchant.toString()) {
                return res.status(400).json({
                    success: false,
                    error: 'Cannot add products from different merchants'
                });
            }
        }

        // Check if already in cart
        const existingItem = cart.items.find(
            item => item.product.toString() === productId &&
                item.preparationType === (preparationType || 'whole')
        );

        if (existingItem) {
            existingItem.quantity += (quantity || 1);
        } else {
            cart.items.push({
                product: productId,
                quantity: quantity || 1,
                preparationType: preparationType || 'whole',
                price: product.price
            });
        }

        // Calculate total
        await cart.populate('items.product');
        cart.total = cart.items.reduce((sum, item) => {
            return sum + (item.product.price * item.quantity);
        }, 0);

        await cart.save();

        // Remove from wishlist
        const wishlist = await Wishlist.findOne({ user: req.user._id });
        if (wishlist) {
            wishlist.items = wishlist.items.filter(
                item => item.product.toString() !== productId
            );
            await wishlist.save();
        }

        res.json({
            success: true,
            message: 'Product moved to cart',
            data: {
                cart: {
                    items: cart.items,
                    total: cart.total
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to move to cart',
            details: error.message
        });
    }
};

exports.checkWishlisted = async (req, res) => {
    try {
        const { productId } = req.params;

        const wishlist = await Wishlist.findOne({ user: req.user._id });

        if (!wishlist) {
            return res.json({
                success: true,
                data: {
                    isWishlisted: false
                }
            });
        }

        const item = wishlist.items.find(
            i => i.product.toString() === productId
        );

        res.json({
            success: true,
            data: {
                isWishlisted: !!item,
                itemId: item?._id
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to check wishlist status',
            details: error.message
        });
    }
};
