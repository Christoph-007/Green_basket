import '../providers/api_provider.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class MerchantRepository {
  final _api = ApiProvider();

  // ─── Profile ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _api.get('/merchants/profile');
    return (response.data as Map<String, dynamic>?) ?? {};
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _api.put('/merchants/profile', data: data);
  }

  Future<void> toggleStoreStatus() async {
    await _api.patch('/merchants/toggle-store');
  }

  // ─── Dashboard Stats ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _api.get('/merchants/dashboard-stats');
    return response.data as Map<String, dynamic>;
  }

  // ─── Order Management ─────────────────────────────────────────────────────

  Future<List<OrderModel>> getMerchantOrders({String? status}) async {
    final response = await _api.get('/orders/merchant/orders', params: {
      if (status != null) 'status': status,
    });
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? {};
    final items = inner['orders'] as List<dynamic>? ?? [];
    return items.map((e) => OrderModel.fromJson(e)).toList();
  }

  /// [note] is stored in the status history (and used as the cancel reason).
  Future<void> updateOrderStatus(String orderId, String status, {String? note}) async {
    await _api.patch('/orders/merchant/$orderId/status', data: {
      'status': status,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  // ─── Product Management ───────────────────────────────────────────────────

  Future<List<ProductModel>> getMyProducts() async {
    final response = await _api.get('/products/merchant/my-products');
    final data = response.data as Map<String, dynamic>;
    // Backend returns { data: { products: [...], pagination: {...} } }
    final inner = data['data'];
    List<dynamic> items;
    if (inner is List) {
      items = inner;
    } else if (inner is Map<String, dynamic>) {
      items = inner['products'] as List<dynamic>? ?? [];
    } else {
      items = [];
    }
    return items.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    await _api.post('/products', data: product);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> product) async {
    await _api.put('/products/$id', data: product);
  }

  Future<void> updateStock(String id, int stock) async {
    await _api.patch('/products/$id/stock', data: {'stock': stock});
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/products/$id');
  }

  /// PUT /api/bulk/products/bulk-update-stock. Returns {successCount, errorCount, errors}.
  Future<Map<String, dynamic>> bulkUpdateStock(List<Map<String, dynamic>> updates) async {
    final response = await _api.put('/bulk/products/bulk-update-stock', data: {'updates': updates});
    return ((response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?) ?? {};
  }

  /// PUT /api/bulk/products/bulk-update-price. Returns {successCount, errorCount, errors}.
  Future<Map<String, dynamic>> bulkUpdatePrice(List<Map<String, dynamic>> updates) async {
    final response = await _api.put('/bulk/products/bulk-update-price', data: {'updates': updates});
    return ((response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?) ?? {};
  }

  // GET /api/bulk/products/upload-history
  Future<List<Map<String, dynamic>>> getUploadHistory() async {
    final response = await _api.get('/bulk/products/upload-history');
    final data = response.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  // POST /api/bulk/products/bulk-upload (multipart field "file")
  // Returns { totalRows, successCount, errorCount, errors: [{ row, error }] }
  Future<Map<String, dynamic>> bulkUploadProducts({
    required List<int> bytes,
    required String fileName,
  }) async {
    final response = await _api.uploadBytes(
      '/bulk/products/bulk-upload',
      bytes: bytes,
      filename: fileName,
      fieldName: 'file',
    );
    final data = response.data as Map<String, dynamic>;
    return Map<String, dynamic>.from(data['data'] ?? {});
  }

  // GET /api/bulk/products/template — CSV text with the expected columns
  Future<String> getUploadTemplate() async {
    final response = await _api.get('/bulk/products/template');
    return response.data.toString();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _api.get('/categories');
    final data = response.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  // ─── Offers / Discounts ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOffers({String? status}) async {
    final response = await _api.get('/offers/merchant', params: {
      if (status != null) 'status': status,
    });
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? {};
    return List<Map<String, dynamic>>.from(inner['offers'] ?? []);
  }

  Future<Map<String, dynamic>> createOffer(Map<String, dynamic> data) async {
    final response = await _api.post('/offers', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateOffer(String id, Map<String, dynamic> data) async {
    await _api.put('/offers/$id', data: data);
  }

  Future<void> deleteOffer(String id) async {
    await _api.delete('/offers/$id');
  }

  Future<void> toggleOffer(String id, bool active) async {
    await updateOffer(id, {'status': active ? 'active' : 'expired'});
  }

  Future<Map<String, dynamic>> getOfferAnalytics(String offerId) async {
    final response = await _api.get('/offers/$offerId/analytics');
    return response.data as Map<String, dynamic>;
  }

  // ─── Analytics ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSalesAnalytics({String period = 'month'}) async {
    final response = await _api.get('/merchants/analytics/sales', params: {'period': period});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProductAnalytics() async {
    final response = await _api.get('/merchants/analytics/products');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCustomerAnalytics() async {
    final response = await _api.get('/merchants/analytics/customers');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInventoryAnalytics() async {
    final response = await _api.get('/merchants/analytics/inventory');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAnalytics({String period = 'month'}) async {
    // This is a legacy/summary call, we'll map it to sales analytics for now
    return getSalesAnalytics(period: period);
  }

  // ─── Financial ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getFinancialSummary(
      {String period = 'month'}) async {
    final response = await _api.get('/financial/merchants/summary',
        params: {'period': period});
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getTransactions(
      {String period = 'month'}) async {
    final response = await _api.get('/financial/merchants/transactions',
        params: {'period': period});
    final data = response.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  // ─── Payouts ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPayoutSummary() async {
    final response = await _api.get('/financial/merchants/earnings');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getPayouts() async {
    final response = await _api.get('/financial/merchants/payouts');
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? {};
    return List<Map<String, dynamic>>.from(inner['payouts'] ?? []);
  }

  Future<Map<String, dynamic>> requestPayout({double? amount}) async {
    final response = await _api.post('/financial/merchants/request-payout',
        data: {'amount': amount});
    return response.data as Map<String, dynamic>;
  }

  // ─── Delivery Zones ───────────────────────────────────────────────────────
  // Backend: /api/merchants/zones/delivery-zones (fields radiusKm,
  // deliveryCharge, minimumOrder, freeDeliveryAbove, estimatedDeliveryTime,
  // isActive). The zone screens use short keys (radius, charge, minOrder,
  // estimatedTime, active), so both are translated here.

  static Map<String, dynamic> zoneFromApi(Map<String, dynamic> z) => {
        ...z,
        'radius': z['radiusKm'],
        'charge': z['deliveryCharge'],
        'minOrder': z['minimumOrder'],
        'estimatedTime': z['estimatedDeliveryTime'],
        'active': z['isActive'] ?? true,
      };

  static Map<String, dynamic> zoneToApi(Map<String, dynamic> d) {
    final out = <String, dynamic>{
      'name': d['name'],
      'radiusKm': d['radiusKm'] ?? d['radius'],
      'deliveryCharge': d['deliveryCharge'] ?? d['charge'],
      'minimumOrder': d['minimumOrder'] ?? d['minOrder'],
      'freeDeliveryAbove': d['freeDeliveryAbove'],
      'estimatedDeliveryTime': d['estimatedDeliveryTime'] ?? d['estimatedTime'],
      'isActive': d['isActive'] ?? d['active'],
    };
    out.removeWhere((_, v) => v == null || (v is String && v.isEmpty));
    return out;
  }

  Future<List<Map<String, dynamic>>> getDeliveryZones() async {
    final response = await _api.get('/merchants/zones/delivery-zones');
    final data = response.data as Map<String, dynamic>;
    final zones = (data['data'] is Map ? data['data']['zones'] : data['data']) ?? [];
    return (zones as List)
        .map((z) => zoneFromApi(Map<String, dynamic>.from(z)))
        .toList();
  }

  Future<void> createZone(Map<String, dynamic> data) async {
    await _api.post('/merchants/zones/delivery-zones', data: zoneToApi(data));
  }

  Future<void> updateZone(String id, Map<String, dynamic> data) async {
    await _api.put('/merchants/zones/delivery-zones/$id', data: zoneToApi(data));
  }

  Future<void> deleteZone(String id) async {
    await _api.delete('/merchants/zones/delivery-zones/$id');
  }

  Future<void> toggleZone(String id, bool active) async {
    await _api.put('/merchants/zones/delivery-zones/$id', data: {'isActive': active});
  }

  /// PUT /api/merchants/zones/location — the store's map location, used to
  /// measure delivery distance to customers.
  Future<void> setStoreLocation({
    required double latitude,
    required double longitude,
  }) async {
    await _api.put('/merchants/zones/location', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // ─── Store Settings ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStoreSettings() async {
    return getProfile();
  }

  Future<void> saveStoreSettings(Map<String, dynamic> data) async {
    await updateProfile(data);
  }

  // ─── Reviews ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyStoreReviews({int page = 1}) async {
    final response = await _api.get('/reviews/my-store',
        params: {'page': page, 'limit': 20});
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>?) ?? data;
  }

  Future<bool> replyToReview(String reviewId, String comment) async {
    try {
      await _api.post('/reviews/$reviewId/reply', data: {'comment': comment});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Disputes ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDisputes() async {
    final response = await _api.get('/disputes/merchant/all');
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? data;
    final items = inner['disputes'] as List<dynamic>? ?? [];
    return List<Map<String, dynamic>>.from(items);
  }

  Future<void> resolveDispute(String id, Map<String, dynamic> data) async {
    await _api.put('/disputes/merchant/$id/resolve', data: data);
  }
}


