const Recipe = require('../models/Recipe');
const Product = require('../models/Product');
const recipeCalculator = require('../services/recipeCalculator');

// Get All Recipes
exports.getAllRecipes = async (req, res) => {
    try {
        const { page = 1, limit = 12, category, cuisine, difficulty, search, lat, lng, radius } = req.query;

        const query = { status: 'published' };
        if (category) query.category = category;
        if (cuisine) query.cuisine = cuisine;
        if (difficulty) query.difficulty = difficulty;
        if (search) {
            query.$text = { $search: search };
        }

        const recipes = await Recipe.find(query)
            .populate({
                path: 'ingredients.product',
                populate: { path: 'merchant', select: 'location' }
            })
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit)
            .lean();

        const { haversineKm } = require('../utils/haversine');
        const recipesWithDistance = recipes.map(r => {
            let distance = null;
            if (lat && lng && r.ingredients && r.ingredients.length > 0) {
                const p = r.ingredients[0].product;
                if (p && p.merchant && p.merchant.location) {
                    distance = haversineKm(
                        parseFloat(lat),
                        parseFloat(lng),
                        p.merchant.location.coordinates[1],
                        p.merchant.location.coordinates[0]
                    );
                }
            }
            return {
                ...r,
                distance: distance ? Math.round(distance * 10) / 10 : null,
                isNearby: radius ? (distance <= parseFloat(radius)) : true
            };
        });

        const total = await Recipe.countDocuments(query);

        res.json({
            success: true,
            data: {
                recipes: recipesWithDistance,
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
            message: 'Error fetching recipes',
            error: error.message
        });
    }
};

// Get Recipes by Product ID
exports.getRecipesByProduct = async (req, res) => {
    try {
        const { productId } = req.params;

        const recipes = await Recipe.find({
            status: 'published',
            'ingredients.product': productId
        })
        .sort({ averageRating: -1, createdAt: -1 })
        .limit(10)
        .lean();

        res.json({
            success: true,
            data: { recipes }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching recipes by product',
            error: error.message
        });
    }
};

// Get All Recipes (Admin)
exports.getAdminRecipes = async (req, res) => {
    try {
        const { page = 1, limit = 12, category, cuisine, difficulty, search, status } = req.query;

        const query = {};
        if (category) query.category = category;
        if (cuisine) query.cuisine = cuisine;
        if (difficulty) query.difficulty = difficulty;
        if (status && status !== 'all') query.status = status;
        if (search) {
            query.$or = [
                { name: new RegExp(search, 'i') },
                { description: new RegExp(search, 'i') }
            ];
        }

        const recipes = await Recipe.find(query)
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit)
            .populate('createdBy.userId', 'name email');

        const total = await Recipe.countDocuments(query);

        res.json({
            success: true,
            data: {
                recipes,
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
            message: 'Error fetching admin recipes',
            error: error.message
        });
    }
};

// Get Recipe By ID
exports.getRecipeById = async (req, res) => {
    try {
        const { id } = req.params;

        const recipe = await Recipe.findById(id).populate('ingredients.product');

        if (!recipe) {
            return res.status(404).json({
                success: false,
                message: 'Recipe not found'
            });
        }

        res.json({
            success: true,
            data: { recipe }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching recipe',
            error: error.message
        });
    }
};

