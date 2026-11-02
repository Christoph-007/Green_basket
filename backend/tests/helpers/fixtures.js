/**
 * Test data builders for integration tests (real in-memory MongoDB).
 */
const User = require('../../src/models/User');
const Merchant = require('../../src/models/Merchant');
const Admin = require('../../src/models/Admin');
const Category = require('../../src/models/Category');
const Product = require('../../src/models/Product');
const Address = require('../../src/models/Address');
const generateToken = require('../../src/utils/generateToken');

let seq = 0;
const next = () => ++seq;

async function customer(overrides = {}) {
    const n = next();
    const user = await User.create({
        name: `Customer ${n}`, email: `c${n}@example.com`, phone: `90000${String(n).padStart(5, '0')}`,
        password: 'secret123', ...overrides
    });
    return { user, token: generateToken(user._id, 'user') };
}

async function merchant(overrides = {}) {
    const n = next();
    const m = await Merchant.create({
        name: `Merchant ${n}`, email: `m${n}@farm.com`, phone: `80000${String(n).padStart(5, '0')}`,
        password: 'secret123', businessName: `Farm ${n}`, verificationStatus: 'approved', isStoreOpen: true,
        address: { street: 'x', city: 'Chennai', state: 'TN', pincode: '600001' },
        location: { type: 'Point', coordinates: [80.27, 13.08] },
        ...overrides
    });
    return { merchant: m, token: generateToken(m._id, 'merchant') };
}

async function admin() {
    const n = next();
    const a = await Admin.create({ name: `Admin ${n}`, email: `a${n}@gb.com`, password: 'secret123' });
    return { admin: a, token: generateToken(a._id, 'admin') };
}

async function category() {
    const n = next();
    return Category.create({ name: `Category ${n}`, slug: `category-${n}` });
}

async function product(merchantDoc, overrides = {}) {
    const n = next();
    const cat = overrides.category || (await category())._id;
    return Product.create({
        name: `Product ${n}`, description: 'Fresh', merchant: merchantDoc._id, category: cat,
        price: 100, stock: 10, unit: 'kg', ...overrides
    });
}

async function address(userDoc, overrides = {}) {
    return Address.create({
        user: userDoc._id, name: userDoc.name, phone: userDoc.phone,
        addressLine1: '1 Main St', city: 'Chennai', state: 'TN', pincode: '600001',
        location: { type: 'Point', coordinates: [80.27, 13.08] },
        ...overrides
    });
}

const auth = (token) => ({ Authorization: `Bearer ${token}` });

module.exports = { customer, merchant, admin, category, product, address, auth };
