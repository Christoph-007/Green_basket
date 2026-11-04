import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';

class AdminRecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const AdminRecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final name = recipe['name']?.toString() ?? 'Recipe';
    final description = recipe['description']?.toString() ?? '';
    final imageUrl = recipe['image']?.toString();
    final category = recipe['category']?.toString() ?? 'General';
    final cuisine = recipe['cuisine']?.toString() ?? '';
    final difficulty = recipe['difficulty']?.toString() ?? '';
    final servings = recipe['servings'] ?? 0;
    final prepTime = recipe['prepTime'] ?? 0;
    final cookTime = recipe['cookTime'] ?? 0;
    final totalTime = recipe['totalTime'] ?? (prepTime + cookTime);
    final ingredients = (recipe['ingredients'] as List?) ?? [];
    final instructions = (recipe['instructions'] as List?) ?? [];
    final tags = (recipe['tags'] as List?) ?? [];
    final dietaryTags = (recipe['dietaryTags'] as List?) ?? [];
    final status = recipe['status']?.toString() ?? 'draft';
    final averageRating = (recipe['averageRating'] ?? 0).toDouble();
    final timesCooked = recipe['timesCooked'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Image AppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            leading: IconButton(tooltip: 'Back', 
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
              ),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null && imageUrl.startsWith('http')
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryContainer,
                            child: const Icon(Icons.restaurant_menu, size: 64, color: AppColors.primary),
                          ),
                        ),
                        // Gradient overlay
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                      ),
                      child: const Icon(Icons.restaurant_menu, size: 64, color: Colors.white),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Title + Status ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(name, style: AppTextStyles.headlineMedium),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status.toLowerCase() == 'published'
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: status.toLowerCase() == 'published'
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  // ─── Quick Info Chips ────────────────────────────────
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _infoChip(Icons.timer_outlined, '${totalTime}min total'),
                      if (prepTime > 0) _infoChip(Icons.hourglass_top, '${prepTime}min prep'),
                      if (cookTime > 0) _infoChip(Icons.local_fire_department_outlined, '${cookTime}min cook'),
                      _infoChip(Icons.people_outline, '$servings servings'),
                      if (difficulty.isNotEmpty)
                        _infoChip(Icons.signal_cellular_alt, '${difficulty[0].toUpperCase()}${difficulty.substring(1)}'),
                      if (category.isNotEmpty)
                        _infoChip(Icons.category_outlined, '${category[0].toUpperCase()}${category.substring(1)}'),
                      if (cuisine.isNotEmpty)
                        _infoChip(Icons.public, '${cuisine[0].toUpperCase()}${cuisine.substring(1)}'),
                    ],
                  ),

                  if (averageRating > 0 || timesCooked > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        if (averageRating > 0) ...[
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('$averageRating', style: AppTextStyles.bodySmall),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        if (timesCooked > 0) ...[
                          const Icon(Icons.restaurant_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('Cooked $timesCooked times', style: AppTextStyles.bodySmall),
                        ],
                      ],
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // ─── Ingredients Section ─────────────────────────────
                  _sectionHeader('Ingredients', Icons.local_grocery_store_outlined, '${ingredients.length} items'),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        children: ingredients.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final ing = entry.value as Map<String, dynamic>;
                          final ingName = ing['name']?.toString() ?? 'Unknown';
                          final quantity = ing['quantity'];
                          final unit = ing['unit']?.toString() ?? '';
                          final isOptional = ing['isOptional'] == true;
                          final hasProduct = ing['product'] != null;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: hasProduct
                                            ? AppColors.primary.withOpacity(0.1)
                                            : AppColors.background,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${idx + 1}',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: hasProduct ? AppColors.primary : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  ingName,
                                                  style: AppTextStyles.bodyMedium.copyWith(
                                                    fontStyle: isOptional ? FontStyle.italic : FontStyle.normal,
                                                  ),
                                                ),
                                              ),
                                              if (isOptional)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4),
                                                  child: Text(
                                                    '(optional)',
                                                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '$quantity $unit',
                                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                              if (idx < ingredients.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ─── Instructions Section ────────────────────────────
                  _sectionHeader('Instructions', Icons.list_alt_outlined, '${instructions.length} steps'),
                  const SizedBox(height: AppSpacing.sm),
                  ...instructions.map((step) {
                    final s = step as Map<String, dynamic>;
                    final stepNum = s['stepNumber'] ?? 0;
                    final instruction = s['instruction']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Center(
                              child: Text(
                                '$stepNum',
                                style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Text(instruction, style: AppTextStyles.bodyMedium),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // ─── Tags Section ────────────────────────────────────
                  if (tags.isNotEmpty || dietaryTags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _sectionHeader('Tags', Icons.sell_outlined, null),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ...dietaryTags.map((t) => Chip(
                          avatar: const Icon(Icons.eco, size: 16, color: AppColors.success),
                          label: Text(t.toString()),
                          backgroundColor: AppColors.success.withOpacity(0.1),
                          side: BorderSide.none,
                        )),
                        ...tags.map((t) => Chip(
                          label: Text(t.toString()),
                          backgroundColor: AppColors.primaryContainer,
                          side: BorderSide.none,
                        )),
                      ],
                    ),
                  ],

                  const SizedBox(height: 100), // space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, String? subtitle) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ],
    );
  }
}
