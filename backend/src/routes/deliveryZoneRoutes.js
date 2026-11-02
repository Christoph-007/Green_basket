const express = require('express');
const router = express.Router();
const deliveryZoneController = require('../controllers/deliveryZoneController');
const { protect, restrictTo } = require('../middlewares/authMiddleware');

// Public routes
router.post('/check-delivery', deliveryZoneController.checkDeliveryAvailability);
router.post('/nearby', deliveryZoneController.getNearbyMerchants);

// Merchant routes
router.use(protect);
router.use(restrictTo('merchant'));

router.put('/location', deliveryZoneController.setMerchantLocation);
router.get('/delivery-zones', deliveryZoneController.getDeliveryZones);
router.post('/delivery-zones', deliveryZoneController.addDeliveryZone);
router.put('/delivery-zones/:zoneId', deliveryZoneController.updateDeliveryZone);
router.delete('/delivery-zones/:zoneId', deliveryZoneController.deleteDeliveryZone);

module.exports = router;
