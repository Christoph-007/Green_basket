const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/merchantAnalyticsController');
const { protect, restrictTo } = require('../middlewares/authMiddleware');

// All routes require merchant authentication
router.use(protect);
router.use(restrictTo('merchant'));

router.get('/sales', analyticsController.getSalesAnalytics);
router.get('/products', analyticsController.getProductAnalytics);
router.get('/customers', analyticsController.getCustomerAnalytics);
router.get('/inventory', analyticsController.getInventoryAnalytics);
router.get('/forecast', analyticsController.getRevenueForecast);
router.get('/reviews', analyticsController.getReviewAnalytics);

module.exports = router;
