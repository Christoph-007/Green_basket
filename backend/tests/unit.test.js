const recipeCalculator = require('../src/services/recipeCalculator');
const mongoose = require('mongoose');

// Mock Data
const mockIngredients = [
    { name: 'Carrot', quantity: 0.5, unit: 'kg' },
    { name: 'Spices', quantity: 2, unit: 'tsp' },
    { name: 'Water', quantity: 500, unit: 'ml' }
];

const mockRecipes = [
    {
        name: 'Soup',
        ingredients: [
            { name: 'Carrot', quantity: 100, unit: 'g' },
            { name: 'Water', quantity: 500, unit: 'ml' }
        ]
    },
    {
        name: 'Salad',
        ingredients: [
            { name: 'Carrot', quantity: 900, unit: 'g' },
            { name: 'Tomato', quantity: 2, unit: 'piece' }
        ]
    }
];

describe('Unit Tests: Services & Logic', () => {

    describe('File: src/services/recipeCalculator.js', () => {

        it('should scale ingredients correctly (Up)', () => {
            // Original: 4 servings, Target: 8 servings (2x)
            const scaled = recipeCalculator.scaleIngredients(mockIngredients, 4, 8);

            expect(scaled[0].scaledQuantity).toBe(1); // 0.5 * 2 = 1
            expect(scaled[1].scaledQuantity).toBe(4); // 2 * 2 = 4
            expect(scaled[2].scaledQuantity).toBe(1000); // 500 * 2 = 1000
        });

        it('should scale ingredients correctly (Down)', () => {
            // Original: 4 servings, Target: 2 servings (0.5x)
            const scaled = recipeCalculator.scaleIngredients(mockIngredients, 4, 2);

            expect(scaled[0].scaledQuantity).toBe(0.25); // 0.5 * 0.5
            expect(scaled[1].scaledQuantity).toBe(1);    // 2 * 0.5
        });

        it('should normalize units correctly', () => {
            const res1 = recipeCalculator.normalizeUnit(1500, 'g');
            expect(res1).toEqual({ quantity: 1.5, unit: 'kg' });

            const res2 = recipeCalculator.normalizeUnit(500, 'g');
            expect(res2).toEqual({ quantity: 500, unit: 'g' }); // No change
        });

        it('should generate a combined shopping list', () => {
            const list = recipeCalculator.generateShoppingList(mockRecipes);

            // Should combine Carrots: 100g + 900g = 1000g -> normalize to 1kg
            const carrot = list.find(i => i.name === 'Carrot');
            expect(carrot).toBeDefined();
            expect(carrot.quantity).toBe(1);
            expect(carrot.unit).toBe('kg');

            // Water: 500ml
            const water = list.find(i => i.name === 'Water');
            expect(water.quantity).toBe(500);

            // Tomato: 2 pieces
            const tomato = list.find(i => i.name === 'Tomato');
            expect(tomato.quantity).toBe(2);
        });
    });

});
