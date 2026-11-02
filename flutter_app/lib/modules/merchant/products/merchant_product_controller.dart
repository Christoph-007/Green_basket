import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/merchant_repository.dart';

class MerchantProductController extends GetxController {
  final _repo = MerchantRepository();
  final isLoading = false.obs;
  final products = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final items = await _repo.getMyProducts();
      products.assignAll(items);
    } catch (e) {
      debugPrint('[MerchantProductController] fetchProducts error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repo.deleteProduct(id);
      fetchProducts();
      Get.snackbar('Success', 'Product deleted successfully');
    } catch (e) {
      debugPrint('[MerchantProductController] deleteProduct error: $e');
      Get.snackbar('Error', 'Failed to delete product');
    }
  }
}
