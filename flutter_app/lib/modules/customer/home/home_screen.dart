import '../nav_controller.dart';
import 'package:greenbasket_app/widgets/common/gb_card.dart';
import 'package:greenbasket_app/widgets/common/gb_gradient_header.dart';
import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../widgets/cards/product_card.dart';
import '../../../widgets/common/gb_loader.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/recipe_model.dart';
import 'home_controller.dart';
import '../cart/cart_controller.dart';
import '../profile/wishlist_controller.dart';
import '../../../utils/responsive_helper.dart';

part 'home_screen_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(HomeController());
    final cartCtrl = Get.find<CartController>();
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: ctrl.fetchData,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: _Header()),

              // Nearby Discovery & Distance Filter (Always Visible)
              SliverToBoxAdapter(
                child: Obx(() {
                  final isShowAll = ctrl.showAll.value;
                  // Always show the banner
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isShowAll
                          ? AppColors.surface
                          : AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isShowAll ? Icons.public : Icons.location_on,
                          size: 18,
                          color: AppColors.primaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isShowAll ? 'GLOBAL MODE' : 'NEARBY MODE',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                isShowAll
                                    ? 'Showing all available merchants'
                                    : 'Showing products within ${ctrl.actualRadiusKm.value.toStringAsFixed(1)} km',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isShowAll) ...[
                          Semantics(button: true, child: GestureDetector(
                            onTap: () =>
                                HomeScreen._showRadiusPicker(context, ctrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: GBCard.decoration().copyWith(border: Border.all(color: AppColors.divider)),
                              child: Row(
                                children: [
                                  Text(
                                    '${ctrl.selectedRadiusKm.value.toInt()}km',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down,
                                      size: 14),
                                ],
                              ),
                            ),
                          )),
                          const SizedBox(width: 8),
                        ],
                        Semantics(button: true, child: GestureDetector(
                          onTap: () => ctrl.toggleShowAll(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isShowAll
                                  ? AppColors.textPrimary
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isShowAll ? 'Nearby' : 'Show All',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  );
                }),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Semantics(button: true, child: GestureDetector(
                    onTap: () => Get.toNamed(Routes.search),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: GBCard.decoration(),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: AppColors.textHint, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Search for fresh produce...',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )),
                ),
              ),

              SliverToBoxAdapter(
                child: Obx(() => ctrl.isLoading.value
                    ? SizedBox(height: responsive.isTablet ? 250 : 180, child: GBLoader())
                    : _BannerSection(
                        offers: ctrl.availableOffers,
                        homeCtrl: ctrl,
                        height: responsive.isTablet ? 250 : 160,
                      )),
              ),

              // Categories
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Shop by Category',
                  onSeeAll: () => NavController.to.openCategories(),
                ),
              ),
              SliverToBoxAdapter(
                child: Obx(() => ctrl.isLoading.value
                    ? _CategoryShimmer()
                    : _CategoriesRow(categories: ctrl.categories)),
              ),

              // Featured products
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Featured Products',
                  onSeeAll: () => NavController.to.openCategories(),
                ),
              ),
              Obx(() => ctrl.isLoading.value
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: GBLoader(),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = ctrl.featuredProducts[index];
                            final wishlistCtrl = Get.find<WishlistController>();
                            return Obx(() => ProductCard(
                                  product: product,
                                  isInWishlist: wishlistCtrl.isWishlisted(product.id),
                                  onWishlistToggle: () => wishlistCtrl.toggleWishlist(product.id),
                                  onAddToCart: (prepId) => cartCtrl.addItem(
                                      productId: product.id,
                                      quantity: 1,
                                      preparationOption: prepId),
                                ));
                          },
                          childCount: ctrl.featuredProducts.length,
                        ),

                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: responsive.gridCrossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: responsive.productCardAspectRatio,
                        ),
                      ),
                    )),

              // Recipes section
              Obx(() {
                if (ctrl.recipes.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _SectionHeader(
                        title: 'Recipes & Meal Ideas',
                        onSeeAll: () => Get.toNamed(Routes.recipes),
                      ),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: ctrl.recipes.length,
                          itemBuilder: (_, i) {
                            final recipe = ctrl.recipes[i];
                            return _HomeRecipeCard(recipe: recipe);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  static void _showRadiusPicker(BuildContext context, HomeController ctrl) {
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
            Text(
              'Select Search Radius',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Only showing merchants within this distance from your location.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            Obx(() => Wrap(
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
                )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

