part of 'product_detail_screen.dart';

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

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, child: GestureDetector(
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
                        style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
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
                              GBSnack.plain('Not added', (result['message'] ?? 'No ingredients could be added').toString(), position: SnackPosition.BOTTOM);
                              return;
                            }
                            GBSnack.success(
                              'Added to Cart 🛒',
                              (result['message'] ?? '${recipe.title} ingredients added').toString(),
                              position: SnackPosition.BOTTOM,
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
                            GBSnack.error(
                              'Error',
                              'Could not add recipe to cart',
                              position: SnackPosition.BOTTOM,
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
    ));
  }
}
