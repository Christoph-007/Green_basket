const Category = require('../models/Category');
const Offer = require('../models/Offer');
const { getNearbyProductsInternal } = require('./productController');

exports.getInitialData = async (req, res) => {
    const totalStart = Date.now();
    try {
        const { lat, lng, radius = 5 } = req.query;

        const tasks = [
            Category.find({ isActive: true }).sort({ name: 1 }).lean().then(res => {
                console.log(`[PERF] Categories fetched in ${Date.now() - totalStart}ms`);
                return res;
            }),
            Offer.find({
                isFlashSale: true,
                status: 'active',
                startDate: { $lte: new Date() },
                endDate: { $gte: new Date() }
            }).populate('merchant', 'businessName profileImage').sort({ endDate: 1 }).limit(5).lean().then(res => {
                console.log(`[PERF] FlashSales fetched in ${Date.now() - totalStart}ms`);
                return res;
            }),
            // Fetch banners (Active public non-flash-sale offers)
            // Prioritize admin offers, then newest
            Offer.find({
                status: 'active',
                isPublic: true,
                isFlashSale: false,
                startDate: { $lte: new Date() },
                endDate: { $gte: new Date() }
            })
            .sort({ createdBy: 1, createdAt: -1 }) // admin (a) comes before merchant (m)
            .limit(5)
            .lean().then(res => {
                console.log(`[PERF] Banners fetched in ${Date.now() - totalStart}ms`);
                return res;
            })
        ];

        // Add nearby products task if location provided
        let nearbyTaskIndex = -1;
        if (lat && lng) {
            nearbyTaskIndex = tasks.length;
            tasks.push(getNearbyProductsInternal({
                lat: parseFloat(lat),
                lng: parseFloat(lng),
                radius: parseFloat(radius),
                limit: 10
            }).then(res => {
                console.log(`[PERF] NearbyProducts fetched in ${Date.now() - totalStart}ms`);
                return res;
            }));
        }

        const results = await Promise.all(tasks);
        
        const categories = results[0];
        const flashSales = results[1];
        const rawBanners = results[2]; // Banners are now at index 2
        let featuredProducts = [];
        
        // Adjust index for nearby products if it was added
        const actualNearbyTaskIndex = nearbyTaskIndex !== -1 ? nearbyTaskIndex : -1;

        if (actualNearbyTaskIndex !== -1) {
            featuredProducts = results[actualNearbyTaskIndex].products;
        } else {
            // Fallback for no location - fetching sequentially if needed but ideally this would also be parallelized
            const Product = require('../models/Product');
            featuredProducts = await Product.find({ isFeatured: true, status: 'active', isActive: { $ne: false } })
                .populate('merchant', 'businessName profileImage averageRating')
                .populate('category', 'name')
                .sort({ createdAt: -1 })
                .limit(10)
                .lean();
        }

        res.json({
            success: true,
            data: {
                categories,
                featuredProducts,
                flashSales,
                banners: rawBanners.map(b => ({
                    id: b._id,
                    title: b.title,
                    description: b.description,
                    type: b.type,
                    discountPercentage: b.discountPercentage,
                    discountAmount: b.discountAmount,
                    couponCode: b.couponCode,
                    isFlashSale: b.isFlashSale,
                    // Map other fields as needed by frontend _getOfferTitle/_getOfferSubtitle
                }))
            }
        });
    } catch (error) {
        console.error('[getInitialData] Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching home data',
            error: error.message
        });
    }
};
