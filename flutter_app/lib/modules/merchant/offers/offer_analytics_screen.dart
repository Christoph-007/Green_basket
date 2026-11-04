import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';
import 'package:greenbasket_app/modules/merchant/widgets/merchant_bottom_nav.dart';

class _OfferAnalyticsController extends GetxController {
  final _repo = MerchantRepository();
  final isLoading = false.obs;
  final offerData = Rxn<Map<String, dynamic>>();
  final stats = Rxn<Map<String, dynamic>>();
  final chartData = <Map<String, dynamic>>[].obs;
  final redemptions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    final offerId = args?['_id'] ?? args?['id'] ?? '';
    if (offerId.isNotEmpty) {
      offerData.value = args;
      fetchAnalytics(offerId);
    }
  }

  Future<void> fetchAnalytics(String offerId) async {
    try {
      isLoading.value = true;
      final result = await _repo.getOfferAnalytics(offerId);
      final data = result['data'] ?? result;
      stats.value = data['stats'] ?? data;
      final rawChart = data['chartData'] as List<dynamic>? ?? [];
      chartData.assignAll(rawChart.cast<Map<String, dynamic>>());
      final rawRedemptions = data['redemptions'] as List<dynamic>? ?? [];
      redemptions.assignAll(rawRedemptions.cast<Map<String, dynamic>>());
    } catch (_) {
      stats.value = {};
      chartData.clear();
      redemptions.clear();
    } finally {
      isLoading.value = false;
    }
  }
}

class OfferAnalyticsScreen extends StatelessWidget {
  const OfferAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_OfferAnalyticsController());

    return Scaffold(
      bottomNavigationBar: const MerchantBottomNav(highlight: false),
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Offer Analytics', backIcon: Icons.arrow_back_ios_new, showDivider: false),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final offer = controller.offerData.value ?? {};
        final statsData = controller.stats.value ?? {};
        final title = offer['title'] ?? offer['name'] ?? 'Offer';
        final discountType = offer['type'] ?? offer['discountType'] ?? 'Percentage';
        final discountVal = offer['discount'] ?? offer['discountValue'] ?? 0;
        final discountDisplay = discountType == 'Fixed'
            ? '₹$discountVal off'
            : '$discountVal% off';
        final applicableOn = offer['applicableOn'] ?? 'All products';
        final status = offer['status'] ?? (offer['active'] == true ? 'Active' : 'Inactive');
        final validFrom = offer['validFrom'] ?? offer['startDate'] ?? '';
        final validTo = offer['validTo'] ?? offer['endDate'] ?? '';
        final period = validFrom.isNotEmpty && validTo.isNotEmpty
            ? '$validFrom – $validTo'
            : '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offer header
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.percent,
                          color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.titleLarge),
                          const SizedBox(height: 2),
                          Text('$discountDisplay · $applicableOn',
                              style: AppTextStyles.bodySmall),
                          if (period.isNotEmpty || status.isNotEmpty)
                            const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              if (status.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (status == 'Active' || status == 'active')
                                        ? AppColors.success.withValues(alpha: 0.1)
                                        : AppColors.warning.withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(status,
                                      style: AppTextStyles.labelSmall
                                          .copyWith(
                                              color: (status == 'Active' || status == 'active')
                                                  ? AppColors.success
                                                  : AppColors.warning)),
                                ),
                              if (period.isNotEmpty) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Text(period, style: AppTextStyles.bodySmall),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Stats row
              _buildStatsGrid(statsData),
              const SizedBox(height: AppSpacing.lg),

              // Chart
              if (controller.chartData.isNotEmpty) ...[
                Text('Daily Redemptions (This Week)',
                    style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _buildBarChart(controller.chartData),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Recent redemptions
              Text('Recent Redemptions', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.md),
              if (controller.redemptions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('No redemptions yet',
                        style: AppTextStyles.bodyMedium),
                  ),
                )
              else
                ...controller.redemptions
                    .map((r) => _buildRedemptionCard(r)),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data) {
    final stats = [
      {
        'label': 'Total Uses',
        'value': '${data['totalUses'] ?? data['usedCount'] ?? 0}',
        'icon': Icons.people_outline
      },
      {
        'label': 'Revenue',
        'value':
            '₹${(data['revenue'] ?? data['totalRevenue'] ?? 0).toStringAsFixed(0)}',
        'icon': Icons.currency_rupee
      },
      {
        'label': 'Avg Order',
        'value':
            '₹${(data['avgOrder'] ?? data['averageOrderValue'] ?? 0).toStringAsFixed(0)}',
        'icon': Icons.shopping_bag_outlined
      },
      {
        'label': 'Discount Given',
        'value':
            '₹${(data['totalDiscount'] ?? data['discountGiven'] ?? 0).toStringAsFixed(0)}',
        'icon': Icons.discount_outlined
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (ctx, i) {
        final stat = stats[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(stat['icon'] as IconData,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(stat['label'] as String,
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(stat['value'] as String,
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: AppColors.primary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    final maxCount = data
        .map((d) => (d['count'] ?? d['redemptions'] ?? 0) as num)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final count = (d['count'] ?? d['redemptions'] ?? 0) as num;
                final ratio = maxCount > 0 ? count / maxCount : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$count',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.primary)),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: 100 * ratio.toDouble(),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadius.sm)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: data.map((d) {
              final label = d['day'] ?? d['date'] ?? '';
              return Expanded(
                child: Text('$label',
                    style: AppTextStyles.labelSmall,
                    textAlign: TextAlign.center),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionCard(Map<String, dynamic> r) {
    final customer = r['customer'] ?? r['customerName'] ?? 'Customer';
    final date = r['date'] ?? r['createdAt'] ?? '-';
    final orderValue = (r['orderValue'] ?? r['amount'] ?? 0).toDouble();
    final discount = (r['discount'] ?? r['discountAmount'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              (customer as String).isNotEmpty ? customer[0].toUpperCase() : 'C',
              style:
                  AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500)),
                Text('$date', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${orderValue.toStringAsFixed(0)}',
                  style: AppTextStyles.titleMedium),
              Text('-₹${discount.toStringAsFixed(0)} off',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error)),
            ],
          ),
        ],
      ),
    );
  }
}
