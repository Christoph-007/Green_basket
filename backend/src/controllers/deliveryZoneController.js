const Merchant = require('../models/Merchant');

/**
 * Calculate distance between two coordinates using Haversine formula
 * @param {Number} lat1 - Latitude of point 1
 * @param {Number} lon1 - Longitude of point 1
 * @param {Number} lat2 - Latitude of point 2
 * @param {Number} lon2 - Longitude of point 2
 * @returns {Number} - Distance in kilometers
 */
const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
};

/**
 * @desc    Set merchant location
 * @route   PUT /api/merchants/location
 * @access  Private (Merchant)
 */
exports.setMerchantLocation = async (req, res) => {
    try {
        const { latitude, longitude, address } = req.body;

        if (latitude === undefined || longitude === undefined) {
            return res.status(400).json({
                success: false,
                error: 'latitude and longitude are required'
            });
        }

        // Validate coordinates
        if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
            return res.status(400).json({
                success: false,
                error: 'Invalid coordinates'
            });
        }

        const merchant = await Merchant.findById(req.user._id);

        if (!merchant) {
            return res.status(404).json({
                success: false,
                error: 'Merchant not found'
            });
        }

        merchant.location = {
            type: 'Point',
            coordinates: [longitude, latitude]
        };

        if (address) {
            merchant.address = address;
        }

        await merchant.save();

        res.json({
            success: true,
            message: 'Merchant location updated successfully',
            data: {
                location: merchant.location,
                address: merchant.address
            }
        });
    } catch (error) {
        console.error('Set merchant location error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update merchant location',
            details: error.message
        });
    }
};

/**
 * @desc    Add delivery zone
 * @route   POST /api/merchants/delivery-zones
 * @access  Private (Merchant)
 */
exports.addDeliveryZone = async (req, res) => {
    try {
        const {
            name, radiusKm, deliveryCharge,
            minimumOrder, freeDeliveryAbove, estimatedDeliveryTime
        } = req.body;

        if (!radiusKm || deliveryCharge === undefined) {
            return res.status(400).json({
                success: false,
                error: 'radiusKm and deliveryCharge are required'
            });
        }

        if (radiusKm <= 0 || radiusKm > 100) {
            return res.status(400).json({
                success: false,
                error: 'radiusKm must be between 0.1 and 100 km'
            });
        }

        const merchant = await Merchant.findById(req.user._id);

        if (!merchant) {
            return res.status(404).json({
                success: false,
                error: 'Merchant not found'
            });
        }

        if (!merchant.location || !merchant.location.coordinates || merchant.location.coordinates.length !== 2) {
            return res.status(400).json({
                success: false,
                error: 'Merchant location must be set before adding delivery zones'
            });
        }

        if (!merchant.deliveryZones) {
            merchant.deliveryZones = [];
        }

        merchant.deliveryZones.push({
            name: name || `Zone ${merchant.deliveryZones.length + 1}`,
            radiusKm,
            deliveryCharge,
            minimumOrder: minimumOrder || 0,
            freeDeliveryAbove,
            estimatedDeliveryTime: estimatedDeliveryTime || '30-45 mins',
            isActive: true
        });

        await merchant.save();

        const newZone = merchant.deliveryZones[merchant.deliveryZones.length - 1];

        res.status(201).json({
            success: true,
            message: 'Delivery zone added successfully',
            data: {
                zone: newZone
            }
        });
    } catch (error) {
        console.error('Add delivery zone error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to add delivery zone',
            details: error.message
        });
    }
};

/**
 * @desc    Get all delivery zones
 * @route   GET /api/merchants/delivery-zones
 * @access  Private (Merchant)
 */
exports.getDeliveryZones = async (req, res) => {
    try {
        const merchant = await Merchant.findById(req.user._id)
            .select('deliveryZones location');

        if (!merchant) {
            return res.status(404).json({
                success: false,
                error: 'Merchant not found'
            });
        }

        res.json({
            success: true,
            data: {
                zones: merchant.deliveryZones || [],
                merchantLocation: merchant.location
            }
        });
    } catch (error) {
        console.error('Get delivery zones error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch delivery zones',
            details: error.message
        });
    }
};

/**
 * @desc    Update delivery zone
 * @route   PUT /api/merchants/delivery-zones/:zoneId
 * @access  Private (Merchant)
 */
exports.updateDeliveryZone = async (req, res) => {
    try {
        const { zoneId } = req.params;
        const updates = req.body;

        const merchant = await Merchant.findById(req.user._id);

        if (!merchant) {
            return res.status(404).json({
                success: false,
                error: 'Merchant not found'
            });
        }

        const zone = merchant.deliveryZones.id(zoneId);

        if (!zone) {
            return res.status(404).json({
                success: false,
                error: 'Delivery zone not found'
            });
        }

        const allowedUpdates = [
            'name', 'radiusKm', 'deliveryCharge',
            'minimumOrder', 'freeDeliveryAbove',
            'estimatedDeliveryTime', 'isActive'
        ];

        allowedUpdates.forEach(field => {
            if (updates[field] !== undefined) {
                zone[field] = updates[field];
            }
        });

        await merchant.save();

        res.json({
            success: true,
            message: 'Delivery zone updated successfully',
            data: {
                zone
            }
        });
    } catch (error) {
        console.error('Update delivery zone error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update delivery zone',
            details: error.message
        });
    }
};

