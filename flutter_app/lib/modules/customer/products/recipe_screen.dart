import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/config/routes.dart';
import 'package:greenbasket_app/data/models/recipe_model.dart';
import 'package:greenbasket_app/data/repositories/recipe_repository.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';

import 'package:greenbasket_app/modules/customer/home/home_controller.dart';

class RecipeController extends GetxController {
  final _repo = RecipeRepository();
  final recipes = <RecipeModel>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedCategory = 'All'.obs;

  final List<String> categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
  ];

  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    fetchRecipes();
    // The meal chips are filtered by the server, so reload whenever one is picked.
    ever(selectedCategory, (_) => fetchRecipes());
  }

  Future<void> fetchRecipes() async {
    final requestId = ++_requestId;
    isLoading.value = true;
    try {
      double? lat, lng, radius;
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        lat = home.latitude;
        lng = home.longitude;
        radius = home.selectedRadiusKm.value;
      }
      final result = await _repo.getRecipes(
        limit: 50,
        mealType: selectedCategory.value,
        lat: lat,
        lng: lng,
        radius: radius,
      );
      // Ignore the answer if another chip was tapped while this one was loading.
      if (requestId == _requestId) recipes.value = result;
    } catch (_) {
      // keep whatever is showing
    }
    if (requestId == _requestId) isLoading.value = false;
  }

  /// The meal filter is applied by the server; only the search box filters here.
  List<RecipeModel> get filteredRecipes {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return recipes.toList();
    return recipes.where((r) => r.title.toLowerCase().contains(query)).toList();
  }
}

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(RecipeController());
    final searchCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Recipes & Meal Ideas', backIcon: Icons.arrow_back_ios_new_rounded),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              controller: searchCtrl,
              onChanged: (v) => ctrl.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.textHint),
                suffixIcon: Obx(() => ctrl.searchQuery.value.isNotEmpty
                    ? IconButton(tooltip: 'Clear', 
                        icon: Icon(Icons.clear_rounded,
                            color: AppColors.textHint, size: 18),
                        onPressed: () {
                          searchCtrl.clear();
                          ctrl.searchQuery.value = '';
                        },
                      )
                    : const SizedBox.shrink()),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          Container(
            color: AppColors.surface,
            height: 52,
            child: Obx(() {
              // Access observable outside itemBuilder to ensure Obx tracks it
              final selectedCat = ctrl.selectedCategory.value;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                itemCount: ctrl.categories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final cat = ctrl.categories[i];
                  final isSelected = selectedCat == cat;
                  return Semantics(button: true, child: GestureDetector(
                    onTap: () => ctrl.selectedCategory.value = cat,
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ));
                },
              );
            }),
          ),
          const Divider(height: 1),

          // Recipe grid
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) return const GBLoader();
              
              final recipes = ctrl.filteredRecipes;
              
              if (recipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu_rounded,
                          color: AppColors.textHint, size: 64),
                      const SizedBox(height: AppSpacing.md),
                      Text('No recipes found',
                          style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
              
              return GridView.builder(
                padding:
                    const EdgeInsets.all(AppSpacing.screenPadding),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.75,
                ),
                itemCount: recipes.length,
                itemBuilder: (_, i) =>
                    _RecipeCard(recipe: recipes[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  const _RecipeCard({required this.recipe});

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
    return Semantics(button: true, child: GestureDetector(
      onTap: () => Get.toNamed(
        Routes.recipeDetail,
        arguments: {'recipeId': recipe.id},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadowFaint,
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            recipe.image != null
                ? CachedNetworkImage(
                    imageUrl: recipe.image!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 120,
                      color: AppColors.primaryContainer,
                      child: Icon(Icons.restaurant_rounded, color: AppColors.primaryText),
                    ),
                  )
                : Container(
                    height: 120,
                    color: AppColors.primaryContainer,
                    child: Center(
                      child: Icon(Icons.restaurant_rounded, color: AppColors.primaryText, size: 40),
                    ),
                  ),
            
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: AppTextStyles.titleMedium
                          .copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        // Meal timing badge
                        if (recipe.displayMealType.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              recipe.displayMealType.toUpperCase(),
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        // Difficulty badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _difficultyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppRadius.full),
                          ),
                          child: Text(
                            recipe.difficulty.toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _difficultyColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (recipe.distance != null) ...[
                          Icon(
                            recipe.isNearby == false ? Icons.location_off : Icons.location_on,
                            size: 10,
                            color: recipe.isNearby == false ? AppColors.error : AppColors.textHint,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${recipe.distance}km',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: recipe.isNearby == false ? AppColors.error : AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Time
                        Icon(Icons.access_time_rounded,
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
    ));
  }
}
