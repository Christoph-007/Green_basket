import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/models/recipe_model.dart';
import 'package:greenbasket_app/data/repositories/recipe_repository.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';
import 'package:greenbasket_app/modules/customer/cart/cart_controller.dart';
import 'package:greenbasket_app/modules/customer/nav_controller.dart';
import 'package:greenbasket_app/modules/customer/home/home_controller.dart';

class RecipeDetailController extends GetxController {
  final _repo = RecipeRepository();
  final recipe = Rxn<RecipeModel>();
  final isLoading = false.obs;
  final isAddingToCart = false.obs;
  final servings = 2.obs;

  final ingredientDetails = <Map<String, dynamic>>[].obs;
  final totalPrice = 0.0.obs;
  final availableCount = 0.obs;
  final totalCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final recipeId = Get.arguments?['recipeId'] ?? '';
    if (recipeId.isNotEmpty) {
      fetchRecipeDetail(recipeId);
    }
  }

  Future<void> fetchRecipeDetail(String id) async {
    isLoading.value = true;
    try {
      recipe.value = await _repo.getRecipeById(id);
      if (recipe.value != null) {
        servings.value = recipe.value!.servings;
        await _fetchIngredientDetails(id);
      }
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> _fetchIngredientDetails(String id) async {
    try {
      double? lat;
      double? lng;
      double? radius;

      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        lat = home.latitude;
        lng = home.longitude;
        radius = home.selectedRadiusKm.value;
      }

      final result = await _repo.calculateIngredients(
        id, 
        servings: servings.value,
        lat: lat,
        lng: lng,
        radius: radius,
      );
      
      final data = result['data'] ?? result;
      ingredientDetails.value = List<Map<String, dynamic>>.from(data['ingredients'] ?? []);
      totalPrice.value = (data['totalPrice'] ?? 0).toDouble();
      availableCount.value = data['availableItemsCount'] ?? 0;
      totalCount.value = data['totalItemsCount'] ?? 0;
    } catch (e) {
      debugPrint('Error fetching ingredient details: $e');
    }
  }

  void incrementServings() {
    servings.value++;
    if (recipe.value != null) _fetchIngredientDetails(recipe.value!.id);
  }

  void decrementServings() {
    if (servings.value > 1) {
      servings.value--;
      if (recipe.value != null) _fetchIngredientDetails(recipe.value!.id);
    }
  }

  Future<void> addAllToCart() async {
    if (recipe.value == null) return;
    isAddingToCart.value = true;
    try {
      double? lat;
      double? lng;
      double? radius;

      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        lat = home.latitude;
        lng = home.longitude;
        radius = home.selectedRadiusKm.value;
      }

      final result = await _repo.addRecipeToCart(
        recipe.value!.id, 
        servings: servings.value,
        lat: lat,
        lng: lng,
        radius: radius,
      );

      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().fetchCart();
      }
      
      final stats = result['data']?['stats'];
      final addedCount = stats?['added'] ?? 0;
      final skippedDist = stats?['skipped_distance'] ?? 0;
      final skippedStock = stats?['skipped_stock'] ?? 0;

      final skippedOtherStore = stats?['skipped_other_store'] ?? 0;
      String message = (result['message'] ?? '$addedCount items added to cart.').toString();
      if (skippedDist > 0 || skippedStock > 0 || skippedOtherStore > 0) {
        message += '\n($skippedDist too far, $skippedStock out of stock, $skippedOtherStore from another store)';
      }

      Get.snackbar(
        addedCount > 0 ? 'Added to Cart 🛒' : 'No items added',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: addedCount > 0 ? AppColors.success : AppColors.warning,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );

      // Use NavController to switch to Cart Tab
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.isRegistered<NavController>()) {
          Get.find<NavController>().toTab(3); // 3 is Cart tab
        } else {
          Get.toNamed('/customer/cart');
        }
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not add ingredients to cart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
    isAddingToCart.value = false;
  }

  double get multiplier => servings.value / (recipe.value?.servings ?? 1);

  String scaleQty(double baseQty) {
    final scaled = baseQty * multiplier;
    if (scaled == scaled.roundToDouble()) return scaled.toInt().toString();
    return scaled.toStringAsFixed(1);
  }
}

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(RecipeDetailController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBLoader();

        final recipe = ctrl.recipe.value;
        if (recipe == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text('Recipe not found', style: AppTextStyles.titleLarge),
                TextButton(onPressed: () => Get.back(), child: const Text('Go Back')),
              ],
            ),
          );
        }

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  backgroundColor: AppColors.surface,
                  leading: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: recipe.image != null
                        ? CachedNetworkImage(
                            imageUrl: recipe.image!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primary, AppColors.secondary],
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.restaurant_rounded, color: Colors.white38, size: 80),
                            ),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.title, style: AppTextStyles.displayMedium),
                        if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(recipe.description!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: AppSpacing.sm),

                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            if (recipe.displayMealType.isNotEmpty)
                              _MetaChip(icon: Icons.restaurant_menu_rounded, label: recipe.displayMealType, color: AppColors.primary),
                            _MetaChip(icon: Icons.access_time_rounded, label: '${recipe.totalTime} min', color: AppColors.primary),
                            _MetaChip(icon: Icons.bar_chart_rounded, label: recipe.difficulty, color: _getDifficultyColor(recipe.difficulty)),
                            _MetaChip(icon: Icons.people_outline_rounded, label: '${ctrl.servings.value} servings', color: AppColors.secondary),
                            _MetaChip(icon: Icons.eco_outlined, label: '${recipe.ingredients.length} ingredients', color: AppColors.textSecondary),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Servings control
                        Row(
                          children: [
                            const Expanded(child: Text('Ingredients', style: AppTextStyles.titleLarge)),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _StepperButton(icon: Icons.remove_rounded, onTap: () => ctrl.decrementServings()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                    child: Text('${ctrl.servings.value}', style: AppTextStyles.titleMedium),
                                  ),
                                  _StepperButton(icon: Icons.add_rounded, onTap: () => ctrl.incrementServings()),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'For ${ctrl.servings.value} serving${ctrl.servings.value > 1 ? 's' : ''}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Ingredient list with availability
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: ctrl.ingredientDetails.isNotEmpty
                              ? Column(
                                  children: List.generate(ctrl.ingredientDetails.length, (i) {
                                    final ing = ctrl.ingredientDetails[i];
                                    final isLast = i == ctrl.ingredientDetails.length - 1;
                                    final isAvailable = ing['isAvailable'] == true;
                                    final product = ing['product'];
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: isAvailable ? AppColors.primary : AppColors.error,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(ing['name'] ?? '', style: AppTextStyles.bodyMedium),
                                                    if (!isAvailable)
                                                      Text(
                                                        ing['rangeMessage'] ?? (product != null ? 'Out of stock' : 'Not linked to product'),
                                                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
                                                      ),
                                                    if (isAvailable && product != null)
                                                      Row(
                                                        children: [
                                                          Text(
                                                            '₹${product['price']}/${ing['unit'] ?? ''}',
                                                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                                                          ),
                                                          if (product['distance'] != null) ...[
                                                            const SizedBox(width: 4),
                                                            const Text('•', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              '${product['distance']}km away',
                                                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '${_formatQty(ing['quantity'])} ${ing['unit'] ?? ''}',
                                                style: AppTextStyles.titleMedium.copyWith(
                                                  color: isAvailable ? AppColors.primary : AppColors.textHint,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!isLast) const Divider(height: 1),
                                      ],
                                    );
                                  }),
                                )
                              : Column(
                                  children: List.generate(recipe.ingredients.length, (i) {
                                    final ing = recipe.ingredients[i];
                                    final isLast = i == recipe.ingredients.length - 1;
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8, height: 8,
                                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              Expanded(child: Text(ing.name, style: AppTextStyles.bodyMedium)),
                                              Text(
                                                '${ctrl.scaleQty(ing.quantity)} ${ing.unit}',
                                                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!isLast) const Divider(height: 1),
                                      ],
                                    );
                                  }),
                                ),
                        ),

                        // Availability summary
                        if (ctrl.ingredientDetails.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: ctrl.availableCount.value == ctrl.totalCount.value
                                  ? AppColors.success.withOpacity(0.08)
                                  : AppColors.warning.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  ctrl.availableCount.value == ctrl.totalCount.value
                                      ? Icons.check_circle_outline : Icons.info_outline,
                                  size: 16,
                                  color: ctrl.availableCount.value == ctrl.totalCount.value
                                      ? AppColors.success : AppColors.warning,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${ctrl.availableCount.value} of ${ctrl.totalCount.value} ingredients available • Est. ₹${ctrl.totalPrice.value.toStringAsFixed(0)}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: ctrl.availableCount.value == ctrl.totalCount.value
                                          ? AppColors.success : AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),

                        const Text('Instructions', style: AppTextStyles.titleLarge),
                        const SizedBox(height: AppSpacing.sm),
                        ...List.generate(recipe.steps.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text('${i + 1}', style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily, fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                                  )),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(recipe.steps[i], style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 28),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, -2))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: ctrl.isAddingToCart.value ? null : () => ctrl.addAllToCart(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    icon: ctrl.isAddingToCart.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.shopping_cart_rounded, size: 20),
                    label: Text(ctrl.isAddingToCart.value
                        ? 'Adding...'
                        : 'Add ${ctrl.availableCount.value} Items to Cart • ₹${ctrl.totalPrice.value.toStringAsFixed(0)}'),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatQty(dynamic qty) {
    if (qty == null) return '0';
    final d = (qty is num) ? qty.toDouble() : double.tryParse(qty.toString()) ?? 0;
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(1);
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return AppColors.success;
      case 'hard': return AppColors.error;
      default: return AppColors.warning;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            fontFamily: AppTextStyles.fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: color,
          )),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }
}
