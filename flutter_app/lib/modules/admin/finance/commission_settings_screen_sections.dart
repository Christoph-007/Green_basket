part of 'commission_settings_screen.dart';

extension _CommissionSettingsScreenStateSections on _CommissionSettingsScreenState {
  String _categoryIcon(Map<String, dynamic> cat) {
    final icon = (cat['icon'] ?? '').toString();
    if (icon.isEmpty) return '📦';
    // If it's an emoji already, return as-is
    if (icon.runes.any((r) => r > 127)) return icon;
    // Named icons
    const iconMap = {
      'carrot': '🥕',
      'apple': '🍎',
      'milk': '🥛',
      'wheat': '🌾',
      'pepper': '🌶️',
    };
    return iconMap[icon.toLowerCase()] ?? '📦';
  }

  String _scheduleLabel(String schedule) {
    switch (schedule) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Bi-weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return schedule.capitalize ?? schedule;
    }
  }

  Widget _buildRevenueSummary() {
    final gross =
        ((_financialSummary['totalGrossRevenue'] ?? 0) as num).toDouble();
    final commission =
        ((_financialSummary['totalCommissionEarned'] ?? 0) as num)
            .toDouble();
    final orders =
        ((_financialSummary['totalOrders'] ?? 0) as num).toInt();
    final refunds =
        ((_financialSummary['totalRefunds'] ?? 0) as num).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined,
                    color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('This Month', style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _summaryTile(
                    'Gross Revenue', '₹${gross.toStringAsFixed(0)}',
                    AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                _summaryTile(
                    'Commission', '₹${commission.toStringAsFixed(0)}',
                    AppColors.success),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _summaryTile('Orders', '$orders', AppColors.info),
                const SizedBox(width: AppSpacing.sm),
                _summaryTile(
                    'Refunds', '₹${refunds.toStringAsFixed(0)}',
                    AppColors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    AppTextStyles.titleMedium.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  void _rebuildCatControllers() {
    final old = Map<int, TextEditingController>.from(_catCtrlMap);
    _catCtrlMap.clear();
    _catEditingMap.clear();
    for (final c in old.values) {
      c.dispose();
    }
    for (int i = 0; i < _categoryRates.length; i++) {
      _catCtrlMap[i] = TextEditingController(
          text:
              (_categoryRates[i]['rate'] as double).toStringAsFixed(1));
      _catEditingMap[i] = false;
    }
  }

  Widget _buildTopMerchants() {
    if (_topMerchants.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store_outlined,
                    color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Top Merchants (This Month)',
                    style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._topMerchants.asMap().entries.map((e) {
              final i = e.key;
              final m = e.value;
              final merchant =
                  m['merchant'] as Map<String, dynamic>? ?? {};
              final name =
                  (merchant['businessName'] ?? 'Unknown').toString();
              final revenue =
                  ((m['revenue'] ?? 0) as num).toDouble();
              final commission =
                  ((m['commission'] ?? 0) as num).toDouble();
              final orders = ((m['orders'] ?? 0) as num).toInt();

              return Column(
                children: [
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            '${i + 1}',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: AppTextStyles.bodyMedium),
                              Text('$orders orders',
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${revenue.toStringAsFixed(0)}',
                              style: AppTextStyles.titleMedium
                                  .copyWith(
                                      color: AppColors.primary),
                            ),
                            Text(
                              '₹${commission.toStringAsFixed(0)} fee',
                              style: AppTextStyles.bodySmall
                                  .copyWith(
                                      color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
