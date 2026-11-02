import 'package:get/get.dart';
import '../../../data/repositories/product_repository.dart';


import '../../../config/theme.dart';

class WishlistController extends GetxController {
  final _repo = ProductRepository();
  final wishlistIds = <String>{}.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    isLoading.value = true;
    try {
      final items = await _repo.getWishlist();
      wishlistIds.assignAll(items.map((e) => e.id));
    } catch (_) {}
    isLoading.value = false;
  }

  bool isWishlisted(String productId) => wishlistIds.contains(productId);

  Future<void> toggleWishlist(String productId) async {
    try {
      if (wishlistIds.contains(productId)) {
        await _repo.removeFromWishlist(productId);
        wishlistIds.remove(productId);
        Get.snackbar('Removed', 'Removed from wishlist',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        await _repo.addToWishlist(productId);
        wishlistIds.add(productId);
        Get.snackbar('Added', 'Added to wishlist',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.primaryContainer,
            colorText: AppColors.primary);
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to update wishlist',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
