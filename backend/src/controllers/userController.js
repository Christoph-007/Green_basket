const User = require('../models/User');
const Address = require('../models/Address');
const notify = require('../services/notify');

exports.getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User profile not found'
            });
        }
        res.json({
            success: true,
            data: user
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching profile',
            error: error.message
        });
    }
};

exports.updateProfile = async (req, res) => {
    try {
        const { name, phone, dietaryPreferences, allergies, dateOfBirth, notificationSettings } = req.body;

        // Only allow updating certain fields
        const updates = {};
        if (name) updates.name = name;
        if (phone) updates.phone = phone;
        if (dietaryPreferences) updates.dietaryPreferences = dietaryPreferences;
        if (allergies) updates.allergies = allergies;
        if (dateOfBirth) updates.dateOfBirth = dateOfBirth;
        if (notificationSettings) updates.notificationSettings = notificationSettings;

        const user = await User.findByIdAndUpdate(
            req.user.id,
            updates,
            { new: true, runValidators: true }
        );

        // ── Profile update notification (non-blocking) ─────────────────
        const changedFields = Object.keys(updates).filter(k => !['notificationSettings'].includes(k));
        if (changedFields.length > 0 && user) {
            const changesStr = changedFields.join(', ');
            notify.email({
                to: user.email,
                subject: 'Profile Updated — Green Basket',
                template: 'profileUpdated',
                data: { name: user.name, changes: changesStr, year: new Date().getFullYear() }
            }).catch(() => {});
        }
        // ─────────────────────────────────────────────────────────────

        res.json({
            success: true,
            message: 'Profile updated successfully',
            data: user
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating profile',
            error: error.message
        });
    }
};

exports.getAddresses = async (req, res) => {
    try {
        const addresses = await Address.find({ user: req.user.id });
        res.json({
            success: true,
            data: addresses
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching addresses',
            error: error.message
        });
    }
};

const geocodingService = require('../services/geocodingService');

exports.addAddress = async (req, res) => {
    try {
        const { location, ...addressData } = req.body;

        // Auto-geocode if location is missing
        if (!location || !location.coordinates || location.coordinates.length !== 2) {
            const addressString = geocodingService.constructAddressString(req.body);
            try {
                const coords = await geocodingService.getCoordinates(addressString);
                if (coords) {
                    req.body.location = {
                        type: 'Point',
                        coordinates: [coords.lng, coords.lat]
                    };
                }
            } catch (error) {
                console.warn('Geocoding failed for new address:', error.message);
                // Continue without coordinates
            }
        }

        // If setting as default, unset other defaults
        if (req.body.isDefault) {
            await Address.updateMany(
                { user: req.user.id },
                { isDefault: false }
            );
        }

        const address = await Address.create({
            ...req.body,
            user: req.user.id
        });

        res.status(201).json({
            success: true,
            message: 'Address added successfully',
            data: address
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error adding address',
            error: error.message
        });
    }
};

exports.updateAddress = async (req, res) => {
    try {
        const { id } = req.params;
        const { location } = req.body;

        // Check ownership
        const address = await Address.findOne({ _id: id, user: req.user.id });
        if (!address) {
            return res.status(404).json({
                success: false,
                message: 'Address not found'
            });
        }

        // Auto-geocode if address changed and location missing
        if (!location || !location.coordinates) {
            // Check if address fields changed
            const addressFields = ['addressLine1', 'addressLine2', 'city', 'state', 'pincode'];
            const hasChanged = addressFields.some(field => req.body[field] && req.body[field] !== address[field]);

            if (hasChanged) {
                const combinedAddress = { ...address.toObject(), ...req.body };
                const addressString = geocodingService.constructAddressString(combinedAddress);

                try {
                    const coords = await geocodingService.getCoordinates(addressString);
                    if (coords) {
                        req.body.location = {
                            type: 'Point',
                            coordinates: [coords.lng, coords.lat]
                        };
                    }
                } catch (error) {
                    console.warn('Geocoding failed for updated address:', error.message);
                }
            }
        }

        if (req.body.isDefault) {
            await Address.updateMany(
                { user: req.user.id },
                { isDefault: false }
            );
        }

        const updatedAddress = await Address.findByIdAndUpdate(
            id,
            req.body,
            { new: true, runValidators: true }
        );

        res.json({
            success: true,
            message: 'Address updated successfully',
            data: updatedAddress
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating address',
            error: error.message
        });
    }
};

