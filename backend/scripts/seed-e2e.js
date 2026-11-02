#!/usr/bin/env node
/**
 * Seed a throwaway database for the Flutter ↔ backend integration test
 * (flutter_app/test/api_integration_test.dart). WIPES the target database.
 *
 *   MONGODB_URI=mongodb://127.0.0.1:27017/gb_e2e node scripts/seed-e2e.js
 *
 * Refuses to run against anything that isn't a local database whose name
 * contains "e2e" or "test".
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const mongoose = require('mongoose');

const uri = process.env.MONGODB_URI || '';
if (!/^mongodb:\/\/(127\.0\.0\.1|localhost)(:\d+)?\/[^/?]*(e2e|test)/i.test(uri)) {
    console.error('Refusing to seed: MONGODB_URI must be a local *e2e*/*test* database');
    process.exit(1);
}

const User = require('../src/models/User');
const Merchant = require('../src/models/Merchant');
const Category = require('../src/models/Category');
const Product = require('../src/models/Product');
const Address = require('../src/models/Address');
const Offer = require('../src/models/Offer');

(async () => {
    await mongoose.connect(uri);
    await mongoose.connection.dropDatabase();

    const customer = await User.create({
        name: 'E2E Customer', email: 'e2e.customer@greenbasket.test', phone: '9100000001',
        password: 'password123', isEmailVerified: true
    });
    const merchant = await Merchant.create({
        name: 'E2E Farmer', email: 'e2e.merchant@greenbasket.test', phone: '9100000002',
        password: 'password123', businessName: 'E2E Farm', verificationStatus: 'approved', isStoreOpen: true,
        address: { street: 'Farm Rd', city: 'Chennai', state: 'TN', pincode: '600001' },
        location: { type: 'Point', coordinates: [80.27, 13.08] },
        deliveryZones: [{ name: 'Near', radiusKm: 5, deliveryCharge: 20 }, { name: 'City', radiusKm: 15, deliveryCharge: 60 }]
    });
    const category = await Category.create({ name: 'Vegetables', slug: 'vegetables' });
    const product = await Product.create({
        name: 'E2E Tomato', description: 'Fresh', merchant: merchant._id, category: category._id,
        price: 100, stock: 50, unit: 'kg', status: 'active',
        preparationOptions: [{ type: 'chopped', additionalPrice: 20 }]
    });
    await Address.create({
        user: customer._id, label: 'home', name: customer.name, phone: customer.phone,
        addressLine1: '1 Near St', city: 'Chennai', state: 'TN', pincode: '600002', isDefault: true,
        location: { type: 'Point', coordinates: [80.27, 13.10] } // ~2 km → "Near" zone, ₹20
    });
    await Offer.create({
        title: 'E2E Ten', type: 'flat', discountAmount: 10, couponCode: 'E2E10', status: 'active', createdBy: 'admin',
        startDate: new Date(Date.now() - 86400000), endDate: new Date(Date.now() + 86400000), usagePerUser: 5
    });

    console.log(JSON.stringify({ productId: product._id, merchantId: merchant._id, customerId: customer._id }));
    await mongoose.disconnect();
})().catch(err => { console.error(err); process.exit(1); });
