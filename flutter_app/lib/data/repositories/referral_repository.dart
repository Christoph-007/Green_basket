import '../providers/api_provider.dart';

class ReferralRepository {
  final _api = ApiProvider();

  // POST /api/referral/generate — returns the user's code (creates it once)
  // { referralCode, referralLink, shareText }
  Future<Map<String, dynamic>> getOrCreateCode() async {
    final res = await _api.post('/referral/generate');
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  // GET /api/referral/stats
  // { referralCode, stats: { totalReferrals, completedReferrals, pendingReferrals, totalEarned }, referrals: [...] }
  Future<Map<String, dynamic>> getStats() async {
    final res = await _api.get('/referral/stats');
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }
}
