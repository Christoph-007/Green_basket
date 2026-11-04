part of 'merchant_dashboard_screen.dart';

extension _MerchantDashboardScreenStateSections1 on _MerchantDashboardScreenState {
  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Builder(builder: (context) {
                    return IconButton(tooltip: 'Open menu', 
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    );
                  }),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting 👋',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Obx(() => Text(
                            authController.user.value?.name ?? "Merchant Store",
                            style: AppTextStyles.headlineLarge
                                .copyWith(color: Colors.white),
                          )),
                    ],
                  ),
                ],
              ),
              Obx(() => CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (authController.user.value?.name ?? "M")[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => Icon(Icons.circle,
                    size: 8,
                    color: controller.isStoreOpen.value
                        ? AppColors.success
                        : AppColors.error)),
                const SizedBox(width: 8),
                Obx(() => Text(
                      'Store Status: ${controller.isStoreOpen.value ? "Currently Open" : "Closed"}',
                      style:
                          AppTextStyles.bodySmall.copyWith(color: Colors.white),
                    )),
                const Spacer(),
                Obx(() => Switch(
                      value: controller.isStoreOpen.value,
                      onChanged: controller.toggleStoreStatus,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.success,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Obx(() => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _kpiCard(
                "Today's Revenue",
                controller.revenue.value,
                Icons.payments_outlined,
                AppColors.primaryContainer,
                AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              _kpiCard(
                'Today Orders',
                '${controller.orderCount.value}',
                Icons.receipt_long_outlined,
                Colors.orange.shade50,
                Colors.orange.shade700,
              ),
              const SizedBox(width: AppSpacing.sm),
              _kpiCard(
                'Total Revenue',
                AppHelpers.formatCurrencyFlexible(controller.totalRevenue.value),
                Icons.account_balance_wallet_outlined,
                Colors.blue.shade50,
                Colors.blue.shade700,
              ),
            ],
          ),
        ));
  }

  Widget _kpiCard(
      String label, String value, IconData icon, Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: AppTextStyles.titleLarge
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// What needs the seller now: orders waiting and products running low.
  /// Each card opens the matching tab. Nothing shows when all is well.
  Widget _buildAttentionRow() {
    return Obx(() {
      final waiting = controller.pendingCount.value;
      final low = controller.lowStockProducts.value;
      if (waiting == 0 && low == 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            if (waiting > 0)
              Expanded(
                child: _attentionCard(
                  Icons.pending_actions,
                  '$waiting order${waiting > 1 ? 's' : ''} waiting',
                  'Open orders',
                  () => MerchantNavController.goTo(1),
                ),
              ),
            if (waiting > 0 && low > 0) const SizedBox(width: AppSpacing.sm),
            if (low > 0)
              Expanded(
                child: _attentionCard(
                  Icons.inventory_2_outlined,
                  '$low low on stock',
                  'Restock now',
                  () => MerchantNavController.goTo(2),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _attentionCard(
      IconData icon, String title, String action, VoidCallback onTap) {
    return Material(
      color: AppColors.amberContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: AppColors.amberDark, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(action,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisputesAlert() {
    return Obx(() {
      if (controller.disputeCount.value == 0) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: InkWell(
          onTap: () => Get.to(() => const MerchantDisputesScreen()),
          child: Row(
            children: [
              const Icon(Icons.gavel_outlined, color: AppColors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${controller.disputeCount.value} Active Dispute${controller.disputeCount.value > 1 ? "s" : ""}',
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.error),
                    ),
                    Text(
                      'Customers have raised issues. Please review.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.error),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildOrderStatusCards() {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Overview',
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _statusChip('Pending', controller.pendingCount.value,
                      Colors.orange),
                  const SizedBox(width: AppSpacing.sm),
                  _statusChip('Confirmed', controller.confirmedCount.value,
                      Colors.blue),
                  const SizedBox(width: AppSpacing.sm),
                  _statusChip(
                      'Ready', controller.processingCount.value, Colors.purple),
                  const SizedBox(width: AppSpacing.sm),
                  _statusChip('Delivered', controller.deliveredCount.value,
                      AppColors.success),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _infoTile(Icons.inventory_2_outlined,
                      '${controller.totalProducts.value} Products'),
                  const SizedBox(width: AppSpacing.sm),
                  _infoTile(Icons.check_circle_outline,
                      '${controller.activeProducts.value} Active'),
                  if (controller.lowStockProducts.value > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _infoTile(Icons.warning_amber_outlined,
                        '${controller.lowStockProducts.value} Low Stock',
                        color: AppColors.warning),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ));
  }
}
