/**
 * Merchant CSV bulk upload: upload, history and template endpoints.
 */
jest.mock('../src/services/notify', () => ({
    email: jest.fn().mockResolvedValue({}), sms: jest.fn().mockResolvedValue({}),
    push: jest.fn().mockResolvedValue({}), all: jest.fn().mockResolvedValue({})
}));

const request = require('supertest');
const app = require('../server');
const Merchant = require('../src/models/Merchant');
const Category = require('../src/models/Category');
const Product = require('../src/models/Product');
const generateToken = require('../src/utils/generateToken');
const db = require('./helpers/db');

jest.setTimeout(60000);

let token;

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    const merchant = await Merchant.create({
        name: 'Ravi', email: 'ravi@farm.com', phone: '9000000002', password: 'secret123',
        businessName: 'Ravi Farm', verificationStatus: 'approved',
        address: { street: 'x', city: 'x', state: 'x', pincode: '000000' }
    });
    token = generateToken(merchant._id, 'merchant');
    await Category.create({ name: 'Vegetables', slug: 'vegetables' });
});

const auth = () => ({ Authorization: `Bearer ${token}` });

it('serves a CSV template with the columns bulk-upload reads', async () => {
    const res = await request(app).get('/api/bulk/products/template').set(auth());
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/text\/csv/);
    expect(res.text.split('\n')[0]).toBe('name,description,category,price,stock,unit,tags,primaryImage');
});

it('uploads a CSV, reports row errors, and records it in the upload history', async () => {
    const csv = [
        'name,description,category,price,stock,unit,tags,primaryImage',
        'Tomato,Red,Vegetables,40,100,kg,organic,',
        'Bad Price,x,Vegetables,-5,10,kg,,',
        'Sneaky,x,.*,10,10,kg,,' // regex characters must not match "Vegetables"
    ].join('\n');

    const res = await request(app).post('/api/bulk/products/bulk-upload').set(auth())
        .attach('file', Buffer.from(csv), 'products.csv');

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual(expect.objectContaining({ totalRows: 3, successCount: 1, errorCount: 2 }));
    expect(await Product.countDocuments({ name: 'Sneaky' })).toBe(0);

    const history = await request(app).get('/api/bulk/products/upload-history').set(auth());
    expect(history.status).toBe(200);
    expect(history.body.data).toHaveLength(1);
    expect(history.body.data[0]).toEqual(expect.objectContaining({
        fileName: 'products.csv', totalRows: 3, successCount: 1, errorCount: 2, status: 'partial'
    }));
});
