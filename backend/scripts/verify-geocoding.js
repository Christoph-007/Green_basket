const geocodingService = require('../src/services/geocodingService');

async function testGeocoding() {
    console.log('Testing Geocoding Service...');

    // Test 1: Simple City
    console.log('\nTest 1: "Bangalore"');
    const coords1 = await geocodingService.getCoordinates('Bangalore');
    console.log('Result:', coords1);

    // Test 2: Full Address (Mock)
    console.log('\nTest 2: "M G Road, Bangalore, Karnataka"');
    const coords2 = await geocodingService.getCoordinates('M G Road, Bangalore, Karnataka');
    console.log('Result:', coords2);

    // Test 3: Invalid Address
    console.log('\nTest 3: "InvalidAddress123456"');
    const coords3 = await geocodingService.getCoordinates('InvalidAddress123456');
    console.log('Result:', coords3);

    // Test 4: Construction
    const addressObj = {
        addressLine1: '123 Main St',
        city: 'New York',
        state: 'NY',
        pincode: '10001'
    };
    console.log('\nTest 4: Construction');
    console.log(geocodingService.constructAddressString(addressObj));
}

testGeocoding();
