const mongoose = require('mongoose');

const addressSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    label: {
        type: String,
        enum: ['home', 'office', 'other'],
        default: 'home'
    },
    name: String,
    phone: String,
    addressLine1: {
        type: String,
        required: true
    },
    addressLine2: String,
    landmark: String,
    city: {
        type: String,
        required: true
    },
    state: {
        type: String,
        required: true
    },
    pincode: {
        type: String,
        required: true,
        match: /^[0-9]{6}$/
    },
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: [Number]  // [longitude, latitude]
    },
    isDefault: {
        type: Boolean,
        default: false
    }
}, { timestamps: true });

module.exports = mongoose.model('Address', addressSchema);
