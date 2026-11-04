import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/config/routes.dart';
import 'package:greenbasket_app/data/models/product_model.dart';
import 'package:greenbasket_app/data/repositories/product_repository.dart';
import 'package:greenbasket_app/widgets/cards/product_card.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';
import '../cart/cart_controller.dart';
import '../../../utils/responsive_helper.dart';

class CategoryDetailController extends GetxController {
  final _repo = ProductRepository();
  final products = <ProductModel>[].obs;
  final isLoading = true.obs;
  final category = Rxn<CategoryModel>();

  // Filter states
  final sortBy = 'relevance'.obs;
  final organicOnly = false.obs;
  final priceRange = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is CategoryModel) {
      category.value = args;
    } else if (args is Map) {
       // Support passing just the name or ID if needed
    }
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    try {
      final res = await _repo.getProducts(
        categoryId: category.value?.id,
        isFeatured: null, // all products in this category
      );
      products.assignAll(res);
    } catch (e) {
      GBSnack.fromError(e, title: 'Products');
    }
    isLoading.value = false;
  }

  List<ProductModel> get filteredProducts {
    var list = List<ProductModel>.from(products);
    
    if (organicOnly.value) {
      list = list.where((p) => p.tags.any((t) => t.toLowerCase() == 'organic')).toList();
    }
    
    switch (priceRange.value) {
      case 'under_50':
        list = list.where((p) => p.price < 50).toList();
        break;
      case '50_100':
        list = list.where((p) => p.price >= 50 && p.price <= 100).toList();
        break;
      case 'above_100':
        list = list.where((p) => p.price > 100).toList();
        break;
    }

    switch (sortBy.value) {
      case 'price_low':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    
    return list;
  }

  void clearFilters() {
    sortBy.value = 'relevance';
    organicOnly.value = false;
    priceRange.value = 'all';
  }
}

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CategoryDetailController());
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(ctrl.category.value?.name ?? 'Category', style: AppTextStyles.titleLarge)),
        actions: [
          IconButton(tooltip: 'Search', 
            icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
            onPressed: () => Get.toNamed(Routes.search),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: AppColors.surface,
            height: 52,
            child: Obx(() => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              children: [
                _FilterChip(
                  label: 'Sort',
                  icon: Icons.sort_rounded,
                  isActive: ctrl.sortBy.value != 'relevance',
                  onTap: () => _showSortSheet(context, ctrl),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Organic',
                  icon: Icons.eco_rounded,
                  isActive: ctrl.organicOnly.value,
                  onTap: () => ctrl.organicOnly.value = !ctrl.organicOnly.value,
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Under ₹50',
                  isActive: ctrl.priceRange.value == 'under_50',
                  onTap: () => ctrl.priceRange.value = 
                      ctrl.priceRange.value == 'under_50' ? 'all' : 'under_50',
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: '₹50 - ₹100',
                  isActive: ctrl.priceRange.value == '50_100',
                  onTap: () => ctrl.priceRange.value = 
                      ctrl.priceRange.value == '50_100' ? 'all' : '50_100',
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Above ₹100',
                  isActive: ctrl.priceRange.value == 'above_100',
                  onTap: () => ctrl.priceRange.value = 
                      ctrl.priceRange.value == 'above_100' ? 'all' : 'above_100',
                ),
              ],
            )),
          ),
          const Divider(height: 1),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Obx(() {
               final products = ctrl.filteredProducts;
               return Row(
                children: [
                  Text(
                    '${products.length} products',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (ctrl.sortBy.value != 'relevance' || ctrl.organicOnly.value || ctrl.priceRange.value != 'all')
                    Semantics(button: true, child: GestureDetector(
                      onTap: ctrl.clearFilters,
                      child: Text(
                        'Clear Filters',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                      ),
                    )),
                ],
              );
            }),
          ),

          // Product grid
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) return const GBProductGridSkeleton();
              
              final products = ctrl.filteredProducts;
              
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, color: AppColors.textHint, size: 64),
                      const SizedBox(height: AppSpacing.md),
                      const Text('No products found', style: AppTextStyles.headlineMedium),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: ctrl.clearFilters,
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ),
                );
              }
              
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.sm),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: responsive.gridCrossAxisCount,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: responsive.productCardAspectRatio,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) => ProductCard(
                  product: products[i],
                  onAddToCart: (prepId) => Get.find<CartController>()
                      .addItem(productId: products[i].id, quantity: 1, preparationOption: prepId),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context, CategoryDetailController ctrl) {
    final options = [
      ('relevance', 'Relevance'),
      ('price_low', 'Price: Low to High'),
      ('price_high', 'Price: High to Low'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.full)),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Sort By', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          ...options.map((opt) => Obx(() => ListTile(
                title: Text(opt.$2, style: AppTextStyles.bodyMedium),
                trailing: ctrl.sortBy.value == opt.$1 ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  ctrl.sortBy.value = opt.$1;
                  Get.back();
                },
              ))),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({required this.label, this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isActive ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
