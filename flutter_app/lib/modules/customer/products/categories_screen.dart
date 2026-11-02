import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:cached_network_image/cached_network_image.dart'; // No longer used in this file
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/location_service.dart';
import '../../../widgets/cards/product_card.dart';
import '../../../widgets/common/gb_loader.dart';
import '../../../widgets/common/empty_state.dart';
import '../cart/cart_controller.dart';
import '../profile/wishlist_controller.dart';

class CategoriesController extends GetxController {
  final _repo = ProductRepository();

  final isLoading = false.obs;
  final categories = <CategoryModel>[].obs;
  final products = <ProductModel>[].obs;
  final selectedCategoryId = ''.obs;
  final searchQuery = ''.obs;
  final selectedRadiusKm = 10.0.obs; // Customer's chosen radius
  final actualRadiusKm = 0.0.obs; // What the backend actually returned
  final hasLocation = false.obs;
  final showAll = false.obs; // "See All Merchants" toggle

  double? _lat;
  double? _lng;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final preselected = args['categoryId'] as String? ?? '';
    _initLocation(preselected: preselected);
  }

  Future<void> _initLocation({String preselected = ''}) async {
    final locResult = await LocationService.getLocation();
    if (locResult != null) {
      _lat = locResult.lat;
      _lng = locResult.lng;
      hasLocation.value = true;
    }
    fetchCategories(preselected: preselected);
  }

  void toggleShowAll() {
    showAll.value = !showAll.value;
    fetchProducts(selectedCategoryId.value);
  }

  void updateRadius(double radius) {
    selectedRadiusKm.value = radius;
    if (!showAll.value) {
      fetchProducts(selectedCategoryId.value);
    }
  }

  Future<void> fetchCategories({String preselected = ''}) async {
    try {
      final fetched = await _repo.getCategories();
      categories.value = [
        CategoryModel(id: '', name: 'All', image: null),
        ...fetched,
      ];
      selectedCategoryId.value = preselected.isNotEmpty ? preselected : '';
      fetchProducts(selectedCategoryId.value);
    } catch (_) {}
  }

  Future<void> fetchProducts(String categoryId) async {
    isLoading.value = true;
    selectedCategoryId.value = categoryId;
    try {
      if (showAll.value) {
        // "See All" mode — bypass location filter
        final result = await _repo.getNearbyProducts(
          lat: 0, lng: 0,
          categoryId: categoryId.isEmpty ? null : categoryId,
          allProducts: true,
        );
        products.value = result['products'] as List<ProductModel>;
        actualRadiusKm.value = 0;
      } else if (_lat != null && _lng != null) {
        final result = await _repo.getNearbyProducts(
          lat: _lat!,
          lng: _lng!,
          radius: selectedRadiusKm.value, // Custom filter radius
          categoryId: categoryId.isEmpty ? null : categoryId,
        );
        products.value = result['products'] as List<ProductModel>;
        actualRadiusKm.value = result['actual_radius_km'] as double;
      } else {
        products.value = await _repo.getProducts(
          categoryId: categoryId.isEmpty ? null : categoryId,
        );
      }
    } catch (_) {
      try {
        products.value = await _repo.getProducts(
          categoryId: categoryId.isEmpty ? null : categoryId,
        );
      } catch (_) {}
    }
    isLoading.value = false;
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    isLoading.value = true;
    searchQuery.value = query;
    try {
      products.value = await _repo.search(query);
    } catch (_) {}
    isLoading.value = false;
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CategoriesController());
    final cartCtrl = Get.find<CartController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Categories', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
          // Top horizontal category list (Refined Chip List)
          Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.divider.withOpacity(0.5))),
            ),
            child: Obx(() => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: ctrl.categories.length,
                  itemBuilder: (context, i) {
                    final cat = ctrl.categories[i];
                    final isSelected = ctrl.selectedCategoryId.value == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => ctrl.fetchProducts(cat.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.divider,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Text(
                            cat.name,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )),
          ),

          // Nearby radius indicator + Show All toggle (Always Visible)
          Obx(() {
            final isShowAll = ctrl.showAll.value;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isShowAll
                  ? AppColors.surface
                  : AppColors.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(
                    isShowAll ? Icons.public : Icons.location_on,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isShowAll
                          ? 'Showing all merchants'
                          : 'Showing products within ${ctrl.actualRadiusKm.value.toStringAsFixed(0)} km',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ctrl.toggleShowAll(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isShowAll ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        isShowAll ? 'Nearby only' : 'Show all',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isShowAll ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (!isShowAll) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showRadiusPicker(context, ctrl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${ctrl.selectedRadiusKm.value.toInt()}km',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          // Product grid below
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const GBLoader();
              }
              if (ctrl.products.isEmpty) {
                return const EmptyState(
                  icon: Icons.eco_outlined,
                  title: 'No products found',
                  message: 'Try selecting a different category',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: ctrl.products.length,
                itemBuilder: (context, i) {
                  final product = ctrl.products[i];
                  final wishlistCtrl = Get.find<WishlistController>();
                  return Obx(() {
                    return ProductCard(
                      product: product,
                      isInWishlist: wishlistCtrl.isWishlisted(product.id),
                      onWishlistToggle: () =>
                          wishlistCtrl.toggleWishlist(product.id),
                      onAddToCart: (prepId) => cartCtrl.addItem(
                          productId: product.id,
                          quantity: 1,
                          preparationOption: prepId),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),

    );
  }

  void _showRadiusPicker(BuildContext context, CategoriesController ctrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Search Radius',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Only showing merchants within this distance from your location.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            Obx(() => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [5, 10, 20, 50, 100].map((r) {
                    final isSelected = ctrl.selectedRadiusKm.value == r.toDouble();
                    return ChoiceChip(
                      label: Text('${r}km'),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (val) {
                        if (val) {
                          ctrl.updateRadius(r.toDouble());
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
                )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
