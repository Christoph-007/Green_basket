const https = require('https');

/**
 * Geocoding Service using OpenStreetMap (Nominatim)
 * Free to use, no API key required, but strictly rate-limited (1 request/sec)
 * For production, consider Google Maps Geocoding API or Mapbox
 */

/**
 * Get coordinates for an address string
 * @param {String} address - Full address string
 * @returns {Promise<{lat: Number, lng: Number}|null>}
 */
exports.getCoordinates = (address) => {
    return new Promise((resolve, reject) => {
        if (!address) return resolve(null);

        // Nominatim requires a User-Agent header
        const options = {
            hostname: 'nominatim.openstreetmap.org',
            port: 443,
            path: `/search?format=json&q=${encodeURIComponent(address)}&limit=1`,
            method: 'GET',
            headers: {
                'User-Agent': 'GreenBasket-Backend/1.0'
            }
        };

        const req = https.request(options, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                try {
                    if (res.statusCode !== 200) {
                        console.error(`Geocoding failed with status code: ${res.statusCode}`);
                        return resolve(null);
                    }

                    const results = JSON.parse(data);

                    if (results && results.length > 0) {
                        const { lat, lon } = results[0];
                        resolve({
                            lat: parseFloat(lat),
                            lng: parseFloat(lon)
                        });
                    } else {
                        console.warn(`No geocoding results found for address: ${address}`);
                        resolve(null);
                    }
                } catch (error) {
                    console.error('Error parsing geocoding response:', error);
                    resolve(null);
                }
            });
        });

        req.on('error', (error) => {
            console.error('Geocoding request error:', error);
            resolve(null); // Resolve null instead of reject to not break the flow
        });

        req.end();
    });
};

/**
 * Helper to construct address string from address object
 * @param {Object} addressObj 
 * @returns {String}
 */
exports.constructAddressString = (addressObj) => {
    if (!addressObj) return '';

    const parts = [
        addressObj.addressLine1,
        addressObj.addressLine2,
        addressObj.city,
        addressObj.state,
        addressObj.pincode,
        // 'India' // Default country if needed
    ];

    return parts.filter(part => part && part.trim() !== '').join(', ');
};
