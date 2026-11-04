import 'package:get/get.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import '../../../data/repositories/product_repository.dart';



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
        GBSnack.plain('Removed', 'Removed from wishlist', position: SnackPosition.BOTTOM);
      } else {
        await _repo.addToWishlist(productId);
        wishlistIds.add(productId);
        GBSnack.success('Added', 'Added to wishlist', position: SnackPosition.BOTTOM);
      }
    } catch (_) {
      GBSnack.plain('Error', 'Failed to update wishlist', position: SnackPosition.BOTTOM);
    }
  }
}
