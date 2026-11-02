const Cart = require('../models/Cart');
const { parseQuantity, MAX_QUANTITY_PER_ITEM } = require('../utils/stock');
const { recipeQuantityToProductQuantity } = require('../utils/units');
const { unitPrice } = require('../utils/pricing');
const { validateCoupon } = require('../utils/coupon');

// A cart holds products from one merchant only (an order goes to one merchant).
// Returns that merchant's id, or null for an empty cart.
async function getCartMerchantId(cart) {
    if (!cart || !cart.items || cart.items.length === 0) return null;
    const ids = cart.items.map(i => (i.product && i.product._id) || i.product);
    const products = await Product.find({ _id: { $in: ids } }, 'merchant').lean();
    const first = products.find(p => p.merchant);
    return first ? String(first.merchant) : null;
}

const merchantIdOf = (product) => String((product.merchant && product.merchant._id) || product.merchant);
const Product = require('../models/Product');
const Recipe = require('../models/Recipe');
const Offer = require('../models/Offer');
const recipeCalculator = require('../services/recipeCalculator');

// Get Cart
exports.getCart = async (req, res) => {
    try {
        const userId = req.user.id;

        let cart = await Cart.findOne({ user: userId }).populate('items.product');

        if (!cart) {
            cart = await Cart.create({ user: userId, items: [], total: 0 });
        }

        // Calculate total
        await cart.calculateTotal();
        await cart.save();

        res.json({
            success: true,
            data: { cart }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching cart',
            error: error.message
        });
    }
};

// Add to Cart
exports.addToCart = async (req, res) => {
    try {
        const userId = req.user.id;
        const { productId, preparation } = req.body;
        const quantity = parseQuantity(req.body.quantity === undefined ? 1 : req.body.quantity);
        if (quantity === null) {
            return res.status(400).json({
                success: false,
                message: `Quantity must be a number between 1 and ${MAX_QUANTITY_PER_ITEM}`
            });
        }

        // Check if product exists and is available
        const product = await Product.findById(productId).populate('merchant', 'isStoreOpen');
        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        if (product.merchant && product.merchant.isStoreOpen === false) {
            return res.status(403).json({
                success: false,
                message: 'This store is currently closed and not accepting orders'
            });
        }

        if (product.stock < quantity) {
            return res.status(400).json({
                success: false,
                message: 'Insufficient stock'
            });
        }

        let cart = await Cart.findOne({ user: userId });

        const cartMerchant = await getCartMerchantId(cart);
        if (cartMerchant && cartMerchant !== merchantIdOf(product)) {
            return res.status(409).json({
                success: false,
                code: 'DIFFERENT_MERCHANT',
                message: 'Your cart has items from another store. Clear the cart to add this item.'
            });
        }

        // Price including the preparation option (same rule the order uses)
        const { unitPrice: finalPrice, preparation: prepName } = unitPrice(product, preparation);

        if (!cart) {
            cart = await Cart.create({
                user: userId,
                items: [{
                    product: productId,
                    quantity,
                    preparation: prepName,
                    price: finalPrice
                }]
            });
        } else {
            // Check if product with same preparation already in cart
            const existingItemIndex = cart.items.findIndex(
                item => item.product.toString() === productId &&
                    (item.preparation || 'whole') === prepName
            );

            if (existingItemIndex > -1) {
                // Update quantity and price
                cart.items[existingItemIndex].quantity += quantity;
                cart.items[existingItemIndex].price = finalPrice;
            } else {
                // Add new item
                cart.items.push({
                    product: productId,
                    quantity,
                    preparation: prepName,
                    price: finalPrice
                });
            }
        }

        await cart.calculateTotal();
        await cart.save();
        await cart.populate('items.product');

        res.json({
            success: true,
            message: 'Product added to cart',
            data: { cart }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error adding to cart',
            error: error.message
        });
    }
};

