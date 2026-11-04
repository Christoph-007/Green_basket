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

  /// Products ticked for a bulk change (empty = not selecting).
  final selectedIds = <String>{}.obs;
  bool get isSelecting => selectedIds.isNotEmpty;

  void toggleSelected(String id) {
    if (!selectedIds.remove(id)) selectedIds.add(id);
  }

  void clearSelection() => selectedIds.clear();

  /// Sets the same stock on every selected product. Returns the server summary.
  Future<Map<String, dynamic>> bulkSetStock(int stock) async {
    final result = await _repo.bulkUpdateStock(
      [for (final id in selectedIds) {'productId': id, 'stock': stock}],
    );
    _afterBulk();
    return result;
  }

  /// Moves every selected price by [percent] (e.g. -10 or 5), rounded to paise.
  Future<Map<String, dynamic>> bulkChangePrice(double percent) async {
    final updates = <Map<String, dynamic>>[];
    for (final p in products.where((p) => selectedIds.contains(p.id))) {
      final next = (p.price * (1 + percent / 100) * 100).round() / 100;
      if (next > 0) updates.add({'productId': p.id, 'price': next});
    }
    if (updates.isEmpty) return {'successCount': 0, 'errorCount': selectedIds.length};
    final result = await _repo.bulkUpdatePrice(updates);
    _afterBulk();
    return result;
  }

  void _afterBulk() {
    clearSelection();
    fetchProducts();
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
