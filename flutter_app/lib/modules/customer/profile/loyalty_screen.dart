import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';

import '../../../data/models/loyalty_model.dart';
import '../../../data/repositories/loyalty_repository.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/common/gb_app_bar.dart';
import '../../../widgets/common/gb_loader.dart';

class LoyaltyController extends GetxController {
  final _repo = LoyaltyRepository();
  final loyalty = Rxn<LoyaltyModel>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLoyalty();
  }

  Future<void> fetchLoyalty() async {
    isLoading.value = true;
    try {
      loyalty.value = await _repo.getLoyaltyInfo();
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> redeemPoints(int points) async {
    try {
      final result = await _repo.redeemPoints(points: points);
      if (result['success'] == true) {
        final code = result['data']?['couponCode'];
        if (code != null) {
          Get.defaultDialog(
            title: 'Reward Unlocked!',
            content: Column(
              children: [
                const Text('Use this coupon code at checkout:'),
                const SizedBox(height: 12),
                SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('This code is valid for 30 days.'),
              ],
            ),
            textConfirm: 'Got it',
            confirmTextColor: Colors.white,
            onConfirm: () => Get.back(),
          );
        } else {
          GBSnack.plain('Success', 'Points redeemed successfully', position: SnackPosition.BOTTOM);
        }
        await fetchLoyalty();
      } else {
        GBSnack.plain('Error', result['message'] ?? 'Failed to redeem');
      }
    } catch (_) {
      GBSnack.plain('Error', 'Failed to redeem points');
    }
  }
}

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  // Correct tiers synced with backend
  static const _tiers = [
    {'name': 'Bronze', 'min': 0, 'max': 499, 'color': AppColors.chartBrown},
    {'name': 'Silver', 'min': 500, 'max': 999, 'color': AppColors.neutralGrey},
    {'name': 'Gold', 'min': 1000, 'max': 2499, 'color': AppColors.amber},
    {
      'name': 'Platinum',
      'min': 2500,
      'max': 999999,
      'color': AppColors.chartPurple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(LoyaltyController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GBAppBar(title: 'Loyalty Points'),
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBLoader();
        final model = ctrl.loyalty.value ?? LoyaltyModel();
        final points = model.points;
        final tier = model.tier;

        return RefreshIndicator(
          onRefresh: ctrl.fetchLoyalty,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Points card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getTierColor(tier),
                        _getTierColor(tier).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'My Points',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              AppHelpers.getLoyaltyTierLabel(tier),
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$points',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'points',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (model.totalEarned > 0 || model.totalRedeemed > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Earned: ${model.totalEarned}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Redeemed: ${model.totalRedeemed}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Progress to next tier
                if (tier != 'platinum') ...[
                  Text('Tier Progress', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppHelpers.getLoyaltyTierLabel(tier),
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              AppHelpers.getLoyaltyTierLabel(model.nextTier),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: model.nextTierProgress.clamp(0.0, 1.0),
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${model.pointsToNextTier} more points to ${AppHelpers.getLoyaltyTierLabel(model.nextTier)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Redeem section
                Text('Redeem Points', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '1 point = ₹1 discount (Min 50 points)',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      if (points < 50)
                        Text(
                          'You need at least 50 points to redeem.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                        )
                      else ...[
                        if (points >= 50)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => ctrl.redeemPoints(50),
                              child: const Text('Redeem 50 Points'),
                            ),
                          ),
                        if (points >= 100) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => ctrl.redeemPoints(100),
                              child: const Text('Redeem 100 Points'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: GBButton(label: 'Redeem All ($points Points)', onPressed: () => ctrl.redeemPoints(points), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tiers overview
                Text('Tier Benefits', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                ..._tiers.map(
                  (t) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: tier == (t['name'] as String).toLowerCase()
                            ? t['color'] as Color
                            : AppColors.border,
                        width: tier == (t['name'] as String).toLowerCase()
                            ? 2
                            : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars_rounded, color: t['color'] as Color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['name'] as String,
                                style: AppTextStyles.titleMedium,
                              ),
                              Text(
                                '${t['min']} – ${(t['max'] as int) > 99999 ? '∞' : t['max']} points',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (tier == (t['name'] as String).toLowerCase())
                          const Text(
                            'Current',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // History
                if (model.history.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Points History', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  ...model.history
                      .take(10)
                      .map(
                        (h) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                h.type == 'earned'
                                    ? Icons.add_circle_outline
                                    : Icons.remove_circle_outline,
                                color: h.type == 'earned'
                                    ? AppColors.success
                                    : AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.description,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    Text(
                                      AppHelpers.formatDate(h.createdAt),
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${h.type == 'earned' ? '+' : '-'}${h.points}',
                                style: TextStyle(
                                  color: h.type == 'earned'
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'silver':
        return AppColors.neutralGrey;
      case 'gold':
        return AppColors.amber;
      case 'platinum':
        return AppColors.chartPurple;
      default:
        return AppColors.chartBrown;
    }
  }
}