// Update Cart Item
exports.updateCartItem = async (req, res) => {
    try {
        const userId = req.user.id;
        const { productId } = req.params;
        const { preparation } = req.body;
        // 0 removes the item; otherwise the same rules as adding
        const removeItem = Number(req.body.quantity) === 0;
        const quantity = removeItem ? 0 : parseQuantity(req.body.quantity);
        if (quantity === null) {
            return res.status(400).json({
                success: false,
                message: `Quantity must be a number between 1 and ${MAX_QUANTITY_PER_ITEM} (or 0 to remove)`
            });
        }

        const cart = await Cart.findOne({ user: userId });

        if (!cart) {
            return res.status(404).json({
                success: false,
                message: 'Cart not found'
            });
        }

        const itemIndex = cart.items.findIndex(
            item => item.product.toString() === productId &&
                (item.preparation || 'whole') === (preparation || 'whole')
        );

        if (itemIndex === -1) {
            return res.status(404).json({
                success: false,
                message: 'Item not found in cart'
            });
        }

        if (removeItem) {
            cart.items.splice(itemIndex, 1);
        } else {
            const product = await Product.findById(productId);
            if (product && product.stock < quantity) {
                return res.status(400).json({ success: false, message: 'Insufficient stock' });
            }
            cart.items[itemIndex].quantity = quantity;
        }

        await cart.calculateTotal();
        await cart.save();
        await cart.populate('items.product');

        res.json({
            success: true,
            message: 'Cart updated',
            data: { cart }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating cart',
            error: error.message
        });
    }
};

// Remove from Cart
exports.removeFromCart = async (req, res) => {
    try {
        const userId = req.user.id;
        const { productId } = req.params;
        const { preparation } = req.query; // Use query param for preparation in DELETE

        const cart = await Cart.findOne({ user: userId });

        if (!cart) {
            return res.status(404).json({
                success: false,
                message: 'Cart not found'
            });
        }

        cart.items = cart.items.filter(
            item => !(item.product.toString() === productId &&
                (item.preparation || 'whole') === (preparation || 'whole'))
        );

        await cart.calculateTotal();
        await cart.save();
        await cart.populate('items.product');

        res.json({
            success: true,
            message: 'Item removed from cart',
            data: { cart }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error removing from cart',
            error: error.message
        });
    }
};

// Clear Cart
exports.clearCart = async (req, res) => {
    try {
        const userId = req.user.id;

        const cart = await Cart.findOneAndUpdate(
            { user: userId },
            { items: [], total: 0 },
            { new: true }
        );

        res.json({
            success: true,
            message: 'Cart cleared',
            data: { cart }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error clearing cart',
            error: error.message
        });
    }
};

