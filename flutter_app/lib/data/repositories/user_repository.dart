import '../providers/api_provider.dart';
import '../models/user_model.dart';

class UserRepository {
  final _api = ApiProvider();

  Future<UserModel> getProfile() async {
    final response = await _api.get('/users/profile');
    final data = (response.data as Map<String, dynamic>?) ?? {};
    final userData = data['data'] as Map<String, dynamic>?;
    return UserModel.fromJson(userData);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _api.put('/users/profile', data: data);
  }

  // Wallet, loyalty, referral and notifications live in WalletRepository,
  // LoyaltyRepository, ReferralRepository and NotificationRepository.

  // Address
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final response = await _api.get('/users/addresses');
    final data = response.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['data']);
  }

  Future<void> addAddress(Map<String, dynamic> data) async {
    await _api.post('/users/addresses', data: data);
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    await _api.put('/users/addresses/$id', data: data);
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete('/users/addresses/$id');
  }
}
