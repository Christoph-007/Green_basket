const express = require('express');
const router = express.Router();
const returnController = require('../controllers/returnController');
const { protect, restrictTo, isAdmin } = require('../middlewares/authMiddleware');

router.use(protect);

// User routes
router.post('/', restrictTo('user'), returnController.requestReturn);
router.get('/my-returns', restrictTo('user'), returnController.getMyReturns);
router.get('/:id', returnController.getReturnById);
router.delete('/:id', restrictTo('user'), returnController.cancelReturn);

// Admin routes
router.get('/admin/all', isAdmin, returnController.getAllReturns);
router.put('/admin/:id/process', isAdmin, returnController.processReturn);

module.exports = router;
