/**
 * Convert a recipe ingredient amount into a purchasable quantity of a product.
 *
 * Recipes use cooking units (g, kg, ml, liter, piece, tbsp, cup, ...);
 * products are sold per their own unit (kg, g, piece, liter, dozen, bundle...).
 * Products are priced per unit and the cart needs whole quantities >= 1, so
 * the result is rounded UP to whole units (200 g of onion → 1 kg pack).
 */

// Factors to a common base: grams for mass, millilitres for volume
const MASS = { g: 1, gram: 1, grams: 1, kg: 1000 };
const VOLUME = { ml: 1, tsp: 5, tbsp: 15, cup: 240, liter: 1000, litre: 1000, l: 1000 };
const COUNT = { piece: 1, pieces: 1, pc: 1, dozen: 12 };

function convert(quantity, from, to) {
    for (const table of [MASS, VOLUME, COUNT]) {
        if (from in table && to in table) return (quantity * table[from]) / table[to];
    }
    return null; // incompatible (e.g. tbsp → kg)
}

function recipeQuantityToProductQuantity(quantity, recipeUnit, productUnit) {
    const from = String(recipeUnit || '').toLowerCase().trim();
    const to = String(productUnit || '').toLowerCase().trim();
    const q = Number(quantity);
    if (!Number.isFinite(q) || q <= 0) return 1;

    const converted = from === to ? q : convert(q, from, to);
    // Spoons, pinches, "to taste", bundles of different sizes: buy one unit
    if (converted === null) return 1;
    return Math.max(1, Math.ceil(converted - 1e-9));
}

module.exports = { recipeQuantityToProductQuantity };
