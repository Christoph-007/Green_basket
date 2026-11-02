const express = require('express');
const router = express.Router();
const searchController = require('../controllers/searchController');

// All search routes are public
router.get('/products', searchController.advancedSearch);
router.get('/suggestions', searchController.getSearchSuggestions);
router.get('/trending', searchController.getTrendingProducts);

module.exports = router;