/**
 * @desc    Delete delivery zone
 * @route   DELETE /api/merchants/delivery-zones/:zoneId
 * @access  Private (Merchant)
 */
exports.deleteDeliveryZone = async (req, res) => {
    try {
        const { zoneId } = req.params;

        const merchant = await Merchant.findById(req.user._id);

        if (!merchant) {
            return res.status(404).json({
                success: false,
                error: 'Merchant not found'
            });
        }

        const zone = merchant.deliveryZones.id(zoneId);

        if (!zone) {
            return res.status(404).json({
                success: false,
                error: 'Delivery zone not found'
            });
        }

        zone.deleteOne();
        await merchant.save();

        res.json({
            success: true,
            message: 'Delivery zone deleted successfully'
        });
    } catch (error) {
        console.error('Delete delivery zone error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete delivery zone',
            details: error.message
        });
    }
};

/**
 * @desc    Check delivery availability
 * @route   POST /api/merchants/check-delivery
 * @access  Public
 */
exports.checkDeliveryAvailability = async (req, res) => {
    try {
        const { merchantId, latitude, longitude } = req.body;

        if (!merchantId || latitude === undefined || longitude === undefined) {
            return res.status(400).json({
                success: false,
                error: 'merchantId, latitude, and longitude are required'
            });
        }

        const merchant = await Merchant.findById(merchantId)
            .select('deliveryZones location businessName');

        if (!merchant) {
            return res.status(404).json({
                success: false,
                error: 'Merchant not found'
            });
        }

        if (!merchant.location || !merchant.location.coordinates || merchant.location.coordinates.length !== 2) {
            return res.json({
                success: true,
                data: {
                    canDeliver: false,
                    reason: 'Merchant has not set delivery location'
                }
            });
        }

        const [merchantLon, merchantLat] = merchant.location.coordinates;
        const distanceKm = calculateDistance(
            latitude, longitude,
            merchantLat, merchantLon
        );

        // Find matching zone (smallest radius that covers the distance)
        const activeZones = merchant.deliveryZones
            ?.filter(z => z.isActive)
            .sort((a, b) => a.radiusKm - b.radiusKm) || [];

        const matchingZone = activeZones.find(z => z.radiusKm >= distanceKm);

        if (!matchingZone) {
            return res.json({
                success: true,
                data: {
                    canDeliver: false,
                    distanceKm: Math.round(distanceKm * 10) / 10,
                    reason: 'Location outside delivery range'
                }
            });
        }

        res.json({
            success: true,
            data: {
                canDeliver: true,
                zone: {
                    name: matchingZone.name,
                    deliveryCharge: matchingZone.deliveryCharge,
                    minimumOrder: matchingZone.minimumOrder,
                    freeDeliveryAbove: matchingZone.freeDeliveryAbove,
                    estimatedDeliveryTime: matchingZone.estimatedDeliveryTime
                },
                distanceKm: Math.round(distanceKm * 10) / 10
            }
        });
    } catch (error) {
        console.error('Check delivery availability error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to check delivery availability',
            details: error.message
        });
    }
};

/**
 * @desc    Get nearby merchants
 * @route   POST /api/merchants/nearby
 * @access  Public
 */
exports.getNearbyMerchants = async (req, res) => {
    try {
        const { latitude, longitude, maxDistanceKm = 10 } = req.body;

        if (latitude === undefined || longitude === undefined) {
            return res.status(400).json({
                success: false,
                error: 'latitude and longitude are required'
            });
        }

        // Use MongoDB $near for geospatial query
        const merchants = await Merchant.find({
            verificationStatus: 'approved',
            isActive: true,
            location: {
                $near: {
                    $geometry: {
                        type: 'Point',
                        coordinates: [longitude, latitude]
                    },
                    $maxDistance: maxDistanceKm * 1000 // Convert to meters
                }
            }
        })
            .select('businessName profileImage averageRating isStoreOpen location deliveryZones')
            .limit(20);

        const merchantsWithDistance = merchants.map(merchant => {
            const [merchantLon, merchantLat] = merchant.location.coordinates;
            const distanceKm = calculateDistance(
                latitude, longitude,
                merchantLat, merchantLon
            );

            // Find applicable zone
            const activeZones = merchant.deliveryZones
                ?.filter(z => z.isActive)
                .sort((a, b) => a.radiusKm - b.radiusKm) || [];

            const matchingZone = activeZones.find(z => z.radiusKm >= distanceKm);

            return {
                merchant: {
                    _id: merchant._id,
                    businessName: merchant.businessName,
                    profileImage: merchant.profileImage,
                    averageRating: merchant.averageRating,
                    isOpen: merchant.isStoreOpen
                },
                distanceKm: Math.round(distanceKm * 10) / 10,
                canDeliver: !!matchingZone,
                deliveryCharge: matchingZone?.deliveryCharge,
                minimumOrder: matchingZone?.minimumOrder,
                estimatedDeliveryTime: matchingZone?.estimatedDeliveryTime
            };
        });

        // Sort by distance
        merchantsWithDistance.sort((a, b) => a.distanceKm - b.distanceKm);

        res.json({
            success: true,
            data: {
                merchants: merchantsWithDistance,
                total: merchantsWithDistance.length
            }
        });
    } catch (error) {
        console.error('Get nearby merchants error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch nearby merchants',
            details: error.message
        });
    }
};
