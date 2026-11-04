part of 'merchant_dashboard_screen.dart';

extension _MerchantDashboardScreenStateSections3 on _MerchantDashboardScreenState {
  Widget _activeOrderCard(OrderModel order) {
    final statusInfo = _getStatusInfo(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusInfo.$2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(statusInfo.$3, color: statusInfo.$2, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('#${order.orderNumber}',
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusInfo.$2.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(statusInfo.$1,
                            style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: statusInfo.$2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${order.customerName ?? "Customer"} · ${order.items.length} items',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      Text(AppHelpers.formatCurrency(order.total),
                          style: AppTextStyles.bodyLarge
                              .copyWith(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentBadge(String method, String status) {
    final isPaid = status == 'paid' || status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPaid
            ? AppColors.success.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPaid ? 'PAID' : method.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: isPaid ? AppColors.success : Colors.orange.shade700),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
