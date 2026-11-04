import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../data/models/recipe_model.dart';
import '../../../widgets/common/gb_button.dart';
import '../../../widgets/cards/product_card.dart';
import '../../../widgets/common/gb_loader.dart';
import '../../../widgets/common/empty_state.dart';
import '../cart/cart_controller.dart';
import '../nav_controller.dart';
import '../profile/wishlist_controller.dart';
import '../../../utils/responsive_helper.dart';

class ProductDetailController extends GetxController {
  final _repo = ProductRepository();
  final _recipeRepo = RecipeRepository();
  final wishlistCtrl = Get.find<WishlistController>();
  
  final isLoading = false.obs;
  final product = Rxn<ProductModel>();
  final similarProducts = <ProductModel>[].obs;
  final recipes = <RecipeModel>[].obs;
  final selectedPreparationOption = Rxn<PreparationOption>();
  final quantity = 1.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final id = args['productId'] as String? ?? '';
    if (id.isNotEmpty) fetchProduct(id);
  }

  Future<void> fetchProduct(String id) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      product.value = await _repo.getProduct(id);
      if (product.value != null) {
        _fetchExtraData();
      }
    } catch (e) {
      errorMessage.value = e.toString().contains('404')
          ? 'Product not found'
          : (e.toString().contains('403')
              ? 'This product is currently restricted.'
              : 'Failed to load product details. Please try again.');
      debugPrint('[ProductDetailController] Fetch error: $e');
    }
    isLoading.value = false;
  }

  Future<void> _fetchExtraData() async {
    if (product.value == null) return;
    try {
      similarProducts.assignAll(
          await _repo.getSimilarProducts(product.value!.id, product.value!.categoryId));
      recipes.assignAll(await _recipeRepo.getRecipesByProductId(product.value!.id));
    } catch (e) {
      debugPrint('[ProductDetailController] Extra fetch error: $e');
    }
  }

  void incrementQty() => quantity.value++;
  void decrementQty() {
    if (quantity.value > 1) quantity.value--;
  }

  void selectPreparation(PreparationOption? option) {
    selectedPreparationOption.value = option;
  }

  Future<void> toggleWishlist() async {
    if (product.value == null) return;
    await wishlistCtrl.toggleWishlist(product.value!.id);
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ProductDetailController());
    final cartCtrl = Get.find<CartController>();
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBPageLoader();
        if (ctrl.product.value == null) {
          return ErrorState(
            message: ctrl.errorMessage.value.isNotEmpty 
                ? ctrl.errorMessage.value 
                : 'Product not found',
            onRetry: () {
              final args = Get.arguments as Map<String, dynamic>? ?? {};
              final id = args['productId'] as String? ?? '';
              if (id.isNotEmpty) ctrl.fetchProduct(id);
            },
          );
        }
        final product = ctrl.product.value!;
        final List<String> allImages = product.images.isNotEmpty 
            ? product.images 
            : (product.primaryImage.isNotEmpty ? [product.primaryImage] : []);
            
        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: responsive.isTablet ? 450 : 300,
                  pinned: true,
                  backgroundColor: AppColors.surface,
                  leading: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  actions: [
                    Obx(() {
                      final isWishlisted = ctrl.wishlistCtrl.isWishlisted(product.id);
                      return GestureDetector(
                        onTap: ctrl.toggleWishlist,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? AppColors.error : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                      );
                    }),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: allImages.isNotEmpty
                        ? PageView.builder(
                            itemCount: allImages.length,
                            itemBuilder: (_, i) => CachedNetworkImage(
                              imageUrl: allImages[i],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceVariant,
                                child: const GBShimmerBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  borderRadius: 0,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.primaryContainer,
                                child: const Icon(Icons.eco_outlined,
                                    size: 80, color: AppColors.primary),
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primaryContainer,
                            child: const Icon(Icons.eco_outlined,
                                size: 80, color: AppColors.primary),
                          ),
                  ),
                ),
                // Status banner for closed store
                if (!product.isStoreOpen)
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: AppColors.error,
                      child: const Center(
                        child: Text(
                          'THIS STORE IS CURRENTLY CLOSED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(product.name,
                                      style: AppTextStyles.headlineLarge),
                                ),
                                if (product.isOrganic)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text('Organic',
                                        style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.primary)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (product.tags.isNotEmpty) ...[
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: product.tags
                                    .map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.full),
                                          ),
                                          child: Text(
                                            '#$tag',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(fontSize: 11),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: product.rating,
                                  itemSize: 16,
                                  itemBuilder: (_, __) =>
                                      const Icon(Icons.star_rounded,
                                          color: AppColors.secondary),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront_outlined, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Sold by', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                                        Text(product.merchantName, style: AppTextStyles.titleMedium),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(product.merchantRating.toStringAsFixed(1), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Obx(() {
                              final p = ctrl.product.value!;
                              final addon = ctrl.selectedPreparationOption.value?.additionalPrice ?? 0;
                              final totalPrice = p.effectivePrice + addon;
                              return Row(
                                children: [
                                  Text(
                                    '₹${totalPrice.toStringAsFixed(0)}/${p.unit}',
                                    style: AppTextStyles.headlineLarge.copyWith(
                                        color: AppColors.primary),
                                  ),
                                  if (p.hasDiscount) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${(p.price + addon).toStringAsFixed(0)}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.full),
                                      ),
                                      child: Text(
                                        '${p.discountPercent}% OFF',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }),
                            const SizedBox(height: 4),
                            Text(
                              'by ${product.merchantName}',
                              style: AppTextStyles.bodySmall,
                            ),
                            if (product.preparationOptions.isNotEmpty) ...[
                              const Divider(height: 28),
                              Text('Preparation Options',
                                  style: AppTextStyles.titleLarge),
                              const SizedBox(height: 12),
                              Obx(() => Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: product.preparationOptions
                                        .map((opt) => GestureDetector(
                                              onTap: () =>
                                                  ctrl.selectPreparation(opt),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 150),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 14, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: ctrl.selectedPreparationOption
                                                              .value?.id ==
                                                          opt.id
                                                      ? AppColors.primary
                                                      : AppColors.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppRadius.full),
                                                  border: Border.all(
                                                    color: ctrl
                                                                .selectedPreparationOption
                                                                .value
                                                                ?.id ==
                                                            opt.id
                                                        ? AppColors.primary
                                                        : AppColors.border,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${opt.name}${opt.additionalPrice > 0 ? ' +₹${opt.additionalPrice.toInt()}' : ''}',
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                    color: ctrl
                                                                .selectedPreparationOption
                                                                .value
                                                                ?.id ==
                                                            opt.id
                                                        ? Colors.white
                                                        : AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  )),
                            ],
                            const Divider(height: 28),
                            Text('About this product',
                                style: AppTextStyles.titleLarge),
                            const SizedBox(height: 8),
                            Text(product.description,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary)),
                            if (product.origin != null) ...[
                              const Divider(height: 32),
                              Text('From the Farm', style: AppTextStyles.titleLarge),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                        Icons.landscape_outlined, 'Farm', product.origin?.farm ?? 'Local Farm'),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                        Icons.location_on_outlined, 'Location', product.origin?.location ?? 'Bangalore'),
                                    if (product.origin?.harvestDate != null) ...[
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                          Icons.calendar_month_outlined,
                                          'Harvested',
                                          DateFormat('MMM d, yyyy')
                                              .format(product.origin!.harvestDate!)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            if (product.nutritionalInfo != null) ...[
                              const Divider(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Nutrition Facts', style: AppTextStyles.titleLarge),
                                  Text('per 100g', 
                                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Column(
                                  children: [
                                    _buildNutritionRow('Calories', 
                                        '${product.nutritionalInfo?.calories?.toInt() ?? 0} kcal', isBold: true),
                                    const Divider(height: 1),
                                    _buildNutritionRow('Protein', 
                                        '${product.nutritionalInfo?.protein?.toStringAsFixed(1) ?? 0}g'),
                                    const Divider(height: 1),
                                    _buildNutritionRow('Carbohydrates', 
                                        '${product.nutritionalInfo?.carbohydrates?.toStringAsFixed(1) ?? 0}g'),
                                    const Divider(height: 1),
                                    _buildNutritionRow('Fat', 
                                        '${product.nutritionalInfo?.fat?.toStringAsFixed(1) ?? 0}g'),
                                    if (product.nutritionalInfo?.fiber != null) ...[
                                      const Divider(height: 1),
                                      _buildNutritionRow('Fiber', 
                                          '${product.nutritionalInfo?.fiber?.toStringAsFixed(1) ?? 0}g'),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            Obx(() {
                              if (ctrl.similarProducts.isEmpty) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 48),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Similar Products', style: AppTextStyles.titleLarge),
                                      TextButton(
                                        onPressed: () => NavController.to.openCategories(categoryId: product.categoryId),
                                        child: const Text('See All'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 260,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: ctrl.similarProducts.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final p = ctrl.similarProducts[index];
                                        final wishlistCtrl = Get.find<WishlistController>();
                                        return Obx(() => SizedBox(
                                              width: 170,
                                              child: ProductCard(
                                                product: p,
                                                isInWishlist: wishlistCtrl.isWishlisted(p.id),
                                                onWishlistToggle: () => wishlistCtrl.toggleWishlist(p.id),
                                                onAddToCart: (prepId) => cartCtrl.addItem(
                                                    productId: p.id,
                                                    quantity: 1,
                                                    preparationOption: prepId),
                                              ),
                                            ));
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }),
                            Obx(() {
                              if (ctrl.recipes.isEmpty) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 48),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Recipes with ${product.name}', style: AppTextStyles.titleLarge),
                                      TextButton(
                                        onPressed: () => Get.toNamed(Routes.recipes),
                                        child: const Text('Explore More'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: ctrl.recipes.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                                      itemBuilder: (context, index) {
                                        final recipe = ctrl.recipes[index];
                                        return _RecipeCard(recipe: recipe);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, -4),
                    )
                  ],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: ctrl.decrementQty,
                                  color: AppColors.textPrimary,
                                ),
                                Obx(() => Text(
                                      ctrl.quantity.value.toString(),
                                      style: AppTextStyles.titleLarge,
                                    )),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: ctrl.incrementQty,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GBButton(
                              label: product.isStoreOpen ? 'Add to Cart' : 'Store Closed',
                              onPressed: !product.isStoreOpen ? null : () {
                                if (product.preparationOptions.isNotEmpty && 
                                    ctrl.selectedPreparationOption.value == null) {
                                  Get.snackbar(
                                    'Select Option', 
                                    'Please select a preparation option',
                                    backgroundColor: AppColors.primaryContainer,
                                    colorText: AppColors.primary,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }
                                cartCtrl.addItem(
                                  productId: product.id,
                                  quantity: ctrl.quantity.value,
                                  preparationOption:
                                      ctrl.selectedPreparationOption.value?.id,
                                );
                              },
                              isFullWidth: true,
                              leadingIcon: Icons.shopping_cart_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        Text(value, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, 
              style: isBold ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700) : AppTextStyles.bodyMedium),
          Text(value, 
              style: isBold ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700) : AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.recipeDetail, arguments: {'recipeId': recipe.id}),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (recipe.image != null && recipe.image!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: recipe.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceVariant,
                        child: const GBShimmerBox(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 0,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primaryContainer,
                        child: const Icon(Icons.restaurant, color: AppColors.primary, size: 32),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.primaryContainer,
                      child: const Icon(Icons.restaurant, color: AppColors.primary, size: 32),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '${recipe.totalTime}m',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: AppTextStyles.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flash_on, size: 12, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          recipe.difficulty.capitalizeFirst ?? '',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          try {
                            final result = await RecipeRepository().addRecipeToCart(recipe.id);
                            if (Get.isRegistered<CartController>()) {
                              Get.find<CartController>().fetchCart();
                            }
                            final added = (result['data']?['stats']?['added'] ?? 0) as num;
                            if (added == 0) {
                              Get.snackbar('Not added',
                                  (result['message'] ?? 'No ingredients could be added').toString(),
                                  snackPosition: SnackPosition.BOTTOM);
                              return;
                            }
                            Get.snackbar(
                              'Added to Cart 🛒',
                              (result['message'] ?? '${recipe.title} ingredients added').toString(),
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.success,
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                            );
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (Get.isRegistered<NavController>()) {
                                Get.find<NavController>().toTab(3); // 3 is Cart tab
                              } else {
                                Get.toNamed('/customer/cart');
                              }
                            });
                          } catch (_) {
                            Get.snackbar(
                              'Error',
                              'Could not add recipe to cart',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.error,
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(16),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Icon(Icons.add_shopping_cart, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
