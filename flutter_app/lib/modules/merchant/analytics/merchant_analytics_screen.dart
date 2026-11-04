import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'merchant_analytics_controller.dart';
import 'product_analytics_screen.dart';
import '../financial/financial_screen.dart';
import '../financial/payouts_screen.dart';
import '../offers/offer_performance_list_screen.dart';
import '../widgets/merchant_drawer.dart';
import 'merchant_reviews_screen.dart';

part 'merchant_analytics_screen_sections.dart';

class MerchantAnalyticsScreen extends StatelessWidget {
  const MerchantAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MerchantAnalyticsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Performance Analytics', leading: Builder(builder: (context) {
          return IconButton(tooltip: 'Open menu', 
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }), backgroundColor: Colors.white),
      drawer: const MerchantDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchAnalytics(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Revenue Overview Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("This Month's Overview",
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                              AppHelpers.formatCurrency(
                                  controller.totalRevenue.value),
                              style: AppTextStyles.headlineLarge
                                  .copyWith(color: AppColors.primary, fontSize: 32)),
                          const SizedBox(width: 8),
                          if (controller.revenueGrowth.value != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: controller.revenueGrowth.value > 0
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    controller.revenueGrowth.value > 0
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    size: 14,
                                    color: controller.revenueGrowth.value > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${controller.revenueGrowth.value.abs().toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: controller.revenueGrowth.value > 0
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildQuickStat(
                              'Total Orders',
                              '${controller.totalOrders.value}',
                              Icons.shopping_bag_outlined,
                              AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Container(height: 40, width: 1, color: AppColors.border),
                          const SizedBox(width: AppSpacing.sm),
                          _buildQuickStat(
                              'Products',
                              '${controller.totalProducts.value}',
                              Icons.inventory_2_outlined,
                              Colors.blue),
                          const SizedBox(width: AppSpacing.sm),
                          Container(height: 40, width: 1, color: AppColors.border),
                          const SizedBox(width: AppSpacing.sm),
                          _buildQuickStat(
                              'Store Rating',
                              '${controller.averageRating.value.toStringAsFixed(1)} ★',
                              Icons.star_outline_rounded,
                              Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Revenue Trend Chart ──
                _buildRevenueChart(controller),

                // ── Quick Stats Row ──
                Padding(

                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _miniStatCard(
                          'Avg. Order',
                          AppHelpers.formatCurrency(
                              controller.avgOrderValue.value),
                          Icons.receipt_long,
                          AppColors.info,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _miniStatCard(
                          'Pending',
                          '${controller.pendingOrders.value}',
                          Icons.hourglass_empty,
                          AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _miniStatCard(
                          'Delivered',
                          '${controller.deliveredOrders.value}',
                          Icons.check_circle_outline,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Top Selling Products ──
                if (controller.topProducts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.trending_up,
                                      size: 18, color: AppColors.success),
                                  const SizedBox(width: 6),
                                  Text('Top Selling Products',
                                      style: AppTextStyles.titleMedium),
                                ],
                              ),
                              Semantics(button: true, child: GestureDetector(
                                onTap: () => Get.to(
                                    () => const MerchantProductAnalyticsScreen()),
                                child: Text('See All',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.primary)),
                              )),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...controller.topProducts.take(3).toList().asMap().entries.map((e) {
                            final i = e.key;
                            final item = e.value;
                            final product =
                                item['product'] as Map<String, dynamic>? ?? {};
                            final name = product['name'] ?? 'Unknown';
                            final totalSold = item['totalSold'] ?? 0;
                            final revenue =
                                (item['revenue'] ?? 0).toDouble();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: i == 0
                                          ? Colors.amber
                                          : i == 1
                                              ? Colors.grey.shade400
                                              : Colors.brown.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text('${i + 1}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        Text('$totalSold units sold',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                    color: AppColors
                                                        .textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Text(AppHelpers.formatCurrency(revenue),
                                      style: AppTextStyles.titleMedium
                                          .copyWith(color: AppColors.success)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),

                // ── Customer Reviews Preview ──
                if (controller.recentReviews.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.rate_review_outlined,
                                      size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text('Recent Reviews',
                                      style: AppTextStyles.titleMedium),
                                ],
                              ),
                              Text('${controller.totalReviews.value} total',
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...controller.recentReviews.take(2).map((r) {
                            final customer = r['customer'] as Map? ?? {};
                            final name = customer['name'] ?? 'Customer';
                            final rating = (r['rating'] as num?)?.toInt() ?? 0;
                            final comment = r['comment'] ?? '';
                            final dateStr = r['createdAt'] ?? '';
                            final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ...List.generate(5, (star) => Icon(
                                        star < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                        size: 14,
                                        color: Colors.amber,
                                      )),
                                      const SizedBox(width: 8),
                                      Text(name, style: AppTextStyles.labelLarge),
                                      const Spacer(),
                                      Text(AppHelpers.formatDateTime(date), style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (comment.isNotEmpty)
                                    Text(comment, 
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const Divider(),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),

                // ── Detailed Reports Section ──
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Text('Detailed Reports', style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.md),
                      _analyticsCard(
                        context,
                        'Store Reviews',
                        'Read all customer feedback and respond to reviews to build trust.',
                        Icons.star_rate,
                        Colors.amber,
                        () => Get.to(() => const MerchantReviewsScreen()),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _analyticsCard(
                        context,
                        'Financial Overview',
                        'View revenue, sales history, and total earnings separated by days.',
                        Icons.account_balance_wallet,
                        AppColors.primary,
                        () => Get.to(() => const FinancialScreen()),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _analyticsCard(
                        context,
                        'Product Performance',
                        'Analyze your top selling products and monitor inventory insights.',
                        Icons.inventory_2,
                        Colors.blue,
                        () => Get.to(
                            () => const MerchantProductAnalyticsScreen()),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _analyticsCard(
                        context,
                        'Offer Analytics',
                        'Analyze how well your discounts are bringing in customers.',
                        Icons.bar_chart,
                        Colors.orange,
                        () => Get.to(() => const OfferPerformanceListScreen()),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _analyticsCard(
                        context,
                        'Store Payouts',
                        'Check your pending and past payouts directed to your bank account.',
                        Icons.payments,
                        AppColors.success,
                        () => Get.to(() => const PayoutsScreen()),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

}