exports.deleteAddress = async (req, res) => {
    try {
        const { id } = req.params;
        const address = await Address.findOneAndDelete({ _id: id, user: req.user.id });

        if (!address) {
            return res.status(404).json({
                success: false,
                message: 'Address not found'
            });
        }

        res.json({
            success: true,
            message: 'Address deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error deleting address',
            error: error.message
        });
    }
};

// Notification Preferences
exports.updateNotificationPreferences = async (req, res) => {
    try {
        const { email, push, sms } = req.body;

        const user = await User.findById(req.user.id);

        if (!user.notificationPreferences) {
            user.notificationPreferences = {};
        }

        if (email) {
            user.notificationPreferences.email = {
                ...user.notificationPreferences.email,
                ...email
            };
        }

        if (push) {
            user.notificationPreferences.push = {
                ...user.notificationPreferences.push,
                ...push
            };
        }

        if (sms) {
            user.notificationPreferences.sms = {
                ...user.notificationPreferences.sms,
                ...sms
            };
        }

        await user.save();

        res.json({
            success: true,
            message: 'Notification preferences updated successfully',
            data: {
                notificationPreferences: user.notificationPreferences
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating notification preferences',
            error: error.message
        });
    }
};

exports.getNotificationPreferences = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);

        res.json({
            success: true,
            data: user.notificationPreferences || {
                email: {
                    orderUpdates: true,
                    offers: true,
                    newsletter: false,
                    productUpdates: true
                },
                push: {
                    orderUpdates: true,
                    offers: true,
                    priceDrops: true,
                    backInStock: true
                },
                sms: {
                    orderUpdates: true,
                    offers: false,
                    otp: true
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching notification preferences',
            error: error.message
        });
    }
};

// FCM Token Management
exports.registerFCMToken = async (req, res) => {
    try {
        const { token, deviceType } = req.body;

        if (!token) {
            return res.status(400).json({
                success: false,
                message: 'Token is required'
            });
        }

        const user = await User.findById(req.user.id);

        if (!user.fcmTokens) {
            user.fcmTokens = [];
        }
        if (!user.deviceTokens) {
            user.deviceTokens = [];
        }

        // Remove token if already exists
        user.fcmTokens = user.fcmTokens.filter(t => t !== token);

        // Add new token
        user.fcmTokens.push(token);

        // Update device tokens
        const existingDevice = user.deviceTokens.find(d => d.token === token);
        if (existingDevice) {
            existingDevice.lastUsed = new Date();
        } else {
            user.deviceTokens.push({
                token,
                deviceType: deviceType || 'web',
                lastUsed: new Date()
            });
        }

        await user.save();

        res.json({
            success: true,
            message: 'FCM token registered successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error registering FCM token',
            error: error.message
        });
    }
};

exports.removeFCMToken = async (req, res) => {
    try {
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({
                success: false,
                message: 'Token is required'
            });
        }

        const user = await User.findById(req.user.id);

        user.fcmTokens = user.fcmTokens.filter(t => t !== token);
        user.deviceTokens = user.deviceTokens.filter(d => d.token !== token);

        await user.save();

        res.json({
            success: true,
            message: 'FCM token removed successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error removing FCM token',
            error: error.message
        });
    }
};

exports.getAllUsers = async (req, res) => {
    try {
        const { page = 1, limit = 20, search } = req.query;
        let query = {};

        if (search) {
            query = {
                $or: [
                    { name: { $regex: search, $options: 'i' } },
                    { email: { $regex: search, $options: 'i' } },
                    { phone: { $regex: search, $options: 'i' } }
                ]
            };
        }

        const skip = (page - 1) * limit;

        const [users, total] = await Promise.all([
            User.find(query)
                .select('-password -fcmTokens') // hide sensitive data
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            User.countDocuments(query)
        ]);

        res.json({
            success: true,
            data: {
                users,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};
