/**
 * Haversine formula — distance between two GPS coordinates in km.
 * Matches the document specification exactly.
 */
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.asin(Math.sqrt(a));
}

/**
 * Composite ranking score per VeggieMarket document:
 *   0.30 × proximity_score     (1 - distance_km / max_radius_km)
 *   0.20 × rating_score        (rating / 5.0)
 *   0.20 × freshness_score     (1.0 today, 0.7 yesterday, 0.3 two days ago — uses harvestDate if available)
 *   0.15 × eta_score            (1 - eta_mins / 120)
 *   0.10 × availability_score   (min(1.0, stock / 50) — normalized stock)
 *   0.05 × reliability_score    (fulfilled / total orders, 30-day window)
 */
function computeScore(product, distanceKm, maxRadiusKm, merchant) {
  const proximityScore = Math.max(0, 1 - distanceKm / maxRadiusKm);

  const rating = product.averageRating || merchant.averageRating || 0;
  const ratingScore = rating / 5.0;

  // Freshness: check product harvest date
  let freshnessScore = 0.5; // default
  if (product.origin && product.origin.harvestDate) {
    const harvestDate = new Date(product.origin.harvestDate);
    const now = new Date();
    const daysDiff = (now - harvestDate) / (1000 * 60 * 60 * 24);
    if (daysDiff <= 1) freshnessScore = 1.0;
    else if (daysDiff <= 2) freshnessScore = 0.7;
    else if (daysDiff <= 3) freshnessScore = 0.3;
    else freshnessScore = 0.1;
  }

  // ETA: prep_time + transit_time + buffer
  const prepTime = merchant.defaultPrepTime || 15;
  const transitTime = (distanceKm / 20) * 60; // 20 km/h default
  const buffer = 10;
  const etaMins = prepTime + transitTime + buffer;
  const etaScore = Math.max(0, 1 - etaMins / 120);

  // Availability
  const stock = product.stock || 0;
  const availabilityScore = Math.min(1.0, stock / 50);

  // Reliability
  const totalOrders = merchant.totalOrders || 0;
  const fulfilledOrders = totalOrders; // Assume all completed for now
  const reliabilityScore = totalOrders > 0 ? fulfilledOrders / totalOrders : 0.85; // New seller boost

  const score =
    0.30 * proximityScore +
    0.20 * ratingScore +
    0.20 * freshnessScore +
    0.15 * etaScore +
    0.10 * availabilityScore +
    0.05 * reliabilityScore;

  return { score: Math.round(score * 100) / 100, etaMins: Math.round(etaMins) };
}

module.exports = { haversineKm, computeScore };
