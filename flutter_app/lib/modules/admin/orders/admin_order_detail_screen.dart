import 'package:dio/dio.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/utils/order_status.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import '../admin_controller.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String? orderId;
  const AdminOrderDetailScreen({super.key, this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final controller = Get.find<AdminController>();
  final _repo = AdminRepository();
  final RxMap<String, dynamic> _order = <String, dynamic>{}.obs;
  final RxBool _isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    final id = widget.orderId ?? Get.arguments?['id'];
    if (id == null) {
      Get.back();
      return;
    }
    _isLoading.value = true;
    try {
      final data = await controller.getOrderDetail(id);
      _order.value = data;
    } catch (e) {
      GBSnack.plain('Error', 'Failed to load order details');
    } finally {
      _isLoading.value = false;
    }
  }

  static const _statuses = ['Placed', 'Confirmed', 'Preparing', 'Ready to pick up', 'Delivered'];

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'ready to pick up':
      case 'dispatched':
      case 'in transit':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  void _showActionDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: Text('$action?', style: AppTextStyles.titleLarge),
        content: Text(
          'Are you sure you want to $action order #${_order['orderNumber'] ?? _order['_id']}? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GBButton(label: 'Confirm', onPressed: () async {
              Navigator.pop(ctx);
              final orderId = (_order['_id'] ?? _order['id']).toString();
              try {
                if (action == 'Cancel Order') {
                  await _repo.cancelOrder(orderId, 'Admin cancelled');
                } else if (action == 'Refund') {
                  await _repo.refundOrder(orderId);
                }
                Get.snackbar('Action Taken', '$action has been applied.',
                    backgroundColor: AppColors.primary, colorText: Colors.white);
                _fetchOrderDetail();
              } catch (e) {
                String msg = 'Failed to perform action';
                if (e is DioException && e.response?.data is Map) {
                  final body = e.response!.data as Map;
                  msg = (body['error'] ?? body['message'] ?? msg).toString();
                }
                GBSnack.error('Error', msg);
              }
            }, backgroundColor: action == 'Cancel Order' ? AppColors.error : AppColors.primary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text('Order #${_order['orderNumber'] ?? _order['_id'] ?? 'Loading...'}')),
        leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            final status = _order['status']?.toString() ?? 'Pending';
            return Container(
              margin: const EdgeInsets.only(right: AppSpacing.md, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                status,
                style: AppTextStyles.labelSmall.copyWith(
                  color: _statusColor(status),
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_order.isEmpty) {
          return const Center(child: Text('Order not found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeline(),
              const SizedBox(height: AppSpacing.md),
              _buildCustomerCard(),
              const SizedBox(height: AppSpacing.sm),
              _buildMerchantCard(),
              const SizedBox(height: AppSpacing.sm),
              _buildAgentCard(context),
              const SizedBox(height: AppSpacing.md),
              _buildItemsList(),
              const SizedBox(height: AppSpacing.md),
              _buildAdminActions(context),
              const SizedBox(height: AppSpacing.md),
              _buildActivityLog(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTimeline() {
    final status = _order['status']?.toString().toLowerCase() ?? '';
    int currentIndex = -1;
    if (status == 'placed') currentIndex = 0;
    if (status == 'confirmed') currentIndex = 1;
    if (status == 'preparing') currentIndex = 2;
    if (status == 'ready to pick up' || status == 'dispatched' || status == 'in transit') currentIndex = 3;
    if (status == 'delivered') currentIndex = 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Status', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: List.generate(_statuses.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepIndex = i ~/ 2;
                  final isPast = stepIndex < currentIndex;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: isPast ? AppColors.primary : AppColors.border,
                    ),
                  );
                } else {
                  final stepIndex = i ~/ 2;
                  final isDone = stepIndex <= currentIndex;
                  return Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.primary : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone ? Icons.check : Icons.circle,
                          color: Colors.white,
                          size: isDone ? 16 : 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statuses[stepIndex],
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDone ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, String>> rows,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTextStyles.titleMedium),
                if (trailing != null) ...[const Spacer(), trailing],
              ],
            ),
            const Divider(height: AppSpacing.md),
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(row['label']!, style: AppTextStyles.bodySmall),
                      ),
                      Expanded(child: Text(row['value']!, style: AppTextStyles.bodyMedium)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    final c = _order['customer'] as Map<String, dynamic>? ?? {};
    final address = _order['shippingAddress'] ?? c['address'] ?? 'N/A';
    return _buildInfoCard(
      title: 'Customer',
      icon: Icons.person_outline,
      iconColor: AppColors.info,
      rows: [
        {'label': 'Name', 'value': c['name']?.toString() ?? 'Guest'},
        {'label': 'Phone', 'value': c['phone']?.toString() ?? 'N/A'},
        {'label': 'Address', 'value': address.toString()},
      ],
    );
  }

  Widget _buildMerchantCard() {
    final m = _order['merchant'] as Map<String, dynamic>? ?? {};
    final merchantName = m['businessName']?.toString() ?? m['name']?.toString() ?? 'N/A';
    return _buildInfoCard(
      title: 'Merchant',
      icon: Icons.store_outlined,
      iconColor: AppColors.primary,
      rows: [
        {'label': 'Store', 'value': merchantName},
        {'label': 'Phone', 'value': m['phone']?.toString() ?? 'N/A'},
      ],
    );
  }

  Widget _buildAgentCard(BuildContext context) {
    final a = _order['agent'] as Map<String, dynamic>? ?? {};
    final hasAgent = a.isNotEmpty && a['name'] != null;
    return _buildInfoCard(
      title: 'Delivery Agent',
      icon: Icons.delivery_dining,
      iconColor: AppColors.secondary,
      rows: [
        {'label': 'Name', 'value': hasAgent ? a['name'].toString() : 'Not Assigned'},
        {'label': 'Phone', 'value': hasAgent ? (a['phone']?.toString() ?? 'N/A') : '-'},
        if (hasAgent) {'label': 'Vehicle', 'value': a['vehicle']?.toString() ?? 'N/A'},
      ],
      trailing: OutlinedButton(
        onPressed: () => Get.toNamed('/admin/assign-order', arguments: _order),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(hasAgent ? 'Reassign' : 'Assign', style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildItemsList() {
    final items = (_order['items'] as List?) ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Items', style: AppTextStyles.titleLarge),
            const Divider(),
            ...items.map((item) {
              final product = item['product'] as Map<String, dynamic>? ?? {};
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.eco_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name']?.toString() ?? 'N/A', style: AppTextStyles.bodyMedium),
                          Text('Qty: ${item['quantity'] ?? item['qty'] ?? 0}', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Text('₹${item['price'] ?? 0}', style: AppTextStyles.labelLarge),
                  ],
                ),
              );
            }),
            const Divider(),
            _totalRow('Subtotal', '₹${_order['subtotal'] ?? 0}'),
            _totalRow('Delivery Fee', '₹${_order['deliveryFee'] ?? 0}'),
            const Divider(),
            _totalRow('Total', '₹${_order['totalAmount'] ?? _order['total'] ?? 0}', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium),
          Text(value, style: isBold ? AppTextStyles.titleMedium.copyWith(color: AppColors.primary) : AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Actions', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Builder(builder: (_) {
              final status = (_order['status'] ?? '').toString();
              final paymentStatus = (_order['paymentStatus'] ?? '').toString();
              final refundStatus = ((_order['refund'] as Map?)?['status'] ?? 'none').toString();
              // Same rules the backend enforces
              final canCancel = OrderStatusRules.adminCancellable.contains(status);
              final canRefund = ['completed', 'paid'].contains(paymentStatus) &&
                  !['initiated', 'processing', 'completed'].contains(refundStatus);
              if (!canCancel && !canRefund) {
                return Text('No actions available for a $status order.',
                    style: AppTextStyles.bodySmall);
              }
              return Row(
                children: [
                  if (canCancel)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showActionDialog(context, 'Cancel Order'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  if (canCancel && canRefund) const SizedBox(width: AppSpacing.sm),
                  if (canRefund)
                    Expanded(
                      child: GBButton(label: 'Refund', onPressed: () => _showActionDialog(context, 'Refund'), backgroundColor: AppColors.info),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog() {
    final logs = (_order['activityLog'] as List?) ?? [];
    if (logs.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Log', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            ...logs.asMap().entries.map((e) {
              final i = e.key;
              final log = e.value as Map<String, dynamic>;
              final isLast = i == logs.length - 1;
              final timeString = log['createdAt']?.toString() ?? '';
              final time = timeString.contains('T') ? timeString.split('T')[1].substring(0, 5) : 'N/A';
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.border,
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log['action']?.toString() ?? 'Event', style: AppTextStyles.bodyMedium),
                          Text('at $time', style: AppTextStyles.bodySmall),
                        ],
                      ),
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
