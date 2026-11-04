part of 'payouts_screen.dart';

extension _PayoutsScreenSections2 on PayoutsScreen {
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
            Text('Available Balance', style: AppTextStyles.bodySmall),
            Obx(() => Text(
                  '₹${controller.availableBalance.value.toStringAsFixed(2)}',
                  style: AppTextStyles.displayMedium
                      .copyWith(color: AppColors.primaryText),
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
                color: AppColors.warning.withValues(alpha: 0.1),
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
              child: GBButton(label: 'Confirm Payout Request', onPressed: () {
                  Navigator.pop(ctx);
                  controller.requestPayout();
                }),
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
