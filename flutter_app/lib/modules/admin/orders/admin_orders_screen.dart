import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_gradient_header.dart';
import 'package:greenbasket_app/config/status_style.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'admin_order_detail_screen.dart';
import '../widgets/admin_drawer.dart';

import '../admin_controller.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final controller = Get.find<AdminController>();
  final RxString _selectedFilter = 'All'.obs;

  static const _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Ready',
    'Out-for-delivery',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    controller.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Header
          GBGradientHeader(
            title: 'All Orders',
            trailingIcon: Icons.list_alt,
            subtitle: Obx(() => Text(
                  'Admin › Orders  (${controller.orders.length})',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                )),
          ),
          
          Expanded(
            child: Obx(() {
              if (controller.orders.isEmpty && controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredOrders = controller.orders.where((o) {
                if (_selectedFilter.value == 'All') return true;
                final orderStatus = (o['status']?.toString().toLowerCase() ?? '');
                return orderStatus == _selectedFilter.value.toLowerCase();
              }).toList();

              return RefreshIndicator(
                onRefresh: () => controller.fetchOrders(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildPill(f),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order Cards
                    if (filteredOrders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                _selectedFilter.value == 'All'
                                    ? 'No orders found'
                                    : 'No ${_selectedFilter.value.toLowerCase()} orders',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredOrders.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildOrderCard(order as Map<String, dynamic>),
                      )),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String title) {
    return Obx(() {
      bool isActive = _selectedFilter.value == title;
      // Count orders matching this filter
      final count = title == 'All'
          ? controller.orders.length
          : controller.orders.where((o) =>
              (o['status']?.toString().toLowerCase() ?? '') == title.toLowerCase()).length;

      return Semantics(button: true, child: GestureDetector(
        onTap: () => _selectedFilter.value = title,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: isActive ? null : Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatFilterLabel(title),
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ));
    });
  }

  String _formatFilterLabel(String status) {
    switch (status.toLowerCase()) {
      case 'out-for-delivery':
      case 'dispatched':
        return 'Out for Delivery';
      case 'payment_pending':
        return 'Awaiting Payment';
      default:
        return status;
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    final style = OrderStatusStyle.of(status);
    return {
      'color': style.fg,
      'bgColor': style.bg,
      'icon': style.icon,
      'label': style.label,
    };
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = (order['status']?.toString() ?? 'pending').toLowerCase();
    final statusInfo = _getStatusInfo(status);
    final orderId = order['orderId'] ?? order['orderNumber'] ?? order['_id'] ?? 'N/A';
    final customerName = order['customerName'] ?? order['customer']?['name'] ?? 'Guest';
    final merchantName = order['merchantName'] ?? order['merchant']?['businessName'] ?? '';
    final itemCount = order['itemCount'] ?? (order['items'] as List?)?.length ?? 0;
    final total = (order['totalAmount'] ?? order['total'] ?? 0).toDouble();
    final paymentMethod = (order['paymentMethod']?.toString() ?? 'cod').toUpperCase();
    final paymentStatus = order['paymentStatus']?.toString() ?? 'pending';
    final createdAt = order['createdAt'];

    // Format time
    String timeDisplay = '';
    String dateDisplay = '';
    if (createdAt != null) {
      DateTime? orderDate;
      if (createdAt is String) {
        orderDate = DateTime.tryParse(createdAt);
      }
      if (orderDate != null) {
        final diff = DateTime.now().difference(orderDate);
        if (diff.inMinutes < 1) {
          timeDisplay = 'Just now';
        } else if (diff.inMinutes < 60) {
          timeDisplay = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeDisplay = '${diff.inHours}h ago';
        } else if (diff.inDays < 7) {
          timeDisplay = '${diff.inDays}d ago';
        } else {
          timeDisplay = DateFormat('dd MMM').format(orderDate);
        }
        dateDisplay = DateFormat('dd MMM yyyy, hh:mm a').format(orderDate);
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.to(() => AdminOrderDetailScreen(orderId: order['_id'] ?? order['id'] ?? order['orderNumber']));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowTintFaint,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Order ID + Status Badge + Time
              Row(
                children: [
                  // Status icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusInfo['bgColor'] as Color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      statusInfo['icon'] as IconData,
                      size: 20,
                      color: statusInfo['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${orderId.toString().length > 14 ? orderId.toString().substring(orderId.toString().length - 10) : orderId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (timeDisplay.isNotEmpty)
                          Text(
                            timeDisplay,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusInfo['bgColor'] as Color,
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
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),

              // Row 2: Customer + Merchant
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            customerName.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            merchantName.toString().isNotEmpty ? merchantName.toString() : 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Row 3: Items + Payment + Amount
              Row(
                children: [
                  // Items count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Payment method
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          paymentMethod == 'COD' ? Icons.money : Icons.credit_card,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          paymentMethod == 'COD' ? 'COD' : paymentMethod,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: paymentStatus == 'completed' || paymentStatus == 'paid'
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Date
                  if (dateDisplay.isNotEmpty)
                    Text(
                      dateDisplay,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  const SizedBox(width: 12),
                  // Amount
                  Text(
                    '₹${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}