import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'payouts_controller.dart';
import 'package:greenbasket_app/modules/merchant/widgets/merchant_bottom_nav.dart';

class PayoutsScreen extends StatelessWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PayoutsController());

    return Scaffold(
      bottomNavigationBar: const MerchantBottomNav(highlight: false),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payouts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
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

  // ─── Balance hero card ──────────────────────────────────────────────────
  Widget _buildBalanceCard(PayoutsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Available Balance',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => Text(
                '₹${controller.availableBalance.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next payout',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white54),
                  ),
                  Obx(() => Text(
                        controller.nextPayoutDate.value.isNotEmpty
                            ? controller.nextPayoutDate.value
                            : 'To be scheduled',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white),
                      )),
                ],
              ),
              Obx(() => ElevatedButton(
                    onPressed: controller.isRequesting.value ||
                            controller.availableBalance.value <= 0
                        ? null
                        : () => _confirmPayout(Get.context!, controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    child: controller.isRequesting.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : Text('Request Payout',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.primary)),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Info banner ────────────────────────────────────────────────────────
  Widget _buildInfoBanner(PayoutsController controller) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Obx(() => Text(
                  'Minimum payout: ₹${controller.minimumPayoutAmount.value.toStringAsFixed(0)}  •  Commission: ${controller.commissionRate.value.toStringAsFixed(0)}%',
                  style: AppTextStyles.bodySmall,
                )),
          ),
        ],
      ),
    );
  }

  // ─── Summary card ───────────────────────────────────────────────────────
  Widget _summaryCard(
      String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${value.toStringAsFixed(0)}',
                  style: AppTextStyles.titleLarge.copyWith(color: color),
                ),
                Text(label,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Current Period card ────────────────────────────────────────────────
  Widget _buildCurrentPeriodCard(PayoutsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Period', style: AppTextStyles.titleMedium),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${controller.periodStart.value} – ${controller.periodEnd.value}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _periodStat(
                    'Revenue',
                    controller.currentPeriodRevenue,
                    AppColors.textPrimary),
              ),
              Expanded(
                child: _periodStat(
                    'Commission',
                    controller.currentPeriodCommission,
                    AppColors.error),
              ),
              Expanded(
                child: _periodStat(
                    'Net',
                    controller.currentPeriodNet,
                    AppColors.success),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Orders', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                          '${controller.currentPeriodOrders.value}',
                          style: AppTextStyles.titleMedium,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodStat(String label, RxDouble value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 4),
        Obx(() => Text(
              '₹${value.value.toStringAsFixed(0)}',
              style: AppTextStyles.titleMedium.copyWith(color: color),
            )),
      ],
    );
  }

  // ─── Empty payouts placeholder ──────────────────────────────────────────
  Widget _buildEmptyPayouts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          const Text('No payout history yet',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Request a payout when your balance is ready',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Payout history card ────────────────────────────────────────────────
  Widget _buildPayoutCard(Map<String, dynamic> payout) {
    final status = (payout['status'] ?? 'pending').toString();
    final Color statusColor;
    final IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'failed':
        statusColor = AppColors.error;
        statusIcon = Icons.error_outline;
        break;
      case 'on_hold':
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle_outline;
        break;
      default: // pending
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule_outlined;
    }

    final netAmount = ((payout['netAmount'] ?? 0) as num).toDouble();
    final grossRevenue = ((payout['grossRevenue'] ?? 0) as num).toDouble();
    final payoutId = payout['payoutId'] ?? payout['_id'] ?? '-';
    final notes = payout['notes'] ?? '';

    // Format date
    String dateStr = '-';
    final raw = payout['createdAt'] ?? payout['date'];
    if (raw != null) {
      try {
        final dt = DateTime.parse(raw.toString());
        dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {
        dateStr = raw.toString();
      }
    }

    // Period range
    String periodStr = '';
    final period = payout['period'] as Map<String, dynamic>?;
    if (period != null) {
      try {
        final s = DateTime.parse(period['startDate'].toString());
        final e = DateTime.parse(period['endDate'].toString());
        periodStr =
            '${DateFormat('dd MMM').format(s)} – ${DateFormat('dd MMM yyyy').format(e)}';
      } catch (_) {}
    }

    // Commission info
    final commission = payout['platformCommission'] as Map<String, dynamic>?;
    final commissionAmt =
        ((commission?['amount'] ?? 0) as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: amount + status
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '₹${netAmount.toStringAsFixed(0)}',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            status.replaceAll('_', ' ').capitalizeFirst!,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(dateStr, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          // Details row
          if (grossRevenue > 0 || commissionAmt > 0 || periodStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    if (grossRevenue > 0)
                      _detailChip(
                          'Gross', '₹${grossRevenue.toStringAsFixed(0)}'),
                    if (commissionAmt > 0)
                      _detailChip('Fee',
                          '-₹${commissionAmt.toStringAsFixed(0)}'),
                    if (periodStr.isNotEmpty)
                      Expanded(
                        child: Text(periodStr,
                            style: AppTextStyles.labelSmall,
                            textAlign: TextAlign.right),
                      ),
                  ],
                ),
              ),
            ),
          // Payout ID / notes
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    payoutId.toString(),
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textHint),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (notes.toString().isNotEmpty)
                  Flexible(
                    child: Text(
                      notes.toString(),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }

  // ─── Confirm payout bottom sheet ────────────────────────────────────────
  void _confirmPayout(BuildContext context, PayoutsController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Request Payout', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text('Available Balance', style: AppTextStyles.bodySmall),
            Obx(() => Text(
                  '₹${controller.availableBalance.value.toStringAsFixed(2)}',
                  style: AppTextStyles.displayMedium
                      .copyWith(color: AppColors.primary),
                )),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Earnings breakdown
            _sheetRow('Total Earned',
                '₹${controller.totalEarned.value.toStringAsFixed(0)}'),
            _sheetRow('Total Withdrawn',
                '-₹${controller.totalWithdrawn.value.toStringAsFixed(0)}'),
            _sheetRow('Commission Rate',
                '${controller.commissionRate.value.toStringAsFixed(0)}%'),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Payouts are processed within 2-3 business days',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  controller.requestPayout();
                },
                child: const Text('Confirm Payout Request'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _sheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
