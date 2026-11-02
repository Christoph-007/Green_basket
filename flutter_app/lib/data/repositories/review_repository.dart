import '../providers/api_provider.dart';

class ReviewRepository {
  final _api = ApiProvider();

  /// Customer: submit a merchant review for a delivered order
  Future<Map<String, dynamic>> addMerchantReview({
    required String merchantId,
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    final response = await _api.post('/reviews', data: {
      'merchantId': merchantId,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Customer: get all reviews I have submitted (to check already-reviewed orders)
  Future<Map<String, dynamic>> getMyReviews({int page = 1}) async {
    final response = await _api.get('/reviews/my-reviews',
        params: {'page': page, 'limit': 100});
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>?) ?? data;
  }

  /// Merchant: get all reviews for my store
  Future<Map<String, dynamic>> getMyStoreReviews({int page = 1}) async {
    final response = await _api.get('/reviews/my-store',
        params: {'page': page, 'limit': 20});
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>?) ?? data;
  }

  /// Admin / Public: get reviews for a specific merchant
  Future<Map<String, dynamic>> getMerchantReviews(String merchantId,
      {int page = 1}) async {
    final response = await _api.get('/reviews/merchant/$merchantId',
        params: {'page': page, 'limit': 20});
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>?) ?? data;
  }
}
