const express = require('express');
const router = express.Router();
const recipeController = require('../controllers/recipeController');
const { authenticate, isAdmin } = require('../middlewares/authMiddleware');

// Public routes
router.get('/', recipeController.getAllRecipes);
router.get('/search', recipeController.searchRecipes);
router.get('/by-product/:productId', recipeController.getRecipesByProduct);
router.get('/:id', recipeController.getRecipeById);
router.post('/:id/calculate-ingredients', recipeController.calculateIngredients);

// Admin routes
router.get('/admin/all', authenticate, isAdmin, recipeController.getAdminRecipes);
router.post('/', authenticate, isAdmin, recipeController.createRecipe);
router.put('/:id', authenticate, isAdmin, recipeController.updateRecipe);
router.patch('/:id', authenticate, isAdmin, recipeController.updateRecipe);
router.delete('/:id', authenticate, isAdmin, recipeController.deleteRecipe);

module.exports = router;
