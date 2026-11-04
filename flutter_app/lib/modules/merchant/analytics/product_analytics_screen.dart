import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'merchant_analytics_controller.dart';

class MerchantProductAnalyticsScreen extends StatelessWidget {
  const MerchantProductAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MerchantAnalyticsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Product Analytics', backIcon: Icons.arrow_back_ios_new, showDivider: false),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInventorySummary(controller),
              const SizedBox(height: AppSpacing.lg),
              Text('Top Selling Products', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.md),
              if (controller.topProducts.isEmpty)
                _buildEmptyState('No sales data yet')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.topProducts.length,
                  itemBuilder: (context, index) {
                    final item = controller.topProducts[index];
                    return _buildProductPerformanceCard(item, index + 1);
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInventorySummary(MerchantAnalyticsController controller) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inventory Insights', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSimpleStat('Total Products', '${controller.totalProducts.value}', Icons.inventory_2, AppColors.primary),
              _buildSimpleStat('Low Stock', '${controller.lowStockCount.value}', Icons.warning_amber, AppColors.warning),
              _buildSimpleStat('Out of Stock', '${controller.outOfStockCount.value}', Icons.error_outline, AppColors.error),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Inventory Value', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              Text(AppHelpers.formatCurrency(controller.inventoryValue.value),
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceCard(Map<String, dynamic> data, int rank) {
    final product = data['product'] ?? {};
    final totalSold = data['totalSold'] ?? 0;
    final revenue = (data['revenue'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppColors.primary : AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: Text('$rank', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: AppSpacing.md),
          // Product Image
          if (product['primaryImage'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                product['primaryImage'],
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: AppColors.divider),
              ),
            )
          else
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? 'Unknown Product', style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$totalSold sales · ${AppHelpers.formatCurrency(revenue)} revenue',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Sentiment/Rating
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text('${product['averageRating'] ?? 0.0}', style: AppTextStyles.labelSmall),
                ],
              ),
              const SizedBox(height: 4),
              Text('Stock: ${product['stock'] ?? 0}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: (product['stock'] ?? 0) <= 10 ? AppColors.error : AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart, size: 48, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
