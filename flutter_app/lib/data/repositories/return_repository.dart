import '../models/return_model.dart';
import '../providers/api_provider.dart';

class ReturnRepository {
  final _api = ApiProvider();

  /// Customer: every return request I have made, newest first.
  Future<List<ReturnModel>> getMyReturns() async {
    final response = await _api.get('/returns/my-returns', params: {'limit': 100});
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final list = data['returns'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ReturnModel.fromJson)
        .toList();
  }

  /// Customer: ask to return items of a delivered or completed order.
  /// [orderId] is the order's database id; [items] are `{productId, quantity}`.
  Future<Map<String, dynamic>> requestReturn({
    required String orderId,
    required String reason,
    required List<Map<String, dynamic>> items,
    String refundMethod = 'wallet',
  }) async {
    final response = await _api.post('/returns', data: {
      'orderId': orderId,
      'type': 'return',
      'reason': reason,
      'items': items,
      'refundMethod': refundMethod,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Customer: withdraw a request that has not been reviewed yet.
  Future<void> cancelReturn(String returnId) async {
    await _api.delete('/returns/$returnId');
  }
}
