part of 'merchant_analytics_screen.dart';

extension _MerchantAnalyticsScreenSections on MerchantAnalyticsScreen {
  Widget _miniStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value,
              style:
                  AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }

  Widget _analyticsCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleLarge),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.arrow_forward_ios,
                      color: AppColors.textHint, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart(MerchantAnalyticsController controller) {
    // If dailyBreakdown is from SalesAnalytics, it might be the list of days.
    if (controller.dailyBreakdown.isEmpty) return const SizedBox.shrink();

    // Take up to last 7 days for the chart
    final data = controller.dailyBreakdown.take(7).toList();
    // Calculate max to scale the bars
    double maxRev = 1.0;
    for (var d in data) {
      final rev = (d['revenue'] ?? 0).toDouble();
      if (rev > maxRev) maxRev = rev;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                    const Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Revenue Trend', style: AppTextStyles.titleMedium),
                  ],
                ),
                Text('Last 7 Days', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((day) {
                  final revenue = (day['revenue'] ?? 0).toDouble();
                  final rawLabel = (day['day'] ?? '').toString();
                  final label = rawLabel.length > 3 ? rawLabel.substring(0, 3) : rawLabel;


                  final heightFactor = revenue / maxRev;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: (80 * heightFactor).clamp(4.0, 80.0).toDouble(),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primaryLight, AppColors.primary],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