// Add Recipe to Cart
exports.addRecipeToCart = async (req, res) => {
    try {
        const userId = req.user.id;
        const { recipeId, servings, lat, lng, radius } = req.body;
        const { haversineKm } = require('../utils/haversine');

        const recipe = await Recipe.findById(recipeId).populate('ingredients.product');

        if (!recipe) {
            return res.status(404).json({
                success: false,
                message: 'Recipe not found'
            });
        }

        // Scale ingredients
        const scaledIngredients = recipeCalculator.scaleIngredients(
            recipe.ingredients,
            recipe.servings,
            servings || recipe.servings
        );

        let cart = await Cart.findOne({ user: userId });
        if (!cart) {
            cart = await Cart.create({ user: userId, items: [] });
        }

        // Add ingredients to cart
        console.log(`Adding ingredients to cart for user ${userId}. Strategy: ${lat && lng && radius ? 'Distance-aware' : 'Stock-only'}`);
        
        let stats = {
            added: 0,
            skipped_stock: 0,
            skipped_distance: 0,
            skipped_no_product: 0
        };

        stats.skipped_other_store = 0;
        const candidates = [];

        for (let ingredient of scaledIngredients) {
            let product = ingredient.product;

            // Fallback: If no product linked, try to find one (matching recipeController.calculateIngredients)
            if (!product) {
                const escaped = String(ingredient.name).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                const found = await Product.findOne({
                    name: new RegExp(escaped, 'i'),
                    status: 'active',
                    isActive: { $ne: false },
                    stock: { $gt: 0 }
                });
                // (crashed with a TypeError when nothing was found)
                product = found ? await Product.findById(found._id).populate('merchant', 'location isStoreOpen') : null;
            }

            if (!product) {
                stats.skipped_no_product++;
                continue;
            }

            // Check if store is open
            if (product.merchant && product.merchant.isStoreOpen === false) {
                stats.skipped_no_product++;
                continue;
            }

            // Check distance if location provided
            if (lat && lng && radius && product.merchant && product.merchant.location) {
                const distance = haversineKm(
                    parseFloat(lat),
                    parseFloat(lng),
                    product.merchant.location.coordinates[1], // lat
                    product.merchant.location.coordinates[0]  // lng
                );
                if (distance > parseFloat(radius)) {
                    stats.skipped_distance++;
                    continue;
                }
            }

            // Recipe amounts are in cooking units (e.g. 200 g); the cart needs
            // whole units of the product's own unit (e.g. 1 kg)
            const buyQuantity = recipeQuantityToProductQuantity(ingredient.scaledQuantity, ingredient.unit, product.unit);

            if (product.stock < buyQuantity) {
                stats.skipped_stock++;
                continue;
            }
            candidates.push({ product, buyQuantity });
        }

        // One merchant per cart: keep the cart's store, or else the store that
        // has the most of this recipe's ingredients
        let targetMerchant = await getCartMerchantId(cart);
        if (!targetMerchant && candidates.length) {
            const counts = {};
            for (const c of candidates) counts[merchantIdOf(c.product)] = (counts[merchantIdOf(c.product)] || 0) + 1;
            targetMerchant = Object.keys(counts).sort((x, y) => counts[y] - counts[x])[0];
        }

        for (const { product, buyQuantity } of candidates) {
            if (merchantIdOf(product) !== targetMerchant) {
                stats.skipped_other_store++;
                continue;
            }
            const existingItemIndex = cart.items.findIndex(
                item => item.product.toString() === product._id.toString() && (item.preparation || 'whole') === 'whole'
            );
            if (existingItemIndex > -1) {
                cart.items[existingItemIndex].quantity += buyQuantity;
            } else {
                cart.items.push({
                    product: product._id,
                    quantity: buyQuantity,
                    preparation: 'whole',
                    price: unitPrice(product).unitPrice
                });
            }
            stats.added++;
        }

        console.log(`Cart Update Stats:`, stats);
        await cart.calculateTotal();
        await cart.save();
        await cart.populate('items.product');

        res.json({
            success: true,
            message: stats.added > 0
                ? `${stats.added} items added to cart` +
                  (stats.skipped_other_store ? ` (${stats.skipped_other_store} available only from another store)` : '')
                : (stats.skipped_other_store
                    ? 'These ingredients are only available from a different store than the items in your cart'
                    : 'No items could be added (out of stock or too far)'),
            data: {
                cart,
                stats
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error adding recipe to cart',
            error: error.message
        });
    }
};

// Apply Coupon
exports.applyCoupon = async (req, res) => {
    try {
        const userId = req.user.id;
        const { code } = req.body;

        if (!code) {
            return res.status(400).json({
                success: false,
                message: 'Coupon code is required'
            });
        }

        const cart = await Cart.findOne({ user: userId }).populate('items.product');
        if (!cart || cart.items.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Cart is empty'
            });
        }

        const items = cart.items.filter(i => i.product).map(i => {
            const price = unitPrice(i.product, i.preparation).unitPrice;
            return { product: i.product._id, category: i.product.category, subtotal: price * i.quantity };
        });
        const itemsTotal = items.reduce((sum, i) => sum + i.subtotal, 0);
        const first = cart.items.find(i => i.product && i.product.merchant);

        // Same validation the order uses (dates, limits, merchant, products)
        const offer = await Offer.findOne({ couponCode: String(code).toUpperCase().trim() });
        const result = validateCoupon(offer, {
            userId,
            merchantId: first ? first.product.merchant : undefined,
            items,
            itemsTotal
        });
        if (!result.ok) {
            return res.status(offer ? 400 : 404).json({ success: false, message: result.reason });
        }

        cart.appliedCoupon = {
            code: offer.couponCode,
            offerId: offer._id,
            discount: result.discount
        };

        await cart.calculateTotal();
        await cart.save();

        res.json({
            success: true,
            message: offer.type === 'free_delivery'
                ? 'Coupon applied: free delivery at checkout'
                : 'Coupon applied successfully',
            data: {
                discount: cart.discount,
                cart
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error applying coupon',
            error: error.message
        });
    }
};

// Remove Coupon
exports.removeCoupon = async (req, res) => {
    try {
        const userId = req.user.id;

        const cart = await Cart.findOne({ user: userId });
        if (!cart) {
            return res.status(404).json({
                success: false,
                message: 'Cart not found'
            });
        }

        cart.appliedCoupon = undefined;
        await cart.calculateTotal();
        await cart.save();

        res.json({
            success: true,
            message: 'Coupon removed successfully',
            data: { cart }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error removing coupon',
            error: error.message
        });
    }
};


