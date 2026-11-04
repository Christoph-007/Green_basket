import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../admin_controller.dart';
import 'create_category_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final controller = Get.find<AdminController>();

  void _showOptionsMenu(BuildContext context, Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(category['name']?.toString() ?? 'Category', style: AppTextStyles.titleLarge),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.info),
              title: const Text('Edit Category'),
              onTap: () {
                Navigator.pop(ctx);
                Get.to(() => CreateCategoryScreen(category: category));
              },
            ),
            ListTile(
              leading: Icon(
                (category['isActive'] ?? true) ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: AppColors.warning,
              ),
              title: Text((category['isActive'] ?? true) ? 'Deactivate' : 'Activate'),
              onTap: () {
                final id = category['_id']?.toString() ?? category['id']?.toString();
                if (id != null) {
                  final newStatus = !(category['isActive'] ?? true);
                  controller.toggleCategoryStatus(id, newStatus);
                }
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Category', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                final id = category['_id']?.toString() ?? category['id']?.toString();
                if (id != null) {
                  controller.deleteCategoryById(id);
                }
                Navigator.pop(ctx);
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
      appBar: GBAppBar(title: 'Categories', leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreateCategoryScreen()),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Category', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchCategories(),
        child: Obx(() {
          final categoryList = controller.categories;
          if (categoryList.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: categoryList.length,
            itemBuilder: (_, i) {
              final cat = categoryList[i] as Map<String, dynamic>;
              final icon = cat['icon']?.toString() ?? '🛒';
              final name = cat['name']?.toString() ?? 'N/A';
              final subCount = (cat['subCategories'] as List?)?.length ?? 0;
              final prodCount = cat['productsCount'] ?? 0;
              final isActive = (cat['isActive'] ?? true) as bool;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InkWell(
                  onLongPress: () => _showOptionsMenu(context, cat),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Center(
                            child: Text(icon, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppTextStyles.titleMedium),
                              Text(
                                '$subCount subcategories • $prodCount products',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (v) {
                            final id = cat['_id']?.toString() ?? cat['id']?.toString();
                            if (id != null) {
                              controller.toggleCategoryStatus(id, v);
                            }
                          },
                          activeColor: AppColors.primary,
                        ),
                        IconButton(tooltip: 'More options', 
                          icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                          onPressed: () => _showOptionsMenu(context, cat),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
