import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/repositories/merchant_repository.dart';

class OffersController extends GetxController {
  final _repo = MerchantRepository();
  final isLoading = false.obs;

  final activeOffers = <Map<String, dynamic>>[].obs;
  final scheduledOffers = <Map<String, dynamic>>[].obs;
  final expiredOffers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    try {
      isLoading.value = true;
      final all = await _repo.getOffers();

      activeOffers.assignAll(
          all.where((o) => o['status'] == 'active' || o['active'] == true));
      scheduledOffers.assignAll(
          all.where((o) => o['status'] == 'scheduled'));
      expiredOffers.assignAll(
          all.where((o) => o['status'] == 'expired'));
    } catch (e) {
      debugPrint('[OffersController] fetchOffers error: $e');
      activeOffers.clear();
      scheduledOffers.clear();
      expiredOffers.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleOffer(String id, bool active) async {
    try {
      await _repo.toggleOffer(id, active);
      fetchOffers();
    } catch (e) {
      debugPrint('[OffersController] toggleOffer error: $e');
      Get.snackbar('Error', 'Could not update offer status');
    }
  }

  Future<void> deleteOffer(String id) async {
    try {
      await _repo.deleteOffer(id);
      fetchOffers();
      Get.snackbar('Deleted', 'Offer removed successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('[OffersController] deleteOffer error: $e');
      Get.snackbar('Error', 'Could not delete offer');
    }
  }
}
