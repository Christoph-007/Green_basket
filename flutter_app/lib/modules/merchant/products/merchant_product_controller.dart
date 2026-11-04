import 'package:flutter/foundation.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/merchant_repository.dart';

class MerchantProductController extends GetxController {
  final _repo = MerchantRepository();
  final isLoading = false.obs;
  final products = <ProductModel>[].obs;

  /// Stock the seller has just set from the list, shown at once while the
  /// change is saved. Cleared whenever the list is loaded from the server.
  final stockOverrides = <String, int>{}.obs;

  int stockOf(ProductModel p) => stockOverrides[p.id] ?? p.stock;

  void setStockLocally(String productId, int stock) {
    stockOverrides[productId] = stock;
  }

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
      stockOverrides.clear();
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
      GBSnack.plain('Success', 'Product deleted successfully');
    } catch (e) {
      debugPrint('[MerchantProductController] deleteProduct error: $e');
      GBSnack.plain('Error', 'Failed to delete product');
    }
  }
}
