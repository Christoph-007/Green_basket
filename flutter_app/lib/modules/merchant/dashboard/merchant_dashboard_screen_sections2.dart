part of 'merchant_dashboard_screen.dart';

extension _MerchantDashboardScreenStateSections2 on _MerchantDashboardScreenState {
  Widget _statusChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: AppTextStyles.titleMedium.copyWith(
                    color: color, fontWeight: FontWeight.w700)),
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String text, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: color ?? AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewOrders() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('New Orders', style: AppTextStyles.headlineLarge),
                    const SizedBox(width: AppSpacing.sm),
                    if (controller.newOrders.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text('${controller.newOrders.length}',
                            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () => Get.toNamed('/merchant/orders', arguments: {'status': 'pending'}),
                  child: const Text('View All'),
                ),
              ],
            ),
            if (controller.newOrders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 48, color: AppColors.divider),
                    const SizedBox(height: AppSpacing.sm),
                    Text('No pending orders',
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('New orders will appear here',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.newOrders.length,
                itemBuilder: (context, index) {
                  final order = controller.newOrders[index];
                  return _newOrderCard(order);
                },
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    });
  }

  Widget _buildActiveOrders() {
    return Obx(() {
      if (controller.activeOrders.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Active Orders', style: AppTextStyles.headlineLarge),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text('${controller.activeOrders.length}',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.activeOrders.length,
              itemBuilder: (context, index) {
                final order = controller.activeOrders[index];
                return _activeOrderCard(order);
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _newOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${order.orderNumber}',
                          style: AppTextStyles.titleMedium
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              order.customerName ?? 'Customer',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(_timeAgo(order.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.orange.shade700)),
                ),
              ],
            ),
            const Divider(height: 20),
            // Items summary
            ...order.items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${item.quantity}',
                            style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(item.productName,
                              style: AppTextStyles.bodyMedium)),
                      Text(AppHelpers.formatCurrency(item.itemTotal),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                )),
            if (order.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('+${order.items.length - 3} more items',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            const Divider(height: 20),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(AppHelpers.formatCurrency(order.total),
                            style: AppTextStyles.titleLarge
                                .copyWith(color: AppColors.primary)),
                        const SizedBox(width: 8),
                        _paymentBadge(order.paymentMethod, order.paymentStatus),
                      ],
                    ),
                    Text('${order.items.length} items',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                Row(
                  children: [
                    GBButton(label: 'Decline', onPressed: () => controller.declineOrder(order.id), variant: GBButtonVariant.outline, foregroundColor: AppColors.error, height: 36),
                    const SizedBox(width: 8),
                    GBButton(label: 'Accept', onPressed: () => controller.acceptOrder(order.id), backgroundColor: AppColors.primary, height: 36),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
