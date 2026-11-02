class RecipeCalculator {
    /**
     * Scale recipe ingredients based on servings
     * @param {Array} ingredients - Original recipe ingredients
     * @param {Number} originalServings - Original serving size
     * @param {Number} targetServings - Target serving size
     * @returns {Array} Scaled ingredients
     */
    scaleIngredients(ingredients, originalServings, targetServings) {
        const scaleFactor = targetServings / originalServings;

        return ingredients.map(ingredient => {
            const scaledQuantity = this.roundQuantity(
                ingredient.quantity * scaleFactor,
                ingredient.unit
            );

            return {
                ...ingredient.toObject ? ingredient.toObject() : ingredient,
                originalQuantity: ingredient.quantity,
                scaledQuantity,
                scaleFactor
            };
        });
    }

    /**
     * Round quantities appropriately based on unit
     */
    roundQuantity(quantity, unit) {
        const roundingRules = {
            'kg': 2,      // 2 decimal places
            'g': 0,       // Whole numbers
            'piece': 0,   // Whole numbers
            'cup': 2,
            'tbsp': 1,
            'tsp': 1,
            'liter': 2,
            'ml': 0,
            'pinch': 0,
            'to-taste': 0
        };

        const decimals = roundingRules[unit] || 2;
        return parseFloat(quantity.toFixed(decimals));
    }

    /**
     * Convert units if needed (e.g., 1000g to 1kg)
     */
    normalizeUnit(quantity, unit) {
        if (unit === 'g' && quantity >= 1000) {
            return {
                quantity: quantity / 1000,
                unit: 'kg'
            };
        }
        if (unit === 'ml' && quantity >= 1000) {
            return {
                quantity: quantity / 1000,
                unit: 'liter'
            };
        }
        return { quantity, unit };
    }

    /**
     * Generate shopping list from multiple recipes
     */
    generateShoppingList(recipes) {
        const ingredientMap = new Map();

        recipes.forEach(recipe => {
            recipe.ingredients.forEach(ingredient => {
                const key = `${ingredient.name}_${ingredient.unit}`;

                if (ingredientMap.has(key)) {
                    const existing = ingredientMap.get(key);
                    existing.quantity += ingredient.scaledQuantity || ingredient.quantity;
                } else {
                    ingredientMap.set(key, {
                        name: ingredient.name,
                        quantity: ingredient.scaledQuantity || ingredient.quantity,
                        unit: ingredient.unit,
                        product: ingredient.product
                    });
                }
            });
        });

        return Array.from(ingredientMap.values()).map(item => {
            const normalized = this.normalizeUnit(item.quantity, item.unit);
            return {
                ...item,
                quantity: normalized.quantity,
                unit: normalized.unit
            };
        });
    }
}

module.exports = new RecipeCalculator();
