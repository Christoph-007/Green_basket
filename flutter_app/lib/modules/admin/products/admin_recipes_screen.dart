import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/admin_repository.dart';
import '../admin_controller.dart';
import 'create_recipe_screen.dart';
import 'admin_recipe_detail_screen.dart';

class AdminRecipesScreen extends StatefulWidget {
  const AdminRecipesScreen({super.key});

  @override
  State<AdminRecipesScreen> createState() => _AdminRecipesScreenState();
}

class _AdminRecipesScreenState extends State<AdminRecipesScreen> {
  final controller = Get.find<AdminController>();
  final _repo = AdminRepository();
  final _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    return status.toLowerCase() == 'published' ? AppColors.success : AppColors.textSecondary;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _recipeId(Map<String, dynamic> recipe) =>
      (recipe['_id'] ?? recipe['id'] ?? '').toString();

  Future<void> _toggleStatus(Map<String, dynamic> recipe) async {
    final id = _recipeId(recipe);
    if (id.isEmpty) return;
    final publishing = recipe['status']?.toString().toLowerCase() != 'published';
    try {
      await _repo.updateRecipe(id, {'status': publishing ? 'published' : 'draft'});
      await controller.fetchRecipes();
      GBSnack.success(publishing ? 'Published' : 'Unpublished', publishing
            ? '${recipe['name']} is now visible to customers.'
            : '${recipe['name']} is now hidden from customers.');
    } catch (_) {
      GBSnack.error('Error', 'Could not update the recipe. Please try again.');
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> recipe) async {
    final id = _recipeId(recipe);
    if (id.isEmpty) return;
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('Delete recipe?'),
      content: Text('"${recipe['name']}" will be removed for everyone. This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
    if (confirmed != true) return;
    try {
      await _repo.deleteRecipe(id);
      await controller.fetchRecipes();
      GBSnack.success('Deleted', '${recipe['name']} was deleted.');
    } catch (_) {
      GBSnack.error('Error', 'Could not delete the recipe. Please try again.');
    }
  }

  void _showRecipeOptions(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(recipe['name']?.toString() ?? 'Recipe', style: AppTextStyles.titleLarge),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.info),
              title: const Text('Edit Recipe'),
              onTap: () {
                Navigator.pop(ctx);
                Get.to(() => CreateRecipeScreen(recipe: recipe));
              },
            ),
            ListTile(
              leading: Icon(
                recipe['status']?.toString().toLowerCase() == 'published' ? Icons.unpublished_outlined : Icons.publish,
                color: AppColors.warning,
              ),
              title: Text(recipe['status']?.toString().toLowerCase() == 'published' ? 'Unpublish' : 'Publish'),
              onTap: () {
                Navigator.pop(ctx);
                _toggleStatus(recipe);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Recipe', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(recipe);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recipes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreateRecipeScreen()),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Recipe', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _searchQuery.value = v,
              decoration: const InputDecoration(
                hintText: 'Search recipes or authors...',
                prefixIcon: Icon(Icons.search, color: AppColors.textHint),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final recipeList = controller.recipes.where((r) {
                final recipe = r as Map<String, dynamic>;
                final name = recipe['name']?.toString().toLowerCase() ?? '';
                final category = recipe['category']?.toString().toLowerCase() ?? '';
                final cuisine = recipe['cuisine']?.toString().toLowerCase() ?? '';
                final query = _searchQuery.value.toLowerCase();
                return name.contains(query) || category.contains(query) || cuisine.contains(query);
              }).toList();

              if (recipeList.isEmpty) {
                return const Center(child: Text('No recipes found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: recipeList.length,
                itemBuilder: (_, i) => _buildRecipeCard(recipeList[i] as Map<String, dynamic>),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final status = recipe['status']?.toString() ?? 'Draft';
    final displayStatus = status[0].toUpperCase() + status.substring(1);
    final name = recipe['name']?.toString() ?? 'N/A';
    // createdBy is { userType: 'admin' } or may have a 'name' field
    final createdBy = recipe['createdBy'];
    final authorName = createdBy is Map
        ? (createdBy['name']?.toString() ?? createdBy['userType']?.toString() ?? 'Admin')
        : 'Admin';
    final authorDisplay = authorName[0].toUpperCase() + authorName.substring(1);
    // category is a plain string like 'breakfast', 'lunch', etc.
    final category = recipe['category']?.toString() ?? 'General';
    final categoryDisplay = category[0].toUpperCase() + category.substring(1);
    final ingredientsCount = (recipe['ingredients'] as List?)?.length ?? 0;
    final imageUrl = recipe['image']?.toString();
    final prepTime = _parseInt(recipe['prepTime']);
    final cookTime = _parseInt(recipe['cookTime']);
    final totalTime = recipe['totalTime'] != null ? _parseInt(recipe['totalTime']) : prepTime + cookTime;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => Get.to(() => AdminRecipeDetailScreen(recipe: recipe)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: imageUrl == null || !imageUrl.startsWith('http')
                    ? LinearGradient(
                        colors: [AppColors.primaryContainer, AppColors.primaryLight.withOpacity(0.3)],
                      )
                    : null,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  image: imageUrl != null && imageUrl.startsWith('http')
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: imageUrl == null || !imageUrl.startsWith('http')
                  ? const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 32)
                  : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: AppTextStyles.titleMedium)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            displayStatus,
                            style: AppTextStyles.labelSmall.copyWith(color: _statusColor(status)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('By $authorDisplay', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            categoryDisplay,
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_grocery_store_outlined, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text('$ingredientsCount items', style: AppTextStyles.bodySmall),
                          ],
                        ),
                        if (totalTime > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 2),
                              Text('${totalTime}min', style: AppTextStyles.bodySmall),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onPressed: () => _showRecipeOptions(recipe),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
