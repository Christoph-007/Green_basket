import 'package:greenbasket_app/data/providers/api_provider.dart';

class AdminRepository {
  final _api = ApiProvider();

  // Helper to extract list from response — handles both flat and nested `data` wrappers:
  // { orders: [...] }  OR  { success, data: { orders: [...] } }  OR  { success, data: [...] }
  List<dynamic> _extractList(Map<String, dynamic> data, List<String> keys) {
    // 1. Top-level key e.g. { orders: [...] }
    for (final key in keys) {
      if (data[key] is List) return data[key] as List<dynamic>;
    }
    // 2. data is directly a list e.g. { data: [...] }
    if (data['data'] is List) return data['data'] as List<dynamic>;
    // 3. Nested wrapper e.g. { success, data: { orders: [...] } }
    if (data['data'] is Map) {
      final inner = data['data'] as Map<String, dynamic>;
      for (final key in keys) {
        if (inner[key] is List) return inner[key] as List<dynamic>;
      }
      // inner itself has a 'data' list
      if (inner['data'] is List) return inner['data'] as List<dynamic>;
    }
    return [];
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _api.get('/admin/stats');
    return response.data as Map<String, dynamic>;
  }

  // Backend: GET /api/admin/merchants/all
  Future<List<dynamic>> getAllMerchants() async {
    final response = await _api.get('/admin/merchants/all');
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['merchants']);
  }

  Future<List<dynamic>> getPendingMerchants() async {
    final response = await _api.get('/admin/merchants/pending');
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['merchants']);
  }

  Future<void> verifyMerchant(String id, bool approved) async {
    await _api.patch('/admin/merchants/$id/verify', data: {'approved': approved});
  }

  Future<void> toggleMerchantBlock(String id) async {
    await _api.patch('/admin/merchants/$id/block');
  }


  Future<List<dynamic>> getUsers() async {
    final response = await _api.get('/admin/users');
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['users']);
  }

  Future<void> toggleUserBlock(String id) async {
    await _api.patch('/admin/users/$id/block');
  }

  // Orders
  // Backend: GET /api/admin/orders/all
  Future<List<dynamic>> getAllOrders({String? status}) async {
    String path = '/admin/orders/all';
    if (status != null && status.isNotEmpty && status != 'all') {
      path += '?status=$status';
    }
    final response = await _api.get(path);
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['orders']);
  }

  // Backend: GET /api/orders/:id
  Future<Map<String, dynamic>> getOrderDetail(String id) async {
    final response = await _api.get('/orders/$id');
    final data = response.data as Map<String, dynamic>;
    return (data['order'] ?? data['data'] ?? data) as Map<String, dynamic>;
  }

  // Backend: GET /api/products (public)
  Future<List<dynamic>> getAllProducts() async {
    final response = await _api.get('/products');
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['products']);
  }

  // Backend: DELETE /api/products/:id
  Future<void> deleteProduct(String id) async {
    await _api.delete('/products/$id');
  }

  // Backend: GET /api/admin/categories (admin — all categories + productsCount)
  Future<List<dynamic>> getAllCategories() async {
    final response = await _api.get('/admin/categories');
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['categories']);
  }

  // Backend: PUT /api/admin/categories/:id
  Future<void> updateCategory(String id, Map<String, dynamic> body) async {
    await _api.put('/admin/categories/$id', data: body);
  }

  // Backend: DELETE /api/admin/categories/:id
  Future<void> deleteCategory(String id) async {
    await _api.delete('/admin/categories/$id');
  }

  // Backend: GET /api/recipes/admin/all (admin - all recipes including drafts)
  Future<List<dynamic>> getAllRecipes() async {
    final response = await _api.get('/recipes/admin/all');
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['recipes']);
  }

  // Backend: DELETE /api/recipes/:id
  Future<void> deleteRecipe(String id) async {
    await _api.delete('/recipes/$id');
  }

  // Backend: GET /api/financial/admin/payouts
  Future<List<dynamic>> getPayoutRequests() async {
    final response = await _api.get('/financial/admin/payouts');
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['payouts']);
  }

  // Backend: POST /api/financial/admin/payouts/:id/process
  Future<void> processPayout(String id) async {
    await _api.post('/financial/admin/payouts/$id/process');
  }

  // Backend: POST /api/financial/admin/payouts/generate
  Future<void> bulkProcessPayouts() async {
    await _api.post('/financial/admin/payouts/generate');
  }

  // ─── Commission Settings ────────────────────────────────────────────────

  // Backend: GET /api/financial/admin/settings/commission
  Future<Map<String, dynamic>> getCommissionSettings() async {
    final response = await _api.get('/financial/admin/settings/commission');
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? data;
    return inner['settings'] as Map<String, dynamic>? ?? {};
  }

  // Backend: PUT /api/financial/admin/settings/commission
  Future<Map<String, dynamic>> updateCommissionSettings(Map<String, dynamic> body) async {
    final response = await _api.put('/financial/admin/settings/commission', data: body);
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? data;
    return inner['settings'] as Map<String, dynamic>? ?? {};
  }

  // Backend: GET /api/financial/admin/reports/financial
  Future<Map<String, dynamic>> getFinancialReports({String period = 'month', int? year, int? month}) async {
    final params = <String, dynamic>{'period': period};
    if (year != null) params['year'] = year;
    if (month != null) params['month'] = month;
    final response = await _api.get('/financial/admin/reports/financial', params: params);
    final data = response.data as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>? ?? {};
  }

  // Backend: GET /api/financial/admin/reports/revenue-orders
  Future<List<dynamic>> getRevenueOrders() async {
    final response = await _api.get('/financial/admin/reports/revenue-orders');
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? data;
    return inner['orders'] as List<dynamic>? ?? [];
  }

  // Removed Gift Card methods

  // ─── Disputes ────────────────────────────────────────────────────────────

  // Backend: GET /api/disputes/admin/all
  Future<List<dynamic>> getDisputes() async {
    final response = await _api.get('/disputes/admin/all');
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['disputes']);
  }

  // Backend: PUT /api/disputes/admin/:id/resolve
  Future<void> resolveDispute(String id, Map<String, dynamic> body) async {
    await _api.put('/disputes/admin/$id/resolve', data: body);
  }

  // ─── Returns ─────────────────────────────────────────────────────────────

  // Backend: GET /api/returns/admin/all
  Future<List<dynamic>> getReturns() async {
    final response = await _api.get('/returns/admin/all');
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['returns']);
  }

  // Backend: PUT /api/returns/admin/:id/process
  Future<void> processReturn(String id, Map<String, dynamic> body) async {
    await _api.put('/returns/admin/$id/process', data: body);
  }

  // Backend: GET /api/notifications/admin/all
  Future<Map<String, dynamic>> getSentNotifications({int page = 1, int limit = 20, String? audience}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (audience != null && audience != 'All Users') params['audience'] = audience;
    final response = await _api.get('/notifications/admin/all', params: params);
    final data = response.data as Map<String, dynamic>;
    
    final innerData = (data['data'] is Map) ? data['data'] as Map<String, dynamic> : {};
    final pagination = innerData['pagination'] as Map<String, dynamic>?;

    return {
      'notifications': _extractList(data, ['notifications']),
      'total': pagination?['total'] ?? 0,
      'pages': pagination?['pages'] ?? 1,
    };
  }

  // Backend: POST /api/notifications/admin/bulk-send
  Future<void> sendNotification(Map<String, dynamic> body) async {
    await _api.post('/notifications/admin/bulk-send', data: body);
  }

  // ─── Admin Offers ────────────────────────────────────────────────────────

  // Use admin endpoint for full offer details (startDate, usedCount, etc.)
  Future<List<dynamic>> getOffers() async {
    final response = await _api.get('/offers/admin/all');
    final data = response.data as Map<String, dynamic>;
    return _extractList(data, ['offers']);
  }

  Future<void> createOffer(Map<String, dynamic> body) async {
    await _api.post('/offers', data: body);
  }

  Future<void> updateOffer(String id, Map<String, dynamic> body) async {
    await _api.put('/offers/$id', data: body);
  }

  Future<void> deleteOffer(String id) async {
    await _api.delete('/offers/$id');
  }

  // ─── Admin Orders Actions ────────────────────────────────────────────────

  // Backend: PATCH /api/orders/:id/cancel
  Future<void> cancelOrder(String id, String reason) async {
    await _api.patch('/orders/$id/cancel', data: {'reason': reason});
  }

  // Backend: POST /api/payment/refund (admin only; full refund by default)
  Future<void> refundOrder(String id, {String reason = 'Refunded by admin', double? amount}) async {
    await _api.post('/payment/refund', data: {
      'orderId': id,
      'reason': reason,
      if (amount != null) 'amount': amount,
    });
  }

  // ─── Category CRUD ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> body) async {
    final response = await _api.post('/categories', data: body);
    return response.data as Map<String, dynamic>;
  }

  // ─── Recipe CRUD ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> body) async {
    final response = await _api.post('/recipes', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRecipe(String id, Map<String, dynamic> body) async {
    final response = await _api.put('/recipes/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  // ─── Merchant Analytics ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMerchantAnalytics(String merchantId, {String period = 'week'}) async {
    final response = await _api.get('/admin/merchants/$merchantId/analytics', params: {'period': period});
    return response.data as Map<String, dynamic>;
  }


  // ─── Product Admin ───────────────────────────────────────────────────────

  Future<void> updateProduct(String id, Map<String, dynamic> body) async {
    await _api.put('/products/$id', data: body);
  }
}
