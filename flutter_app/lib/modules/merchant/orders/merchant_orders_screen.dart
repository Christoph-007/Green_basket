import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'merchant_order_controller.dart';
import 'merchant_order_detail_screen.dart';
import '../widgets/merchant_drawer.dart';

class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(MerchantOrderController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Orders Management'),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Obx(() => Tab(text: 'Pending (${controller.pendingOrders.length})')),
            Obx(() =>
                Tab(text: 'Preparing (${controller.preparingOrders.length})')),
            Obx(() =>
                Tab(text: 'Completed (${controller.completedOrders.length})')),
            Obx(() =>
                Tab(text: 'Cancelled (${controller.cancelledOrders.length})')),
          ],
        ),
      ),
      drawer: const MerchantDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(type: 'pending'),
          _buildOrderList(type: 'preparing'),
          _buildOrderList(type: 'completed'),
          _buildOrderList(type: 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildOrderList({required String type}) {
    return Obx(() {
      final orders = type == 'pending'
          ? controller.pendingOrders
          : type == 'preparing'
              ? controller.preparingOrders
              : type == 'completed'
                  ? controller.completedOrders
                  : controller.cancelledOrders;

      if (controller.isLoading.value && orders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (orders.isEmpty) {
        return Center(
            child: Text('No $type orders', style: AppTextStyles.bodyLarge));
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchAllOrders(),
        child: ListView.separated(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final order = orders[index];
          final customerDisplayName = (order.customerName?.isNotEmpty == true)
              ? order.customerName!
              : 'Customer';
          final customerInitial = customerDisplayName.isNotEmpty
              ? customerDisplayName[0].toUpperCase()
              : 'C';
          final addressText = order.deliveryAddress.line1.isNotEmpty
              ? order.deliveryAddress.fullAddress
              : 'Address not available';

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () =>
                    Get.to(() => MerchantOrderDetailScreen(order: order)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text('Order #${order.orderNumber}',
                                      style: AppTextStyles.titleMedium,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (order.deliveryType == 'pickup') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.info),
                                    ),
                                    child: const Text('PICKUP', style: TextStyle(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Divider(height: 1),
                      ),
                      // Customer info
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primaryContainer,
                            radius: 20,
                            child: Text(customerInitial,
                                style: AppTextStyles.titleMedium
                                    .copyWith(color: AppColors.primary)),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customerDisplayName,
                                    style: AppTextStyles.bodyLarge
                                        .copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(order.deliveryType == 'pickup' ? Icons.store_outlined : Icons.location_on_outlined,
                                        size: 13, color: AppColors.textSecondary),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(order.deliveryType == 'pickup' ? 'Self Pickup at Store' : addressText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),
                      // Items summary
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Column(
                          children: [
                            ...order.items.take(3).map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Center(
                                          child: Text('${item.quantity}x',
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary)),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(item.productName,
                                            style: AppTextStyles.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      Text(AppHelpers.formatCurrency(item.itemTotal),
                                          style: AppTextStyles.bodySmall
                                              .copyWith(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )),
                            if (order.items.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                    '+${order.items.length - 3} more items',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.textHint)),
                              ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${order.items.length} items total',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.textSecondary)),
                                Text(AppHelpers.formatCurrency(order.total),
                                    style: AppTextStyles.titleMedium
                                        .copyWith(color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(AppHelpers.formatDateTime(order.createdAt),
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                          if (order.status == 'pending')
                            ElevatedButton(
                              onPressed: () =>
                                  controller.updateStatus(order.id, 'confirmed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 0),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full)),
                              ),
                              child: const Text('Accept Order',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            )
                          else if (order.status == 'confirmed' ||
                              order.status == 'preparing')
                            ElevatedButton(
                              onPressed: () =>
                                  controller.updateStatus(order.id, 'ready'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 0),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full)),
                              ),
                              child: Text(
                                  order.deliveryType == 'pickup'
                                      ? 'Ready to pick up'
                                      : 'Mark Ready',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            )
                          else if (order.status == 'ready')
                            ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Ready to pick up',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.info,
                                disabledBackgroundColor: AppColors.info.withOpacity(0.8),
                                disabledForegroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 0),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full)),
                              ),
                            )
                          else if (order.status == 'out-for-delivery' || order.status == 'dispatched')
                            ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                              label: const Text('Ready to pick up',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.primary.withOpacity(0.8),
                                disabledForegroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 0),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full)),
                              ),
                            )
                          else
                            OutlinedButton(
                              onPressed: () => Get.to(
                                  () => MerchantOrderDetailScreen(order: order)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 0),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full)),
                              ),
                              child: const Text('View Details',
                                  style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      );
    });
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text = status.capitalizeFirst ?? '';

    switch (status) {
      case 'pending':
        bgColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        text = 'New';
        break;
      case 'confirmed':
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        text = 'Confirmed';
        break;
      case 'preparing':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = 'Preparing';
        break;
      case 'ready':
        bgColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        text = 'Ready';
        break;
      case 'out-for-delivery':
      case 'dispatched':
        bgColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        text = 'Ready to Pick up';
        break;
      case 'completed':
      case 'delivered':
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        text = 'Delivered';
        break;
      case 'cancelled':
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        text = 'Cancelled';
        break;
      case 'refunded':
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        text = 'Refunded';
        break;
      default:
        bgColor = AppColors.background;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, color: textColor, fontWeight: FontWeight.w600)),
    );
  }
}