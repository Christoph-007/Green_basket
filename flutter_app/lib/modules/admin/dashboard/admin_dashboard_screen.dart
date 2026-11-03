import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/modules/admin/admin_controller.dart';
import 'package:greenbasket_app/modules/admin/users/admin_users_screen.dart';
import 'package:greenbasket_app/modules/admin/orders/admin_orders_screen.dart';
import 'package:greenbasket_app/modules/admin/orders/admin_order_detail_screen.dart';
import 'package:greenbasket_app/modules/admin/merchants/admin_merchants_screen.dart';
import '../widgets/admin_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final controller = Get.find<AdminController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildOverviewStats(),
              _buildMetrics(),
              _buildPendingActions(),
              _buildRecentOrders(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                }
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final hour = DateTime.now().hour;
                      final greeting = hour < 12
                          ? 'Good morning'
                          : hour < 17
                              ? 'Good afternoon'
                              : 'Good evening';
                      return Text(
                        greeting,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      );
                    },
                  ),
                  const Text(
                    'Admin Dashboard',
                    style: AppTextStyles.displayMedium,
                  ),
                ],
              ),
            ],
          ),
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Text('SA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Obx(() => Row(
        children: [
          _statCard('Total Users', '${controller.totalUsersCount.value}', Icons.people_outline, Colors.blue.shade50, onTap: () {
            Get.to(() => const AdminUsersScreen());
          }),
          const SizedBox(width: AppSpacing.md),
          _statCard('Orders Today', '${controller.totalOrdersCount.value}', Icons.shopping_basket_outlined, Colors.green.shade50, onTap: () {
            Get.to(() => const AdminOrdersScreen());
          }),
        ],
      )),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color bgColor, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.textPrimary),
                const SizedBox(height: 12),
                Text(value, style: AppTextStyles.displaySmall),
                Text(label, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Obx(() {
        final report = controller.financialReport;
        final revenue = report['summary']?['totalGrossRevenue']?.toString() ?? '0';
        return Row(
          children: [
            _metricItem('Revenue', '₹$revenue'),
            _metricDivider(),
            _metricItem('Pending Actions', '${controller.pendingActionsCount.value}'),
          ],
        );
      }),
    );
  }

  Widget _metricItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary)),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _metricDivider() {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }

  Widget _buildPendingActions() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending Actions', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          Obx(() => Row(
            children: [
              _actionCard('${controller.merchantApprovalsCount.value} Merchant Approvals', Colors.orange.shade100, Colors.orange, onTap: () {
                Get.to(() => const AdminMerchantsScreen());
              }),
            ],
          )),
        ],
      ),
    );
  }

  Widget _actionCard(String text, Color bgColor, Color iconColor, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.report_gmailerrorred, color: iconColor),
                const SizedBox(width: 8),
                Expanded(child: Text(text, style: AppTextStyles.labelSmall.copyWith(color: Colors.black))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Orders', style: AppTextStyles.titleLarge),
              TextButton(onPressed: () {
                Get.to(() => const AdminOrdersScreen());
              }, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 4),
          Obx(() {
            if (controller.isLoading.value && controller.recentOrdersList.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.recentOrdersList.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text('No orders yet', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.recentOrdersList.length > 5
                  ? 5
                  : controller.recentOrdersList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = controller.recentOrdersList[index] as Map<String, dynamic>;
                return _buildOrderCard(order);
              },
            );
          }),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = (order['status'] as String? ?? 'pending').toLowerCase();
    final statusInfo = _getStatusInfo(status);
    final amount = (order['totalAmount'] ?? 0).toDouble();
    final customerName = order['customerName'] as String? ?? 'Unknown Customer';
    final merchantName = order['merchantName'] as String? ?? '';
    final orderId = order['orderId'] ?? order['orderNumber'] ?? order['_id'] ?? '';
    final itemCount = order['itemCount'] ?? order['items']?.length ?? 0;
    final paymentMethod = (order['paymentMethod'] as String? ?? 'cod').toUpperCase();
    final paymentStatus = order['paymentStatus'] as String? ?? 'pending';
    final createdAt = order['createdAt'];

    // Format time ago
    String timeAgo = '';
    if (createdAt != null) {
      DateTime? orderDate;
      if (createdAt is String) {
        orderDate = DateTime.tryParse(createdAt);
      }
      if (orderDate != null) {
        final diff = DateTime.now().difference(orderDate);
        if (diff.inMinutes < 1) {
          timeAgo = 'Just now';
        } else if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else if (diff.inDays < 7) {
          timeAgo = '${diff.inDays}d ago';
        } else {
          timeAgo = DateFormat('dd MMM').format(orderDate);
        }
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.to(() => AdminOrderDetailScreen(orderId: order['_id'] ?? order['id'] ?? ''));
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top row: Order ID + Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: statusInfo['bgColor'] as Color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            statusInfo['icon'] as IconData,
                            size: 18,
                            color: statusInfo['color'] as Color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${orderId.toString().length > 12 ? orderId.toString().substring(orderId.toString().length - 8) : orderId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (timeAgo.isNotEmpty)
                                Text(
                                  timeAgo,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(status, statusInfo),
                ],
              ),
              const Divider(height: 16),
              // Bottom row: Customer + Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                customerName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                merchantName.isNotEmpty ? merchantName : 'N/A',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            paymentMethod == 'COD' ? Icons.money : Icons.credit_card,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            paymentMethod == 'COD' ? 'COD' : paymentMethod,
                            style: TextStyle(
                              fontSize: 10,
                              color: paymentStatus == 'completed' || paymentStatus == 'paid'
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'delivered':
        return {
          'color': AppColors.success,
          'bgColor': AppColors.statusDelivered.withOpacity(0.3),
          'icon': Icons.check_circle_outline,
          'label': 'Delivered',
        };
      case 'confirmed':
        return {
          'color': AppColors.info,
          'bgColor': AppColors.statusConfirmed,
          'icon': Icons.thumb_up_outlined,
          'label': 'Confirmed',
        };
      case 'ready':
        return {
          'color': const Color(0xFF6A1B9A),
          'bgColor': const Color(0xFFF3E5F5),
          'icon': Icons.inventory_2_outlined,
          'label': 'Ready',
        };
      case 'dispatched':
      case 'out-for-delivery':
        return {
          'color': AppColors.secondary,
          'bgColor': AppColors.statusPreparing,
          'icon': Icons.shopping_bag_outlined,
          'label': 'Ready to pick up',
        };
      case 'cancelled':
        return {
          'color': AppColors.error,
          'bgColor': AppColors.statusCancelled,
          'icon': Icons.cancel_outlined,
          'label': 'Cancelled',
        };
      case 'refunded':
        return {
          'color': AppColors.error,
          'bgColor': AppColors.statusCancelled,
          'icon': Icons.replay,
          'label': 'Refunded',
        };
      case 'pending':
      default:
        return {
          'color': AppColors.warning,
          'bgColor': AppColors.statusPending,
          'icon': Icons.schedule,
          'label': 'Pending',
        };
    }
  }

  Widget _statusBadge(String status, Map<String, dynamic> statusInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (statusInfo['bgColor'] as Color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusInfo['label'] as String,
        style: TextStyle(
          color: statusInfo['color'] as Color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
