import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'payouts_controller.dart';
import 'package:greenbasket_app/modules/merchant/widgets/merchant_bottom_nav.dart';

part 'payouts_screen_sections1.dart';
part 'payouts_screen_sections2.dart';

class PayoutsScreen extends StatelessWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PayoutsController());

    return Scaffold(
      bottomNavigationBar: const MerchantBottomNav(highlight: false),
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Payouts', backIcon: Icons.arrow_back_ios_new, showDivider: false),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.fetchPayouts,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Available balance hero card ─────────────────────
                _buildBalanceCard(controller),
                const SizedBox(height: AppSpacing.sm),

                // Info banner
                _buildInfoBanner(controller),
                const SizedBox(height: AppSpacing.lg),

                // ─── Earnings summary row ────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'Total Earned',
                        controller.totalEarned.value,
                        AppColors.primary,
                        Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _summaryCard(
                        'Total Withdrawn',
                        controller.totalWithdrawn.value,
                        AppColors.success,
                        Icons.arrow_circle_up_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Current Period card ─────────────────────────────
                _buildCurrentPeriodCard(controller),
                const SizedBox(height: AppSpacing.lg),

                // ─── Payout history ──────────────────────────────────
                Text('Payout History', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Obx(() {
                  if (controller.payouts.isEmpty) {
                    return _buildEmptyPayouts();
                  }
                  return Column(
                    children: controller.payouts
                        .map((p) => _buildPayoutCard(p))
                        .toList(),
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      }),
    );
  }

}
