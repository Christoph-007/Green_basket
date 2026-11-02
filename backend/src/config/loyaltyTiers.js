const LOYALTY_TIERS = {
    bronze: {
        name: 'Bronze',
        minPoints: 0,
        maxPoints: 499,
        benefits: {
            extraPointsPercentage: 0,
            freeDeliveryThreshold: null,
            prioritySupport: false,
            pointsPerRupee: 1 // 1 point per ₹10 spent
        },
        color: '#CD7F32'
    },
    silver: {
        name: 'Silver',
        minPoints: 500,
        maxPoints: 999,
        benefits: {
            extraPointsPercentage: 10, // +10% bonus points
            freeDeliveryThreshold: 299,
            prioritySupport: false,
            pointsPerRupee: 1
        },
        color: '#C0C0C0'
    },
    gold: {
        name: 'Gold',
        minPoints: 1000,
        maxPoints: 2499,
        benefits: {
            extraPointsPercentage: 20, // +20% bonus points
            freeDeliveryThreshold: 199,
            prioritySupport: true,
            pointsPerRupee: 1.5 // 1.5 points per ₹10 spent
        },
        color: '#FFD700'
    },
    platinum: {
        name: 'Platinum',
        minPoints: 2500,
        maxPoints: Infinity,
        benefits: {
            extraPointsPercentage: 30, // +30% bonus points
            freeDeliveryThreshold: 0, // Always free delivery
            prioritySupport: true,
            pointsPerRupee: 2 // 2 points per ₹10 spent
        },
        color: '#E5E4E2'
    }
};

function getTierFromPoints(points) {
    if (points >= LOYALTY_TIERS.platinum.minPoints) return 'platinum';
    if (points >= LOYALTY_TIERS.gold.minPoints) return 'gold';
    if (points >= LOYALTY_TIERS.silver.minPoints) return 'silver';
    return 'bronze';
}

function getNextTier(currentTier) {
    const tiers = ['bronze', 'silver', 'gold', 'platinum'];
    const currentIndex = tiers.indexOf(currentTier);
    return currentIndex < tiers.length - 1 ? tiers[currentIndex + 1] : null;
}

function getPointsToNextTier(currentPoints, currentTier) {
    const nextTier = getNextTier(currentTier);
    if (!nextTier) return 0;
    return LOYALTY_TIERS[nextTier].minPoints - currentPoints;
}

module.exports = {
    LOYALTY_TIERS,
    getTierFromPoints,
    getNextTier,
    getPointsToNextTier
};
