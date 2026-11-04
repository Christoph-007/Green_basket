import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/models/order_model.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:greenbasket_app/modules/auth/auth_controller.dart';
import 'package:greenbasket_app/modules/merchant/merchant_controller.dart';

import '../widgets/merchant_drawer.dart';
import '../orders/merchant_disputes_screen.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  final controller = Get.put(MerchantController());
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const MerchantDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              controller.fetchProfile(),
              controller.fetchStats(),
              controller.fetchNewOrders(),
              controller.fetchActiveOrders(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildQuickStats(),
                _buildDisputesAlert(),
                _buildOrderStatusCards(),
                _buildNewOrders(),
                _buildActiveOrders(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
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
                style: TextStyle(fontSize: 11, color: color),
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
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
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
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500)),
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
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
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
                    OutlinedButton(
                      onPressed: () => controller.declineOrder(order.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.full)),
                      ),
                      child: const Text('Decline'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => controller.acceptOrder(order.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.full)),
                      ),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                            style: TextStyle(
                                fontSize: 11,
                                color: statusInfo.$2,
                                fontWeight: FontWeight.w600)),
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
                                  color: AppColors.primary,
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPaid ? AppColors.success : Colors.orange.shade700,
        ),
      ),
    );
  }

  (String, Color, IconData) _getStatusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return ('Confirmed', Colors.blue, Icons.check_circle_outline);
      case 'ready':
        return ('Ready', Colors.purple, Icons.inventory_2_outlined);
      case 'dispatched':
      case 'out-for-delivery':
        return ('Ready to pick up', Colors.teal, Icons.shopping_bag_outlined);
      case 'delivered':
        return ('Delivered', AppColors.success, Icons.done_all);
      default:
        return ('Pending', Colors.orange, Icons.schedule);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
