import '../providers/api_provider.dart';
import '../models/loyalty_model.dart';

class LoyaltyRepository {
  final _api = ApiProvider();

  // GET /api/loyalty/history
  Future<LoyaltyModel> getLoyaltyInfo() async {
    final res = await _api.get('/loyalty/history');
    return LoyaltyModel.fromJson(res.data['data'] ?? res.data);
  }

  // GET /api/loyalty/benefits
  Future<List<Map<String, dynamic>>> getBenefits() async {
    final res = await _api.get('/loyalty/benefits');
    final list = res.data['data'] ?? res.data['benefits'] ?? [];
    return List<Map<String, dynamic>>.from(list);
  }

  // POST /api/loyalty/redeem
  Future<Map<String, dynamic>> redeemPoints({required int points}) async {
    final res = await _api.post('/loyalty/redeem', data: {'points': points});
    return res.data;
  }
}
