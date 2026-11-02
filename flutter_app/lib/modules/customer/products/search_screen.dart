import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../widgets/cards/product_card.dart';
import '../../../widgets/common/gb_loader.dart';
import '../../../widgets/common/empty_state.dart';
import '../cart/cart_controller.dart';

class SearchController2 extends GetxController {
  final _repo = ProductRepository();
  final results = <ProductModel>[].obs;
  final isLoading = false.obs;
  final query = ''.obs;

  Future<void> search(String q) async {
    if (q.trim().isEmpty) {
      results.clear();
      return;
    }
    query.value = q;
    isLoading.value = true;
    try {
      results.value = await _repo.search(q.trim());
    } catch (_) {}
    isLoading.value = false;
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = Get.put(SearchController2());
  final _cartCtrl = Get.find<CartController>();
  final _textCtrl = TextEditingController();
  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _textCtrl,
          autofocus: true,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search products, categories...',
            hintStyle: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textHint),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () {
                _textCtrl.clear();
                _ctrl.results.clear();
                _ctrl.query.value = '';
              },
            ),
          ),
          onChanged: (val) => _ctrl.search(val),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) return const GBLoader();
        if (_ctrl.query.value.isNotEmpty && _ctrl.results.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_outlined,
            title: 'No results found',
            message: 'Try a different search term',
            actionLabel: 'Clear Search',
            onAction: () {
              _textCtrl.clear();
              _ctrl.results.clear();
              _ctrl.query.value = '';
            },
          );
        }
        if (_ctrl.query.value.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 64, color: AppColors.border),
                const SizedBox(height: 16),
                Text(
                  'Search for fresh produce',
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: _ctrl.results.length,
          itemBuilder: (context, i) {
            final product = _ctrl.results[i];
            return ProductCard(
              product: product,
              onAddToCart: (prepId) =>
                  _cartCtrl.addItem(productId: product.id, quantity: 1, preparationOption: prepId),
            );
          },
        );
      }),
    );
  }
}
