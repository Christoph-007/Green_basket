const { haversineKm } = require('./haversine');
const { LOYALTY_TIERS } = require('../config/loyaltyTiers');

// Charged when a merchant hasn't configured delivery pricing (previous flat fee)
const DEFAULT_DELIVERY_CHARGE = 50;

const coordsOf = (doc) => {
    const c = doc && doc.location && doc.location.coordinates;
    return Array.isArray(c) && c.length === 2 && (c[0] !== 0 || c[1] !== 0) ? { lng: c[0], lat: c[1] } : null;
};

/**
 * Delivery charge for an order, from the merchant's delivery zones.
 *
 *  - pickup: ₹0
 *  - zones + measurable distance: the smallest active zone covering the
 *    address; outside every zone → not deliverable; zone minimum order applies
 *  - zones but no coordinates: the highest zone charge (never undercharge)
 *  - no zones: merchant.deliveryCharges, or ₹50 if not configured
 *  - free when itemsTotal reaches the zone's / merchant's freeDeliveryAbove,
 *    or the customer's loyalty-tier freeDeliveryThreshold
 *
 * @returns {{ ok: true, charge, distanceKm?, zone? } | { ok: false, reason, code }}
 */
function computeDelivery({ deliveryType, merchant, address, itemsTotal, user }) {
    if (deliveryType === 'pickup') return { ok: true, charge: 0 };
    if (!address) return { ok: false, code: 'ADDRESS_REQUIRED', reason: 'Please choose a delivery address' };

    const zones = ((merchant && merchant.deliveryZones) || []).filter(z => z.isActive !== false);
    const from = coordsOf(merchant);
    const to = coordsOf(address);
    let charge;
    let freeAbove = merchant && merchant.freeDeliveryAbove;
    let zone = null;
    let distanceKm;

    if (zones.length && from && to) {
        distanceKm = Math.round(haversineKm(from.lat, from.lng, to.lat, to.lng) * 100) / 100;
        zone = zones.filter(z => distanceKm <= z.radiusKm).sort((a, b) => a.radiusKm - b.radiusKm)[0];
        if (!zone) {
            return { ok: false, code: 'OUT_OF_DELIVERY_AREA', reason: `This address is ${distanceKm} km away, outside this store's delivery area`, distanceKm };
        }
        if (zone.minimumOrder && itemsTotal < zone.minimumOrder) {
            return { ok: false, code: 'BELOW_MINIMUM_ORDER', reason: `Minimum order for delivery to this area is ₹${zone.minimumOrder}` };
        }
        charge = zone.deliveryCharge;
        if (zone.freeDeliveryAbove !== undefined && zone.freeDeliveryAbove !== null) freeAbove = zone.freeDeliveryAbove;
    } else if (zones.length) {
        charge = Math.max(...zones.map(z => z.deliveryCharge || 0));
    } else {
        charge = merchant && merchant.deliveryCharges > 0 ? merchant.deliveryCharges : DEFAULT_DELIVERY_CHARGE;
    }

    const tier = user && LOYALTY_TIERS[user.loyaltyTier || 'bronze'];
    const tierThreshold = tier && tier.benefits.freeDeliveryThreshold;
    const free = (freeAbove !== undefined && freeAbove !== null && itemsTotal >= freeAbove) ||
        (tierThreshold !== undefined && tierThreshold !== null && itemsTotal >= tierThreshold);

    return { ok: true, charge: free ? 0 : charge, distanceKm, zone: zone ? { name: zone.name, radiusKm: zone.radiusKm } : null };
}

module.exports = { computeDelivery, DEFAULT_DELIVERY_CHARGE };