// Calculate Ingredients for Servings
exports.calculateIngredients = async (req, res) => {
    try {
        const { id } = req.params;
        const { servings, lat, lng, radius } = req.body;

        const recipe = await Recipe.findById(id).populate('ingredients.product');

        if (!recipe) {
            return res.status(404).json({
                success: false,
                message: 'Recipe not found'
            });
        }

        const targetServings = servings || recipe.servings;

        // Calculate scaled ingredients
        const scaledIngredients = recipeCalculator.scaleIngredients(
            recipe.ingredients,
            recipe.servings,
            targetServings
        );

        const { haversineKm } = require('../utils/haversine');

        // Find matching products for each ingredient and check location
        const ingredientsWithProducts = await Promise.all(
            scaledIngredients.map(async (ingredient) => {
                let product = ingredient.product;

                // If no product linked, try to find one
                if (!product) {
                    product = await Product.findOne({
                        name: new RegExp(ingredient.name, 'i'),
                        status: 'active',
                        isActive: { $ne: false }
                    })
                    .populate('merchant', 'address location')
                    .sort({ averageRating: -1 });
                } else if (product && (!product.merchant || !product.merchant.location)) {
                    // Refresh product with merchant location if needed
                    product = await Product.findById(product._id).populate('merchant', 'address location');
                }

                let isNearby = true;
                let distance = null;
                let rangeMessage = null;

                if (product && product.merchant && product.merchant.location && lat && lng && radius) {
                    distance = haversineKm(
                        parseFloat(lat),
                        parseFloat(lng),
                        product.merchant.location.coordinates[1], // lat
                        product.merchant.location.coordinates[0]  // lng
                    );
                    
                    if (distance > parseFloat(radius)) {
                        isNearby = false;
                        rangeMessage = `Outside range (${distance.toFixed(1)}km)`;
                    }
                }

                return {
                    name: ingredient.name,
                    quantity: ingredient.scaledQuantity,
                    unit: ingredient.unit,
                    product: product ? {
                        id: product._id,
                        name: product.name,
                        price: product.price,
                        image: product.primaryImage,
                        merchant: product.merchant,
                        stock: product.stock,
                        distance: distance ? Math.round(distance * 10) / 10 : null
                    } : null,
                    isAvailable: product && product.stock > 0 && isNearby,
                    isNearby,
                    rangeMessage
                };
            })
        );

        // Calculate total price
        const totalPrice = ingredientsWithProducts.reduce((sum, item) => {
            if (item.product && item.isAvailable) {
                return sum + (item.product.price * item.quantity);
            }
            return sum;
        }, 0);

        res.json({
            success: true,
            data: {
                recipe: {
                    id: recipe._id,
                    name: recipe.name,
                    servings: targetServings,
                    originalServings: recipe.servings
                },
                ingredients: ingredientsWithProducts,
                totalPrice,
                availableItemsCount: ingredientsWithProducts.filter(i => i.isAvailable).length,
                totalItemsCount: ingredientsWithProducts.length
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error calculating ingredients',
            error: error.message
        });
    }
};

// Search Recipes
exports.searchRecipes = async (req, res) => {
    try {
        const { q, category, cuisine } = req.query;

        const query = { status: 'published' };

        if (q) {
            query.$or = [
                { name: new RegExp(q, 'i') },
                { description: new RegExp(q, 'i') },
                { tags: new RegExp(q, 'i') }
            ];
        }

        if (category) query.category = category;
        if (cuisine) query.cuisine = cuisine;

        const recipes = await Recipe.find(query).limit(20);

        res.json({
            success: true,
            data: { recipes }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error searching recipes',
            error: error.message
        });
    }
};

// Create Recipe (Admin)
exports.createRecipe = async (req, res) => {
    try {
        const recipeData = req.body;

        const recipe = await Recipe.create({
            ...recipeData,
            createdBy: {
                userType: 'admin',
                userId: req.user.id
            }
        });

        res.status(201).json({
            success: true,
            message: 'Recipe created successfully',
            data: { recipe }
        });
    } catch (error) {
        console.error("CREATE RECIPE ERROR:", error);
        res.status(500).json({
            success: false,
            message: 'Error creating recipe',
            error: error.message,
            stack: error.stack
        });
    }
};

// Update Recipe (Admin)
exports.updateRecipe = async (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body;

        const recipe = await Recipe.findByIdAndUpdate(id, updates, { new: true });

        if (!recipe) {
            return res.status(404).json({
                success: false,
                message: 'Recipe not found'
            });
        }

        res.json({
            success: true,
            message: 'Recipe updated successfully',
            data: { recipe }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating recipe',
            error: error.message
        });
    }
};

// Delete Recipe (Admin)
exports.deleteRecipe = async (req, res) => {
    try {
        const { id } = req.params;

        const recipe = await Recipe.findByIdAndDelete(id);

        if (!recipe) {
            return res.status(404).json({
                success: false,
                message: 'Recipe not found'
            });
        }

        res.json({
            success: true,
            message: 'Recipe deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error deleting recipe',
            error: error.message
        });
    }
};
