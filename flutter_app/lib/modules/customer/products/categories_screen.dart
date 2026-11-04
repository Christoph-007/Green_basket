import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
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
import '../nav_controller.dart';
import '../profile/wishlist_controller.dart';

class CategoriesController extends GetxController {
  CategoriesController({ProductRepository? repository})
      : _repo = repository ?? ProductRepository();

  final ProductRepository _repo;

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
  bool _categoriesLoaded = false;

  /// Each fetch gets a number; a response is ignored if a newer fetch was
  /// started meanwhile (tapping chips quickly used to show the products of an
  /// older category under the newly selected chip).
  int _fetchSeq = 0;

  NavController? get _nav =>
      Get.isRegistered<NavController>() ? Get.find<NavController>() : null;

  @override
  void onInit() {
    super.onInit();
    // A category can be requested via route arguments, or by another tab
    // through NavController.openCategories() (before or after we exist)
    final args = Get.arguments is Map ? Get.arguments as Map : const {};
    String preselected = (args['categoryId'] as String?) ?? '';
    final nav = _nav;
    if (nav != null) {
      if (nav.pendingCategoryId != null) {
        preselected = nav.pendingCategoryId!;
        nav.pendingCategoryId = null;
      }
      nav.onCategoryRequested = selectCategory;
    }
    _initLocation(preselected: preselected);
  }

  @override
  void onClose() {
    final nav = _nav;
    if (nav != null && nav.onCategoryRequested == selectCategory) {
      nav.onCategoryRequested = null;
    }
    super.onClose();
  }

  Future<void> _initLocation({String preselected = ''}) async {
    final locResult = await LocationService.getLocation();
    if (locResult != null) {
      _lat = locResult.lat;
      _lng = locResult.lng;
      hasLocation.value = true;
    } else {
      // Without a saved location the list can't be "nearby"
      showAll.value = true;
    }
    fetchCategories(preselected: preselected);
  }

  /// Select a category chip (by id; '' = All) and load its products.
  void selectCategory(String categoryId) {
    if (!_categoriesLoaded) {
      // Applied when the category list arrives
      selectedCategoryId.value = categoryId;
      return;
    }
    fetchProducts(categoryId);
  }

  void toggleShowAll() {
    if (!hasLocation.value) return; // nothing "nearby" to switch back to
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
    } catch (_) {
      categories.value = [CategoryModel(id: '', name: 'All', image: null)];
    }
    _categoriesLoaded = true;
    // A selection made while loading wins over the initial one
    var target = selectedCategoryId.value.isNotEmpty
        ? selectedCategoryId.value
        : preselected;
    // Unknown id (e.g. deleted category) → fall back to All
    if (!categories.any((c) => c.id == target)) target = '';
    fetchProducts(target);
  }

  Future<void> fetchProducts(String categoryId) async {
    final seq = ++_fetchSeq;
    isLoading.value = true;
    selectedCategoryId.value = categoryId;
    final category = categoryId.isEmpty ? null : categoryId;
    List<ProductModel> result;
    double radius = 0;
    try {
      if (showAll.value || _lat == null || _lng == null) {
        // All merchants (no location filter; in-stock products only)
        final all = await _repo.getNearbyProducts(
          lat: 0,
          lng: 0,
          categoryId: category,
          allProducts: true,
          limit: 50,
        );
        result = all['products'] as List<ProductModel>;
      } else {
        final nearby = await _repo.getNearbyProducts(
          lat: _lat!,
          lng: _lng!,
          radius: selectedRadiusKm.value,
          categoryId: category,
        );
        result = nearby['products'] as List<ProductModel>;
        radius = nearby['actual_radius_km'] as double;
      }
    } catch (_) {
      result = [];
    }
    if (seq != _fetchSeq) return; // a newer selection is loading
    products.value = result;
    actualRadiusKm.value = radius;
    isLoading.value = false;
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    isLoading.value = true;
    searchQuery.value = query;
    try {
      products.value = await _repo.search(query);
    } catch (e) {
      GBSnack.fromError(e, title: 'Search');
    }
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
          IconButton(tooltip: 'Search', 
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
              border: Border(
                bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
              ),
            ),
            child: Obx(() {
              // Read the selection here, not inside itemBuilder: itemBuilder
              // runs later during layout, outside Obx's tracking, so the
              // highlighted chip never changed when a category was tapped.
              final selectedId = ctrl.selectedCategoryId.value;
              final cats = ctrl.categories.toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: cats.length,
                itemBuilder: (context, i) {
                  final cat = cats[i];
                  final isSelected = selectedId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Semantics(button: true, child: GestureDetector(
                      onTap: () => ctrl.selectCategory(cat.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          cat.name,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )),
                  );
                },
              );
            }),
          ),

          // Nearby radius indicator + Show All toggle (Always Visible)
          Obx(() {
            final isShowAll = ctrl.showAll.value;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isShowAll
                  ? AppColors.surface
                  : AppColors.primaryContainer.withValues(alpha: 0.3),
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
                      !ctrl.hasLocation.value
                          ? 'Showing all merchants (set your home location to see nearby)'
                          : isShowAll
                          ? 'Showing all merchants'
                          : 'Showing products within ${ctrl.actualRadiusKm.value.toStringAsFixed(0)} km',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (ctrl.hasLocation.value)
                    Semantics(button: true, child: GestureDetector(
                      onTap: () => ctrl.toggleShowAll(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isShowAll
                              ? AppColors.primary
                              : AppColors.surface,
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
                    )),
                  if (!isShowAll) ...[
                    const SizedBox(width: 8),
                    Semantics(button: true, child: GestureDetector(
                      onTap: () => _showRadiusPicker(context, ctrl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
                    )),
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
                        preparationOption: prepId,
                      ),
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
            const Text('Select Search Radius', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Only showing merchants within this distance from your location.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            Obx(
              () => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [5, 10, 20, 50, 100].map((r) {
                  final isSelected =
                      ctrl.selectedRadiusKm.value == r.toDouble();
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
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
