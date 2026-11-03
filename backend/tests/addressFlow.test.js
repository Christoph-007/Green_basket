/**
 * Saving an address exactly as the Flutter AddressModel.toJson() sends it,
 * including the GPS point from "Use current location".
 * Real in-memory MongoDB; geocoding is mocked because it calls an external service.
 */
jest.mock('../src/services/geocodingService', () => ({
    constructAddressString: jest.fn(() => 'addr'),
    geocode: jest.fn().mockResolvedValue(null),
    geocodeAddress: jest.fn().mockResolvedValue(null)
}));

const request = require('supertest');
const app = require('../server');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

let shopper;
beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    shopper = await f.customer();
});

// Same keys as AddressModel.toJson()
const appAddress = (extra = {}) => ({
    label: 'home', addressLine1: '12 Lake Road', line1: '12 Lake Road', addressLine2: 'Near the temple',
    line2: 'Near the temple', landmark: 'Near the temple', city: 'Kochi', state: 'Kerala', pincode: '682001',
    isDefault: true, ...extra
});
const save = (body) => request(app).post('/api/users/addresses').set(f.auth(shopper.token)).send(body);

it('keeps the GPS point the app sends, as [longitude, latitude]', async () => {
    const res = await save(appAddress({ location: { type: 'Point', coordinates: [76.2673, 9.9312] } }));
    expect(res.status).toBe(201);
    expect(res.body.data.location.coordinates).toEqual([76.2673, 9.9312]);
    expect(res.body.data.city).toBe('Kochi');
});

it('maps the Work label the app shows to the stored "office" label', async () => {
    const res = await save(appAddress({ label: 'office' }));
    expect(res.status).toBe(201);
    expect(res.body.data.label).toBe('office');
});

it('lists the saved address back with the fields the app reads', async () => {
    await save(appAddress({ location: { type: 'Point', coordinates: [76.2673, 9.9312] } }));
    const res = await request(app).get('/api/users/addresses').set(f.auth(shopper.token));
    expect(res.status).toBe(200);
    const list = res.body.data.addresses || res.body.data;
    const a = list[0];
    expect(a.addressLine1).toBe('12 Lake Road');
    expect(a.pincode).toBe('682001');
    expect(a.location.coordinates).toEqual([76.2673, 9.9312]);
});

it('rejects an address without the required fields', async () => {
    const res = await save({ label: 'home', city: 'Kochi' });
    expect(res.status).toBe(400);
});
