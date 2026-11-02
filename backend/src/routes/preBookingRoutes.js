const express = require('express');
const router = express.Router();
const preBookingController = require('../controllers/preBookingController');
const { protect, restrictTo, isAdmin } = require('../middlewares/authMiddleware');

// User routes
router.use(protect);

router.post('/', preBookingController.createPreBooking);
router.get('/my-prebookings', preBookingController.getMyPreBookings);
router.delete('/:id', preBookingController.cancelPreBooking);
router.post('/:id/convert-to-order', preBookingController.convertToOrder);

// Merchant routes
router.patch('/products/:id/mark-available',
    restrictTo('merchant'),
    preBookingController.markProductAvailable
);

router.patch('/:id/update-status',
    restrictTo('merchant'),
    preBookingController.updatePreBookingStatus
);

router.patch('/merchant/products/:productId/prebooking',
    restrictTo('merchant'),
    preBookingController.updatePreBookingSettings
);

router.get('/merchant/all',
    restrictTo('merchant'),
    preBookingController.getMerchantPreBookings
);

// Admin routes
router.get('/admin/all',
    isAdmin,
    preBookingController.getAllPreBookings
);

module.exports = router;
