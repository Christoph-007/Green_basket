import '../providers/api_provider.dart';
import '../models/wallet_model.dart';

class WalletRepository {
  final _api = ApiProvider();

  // GET /api/wallet
  Future<WalletModel> getWallet() async {
    final res = await _api.get('/wallet');
    return WalletModel.fromJson(res.data['data'] ?? res.data);
  }

  // GET /api/wallet/transactions
  Future<List<WalletTransaction>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get('/wallet/transactions', params: {
      'page': page,
      'limit': limit,
    });
    // Response: { data: { transactions: [...], summary, pagination } }
    final data = res.data['data'];
    final list = (data is Map ? data['transactions'] : data) ?? [];
    return (list as List)
        .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // POST /api/wallet/add-money
  Future<Map<String, dynamic>> addMoney(double amount) async {
    final res = await _api.post('/wallet/add-money', data: {'amount': amount});
    return res.data;
  }

  // POST /api/wallet/verify-topup
  // The backend credits the amount Razorpay reports, not a client amount.
  Future<Map<String, dynamic>> verifyTopup({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final res = await _api.post('/wallet/verify-topup', data: {
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
    });
    return res.data;
  }

  // POST /api/wallet/use-for-payment — pay an existing unpaid order
  // (the amount is always the order total, decided by the backend)
  Future<Map<String, dynamic>> useForPayment({required String orderId}) async {
    final res = await _api.post('/wallet/use-for-payment', data: {
      'orderId': orderId,
    });
    return res.data;
  }
}
