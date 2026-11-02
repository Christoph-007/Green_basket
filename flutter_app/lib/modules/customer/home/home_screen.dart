import 'package:flutter/material.dart';
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
                          : AppColors.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isShowAll ? Icons.public : Icons.location_on,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isShowAll ? 'GLOBAL MODE' : 'NEARBY MODE',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
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
                          GestureDetector(
                            onTap: () =>
                                HomeScreen._showRadiusPicker(context, ctrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.divider),
                              ),
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
                          ),
                          const SizedBox(width: 8),
                        ],
                        GestureDetector(
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
                        ),
                      ],
                    ),
                  );
                }),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: GestureDetector(
                    onTap: () => Get.toNamed(Routes.search),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: AppColors.textHint, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Search for fresh produce...',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                  onSeeAll: () => Get.toNamed(Routes.categories),
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
                  onSeeAll: () => Get.toNamed(Routes.categories),
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


class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning! 👋',
                  style: AppTextStyles.bodySmall),
              SizedBox(height: 2),
              Text('What are you looking for?',
                  style: AppTextStyles.headlineMedium),
            ],
          ),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.textPrimary,
                onPressed: () => Get.toNamed('/customer/notifications'),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerSection extends StatefulWidget {
  final List<Map<String, dynamic>> offers;
  final HomeController homeCtrl;
  final double height;

  const _BannerSection({
    required this.offers,
    required this.homeCtrl,
    this.height = 160,
  });

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // Placeholder gradient banners until API banners are loaded
  final _bannerColors = [
    [AppColors.primary, AppColors.primaryDark],
    [AppColors.secondary, AppColors.secondaryDark],
    [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
    [const Color(0xFFE53935), const Color(0xFFD32F2F)],
  ];

  String _getOfferTitle(Map<String, dynamic> offer) {
    final type = offer['type'] ?? '';
    final title = offer['title'] ?? '';
    if (title.isNotEmpty) return title;

    if (type == 'percentage') {
      return '${offer['discountPercentage']}% OFF on your order';
    } else if (type == 'flat') {
      return 'Flat ₹${offer['discountAmount']} OFF';
    }
    return 'Special Offer';
  }

  String _getOfferSubtitle(Map<String, dynamic> offer) {
    final code = offer['couponCode'] ?? '';
    if (code.isNotEmpty) return 'Use code: $code';
    final minOrder = offer['minOrderValue'] ?? 0;
    if (minOrder > 0) return 'Min order ₹$minOrder';
    return 'Limited time only';
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsCount = widget.offers.isEmpty ? 3 : widget.offers.length;

    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: itemsCount,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final colors = _bannerColors[i % _bannerColors.length];
              String title;
              String subtitle;
              String buttonText = 'Shop Now';

              if (widget.offers.isEmpty) {
                final staticTitles = [
                  'Fresh Organic Produce\nDelivered Daily',
                  'Huge Savings on\nSelected Items',
                  'New Recipes Added\nCook Something Amazing',
                ];
                title = staticTitles[i % staticTitles.length];
                subtitle = 'Discover our collection';
              } else {
                final offer = widget.offers[i];
                title = _getOfferTitle(offer);
                subtitle = _getOfferSubtitle(offer);
                buttonText = offer['couponCode'] != null ? 'Copy Code' : 'Claim Now';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    if (widget.offers.isNotEmpty) {
                      final offer = widget.offers[i];
                      final code = offer['couponCode'];
                      if (code != null && code.toString().isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: code));
                        Get.snackbar(
                          'Success',
                          'Coupon code "$code" copied to clipboard',
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                buttonText,
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: colors[0]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.offers.isNotEmpty && widget.offers[i]['isFlashSale'] == true)
                        const Expanded(
                          flex: 1,
                          child: Icon(Icons.flash_on,
                              color: Colors.white, size: 48),
                        ),
                    ],
                  ),
                ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            itemsCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentPage ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headlineMedium),
            ],
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See All',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  final List<CategoryModel> categories;
  const _CategoriesRow({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox(height: 80);
    }
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          return GestureDetector(
            onTap: () =>
                Get.toNamed(Routes.categories, arguments: {'categoryId': cat.id}),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: cat.image != null && cat.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: cat.image!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Icon(
                                Icons.eco_outlined,
                                color: AppColors.primary),
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.eco_outlined,
                                color: AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.eco_outlined,
                          color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  cat.name,
                  style: AppTextStyles.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 6,
        itemBuilder: (_, __) => const Column(
          children: [
            GBShimmerBox(width: 60, height: 60, borderRadius: 16),
            SizedBox(height: 6),
            GBShimmerBox(width: 50, height: 10),
          ],
        ),
      ),
    );
  }
}

class _HomeRecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  const _HomeRecipeCard({required this.recipe});

  Color get _difficultyColor {
    switch (recipe.difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.recipeDetail,
        arguments: {'recipeId': recipe.id},
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            recipe.image != null
                ? CachedNetworkImage(
                    imageUrl: recipe.image!,
                    height: 110,
                    width: 160,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 110,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 110,
                      color: AppColors.primaryContainer,
                      child: const Icon(Icons.restaurant_rounded,
                          color: AppColors.primary, size: 32),
                    ),
                  )
                : Container(
                    height: 110,
                    color: AppColors.primaryContainer,
                    child: const Center(
                      child: Icon(Icons.restaurant_rounded,
                          color: AppColors.primary, size: 32),
                    ),
                  ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _difficultyColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            recipe.difficulty.toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _difficultyColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.access_time_rounded,
                            size: 10, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          '${recipe.totalTime}m',
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
