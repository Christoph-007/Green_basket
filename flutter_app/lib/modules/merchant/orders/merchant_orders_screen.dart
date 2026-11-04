import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_status_chip.dart';
import 'package:greenbasket_app/widgets/common/gb_card.dart';
import 'package:greenbasket_app/widgets/common/gb_gradient_header.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:greenbasket_app/utils/order_status.dart';
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
      appBar: GBBrandAppBar(title: 'Orders Management', showMenu: true, bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
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
        )),
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
        return const GBListSkeleton(itemHeight: 140);
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
            decoration: GBCard.decoration(),
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
                                      color: AppColors.info.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.info),
                                    ),
                                    child: Text('PICKUP', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.info)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(order.status, order.deliveryType),
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
                                    .copyWith(color: AppColors.primaryText)),
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
                                              style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
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
                                        .copyWith(color: AppColors.textSecondary)),
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
                                        .copyWith(color: AppColors.primaryText)),
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
                              Icon(Icons.access_time,
                                  size: 14, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(AppHelpers.formatDateTime(order.createdAt),
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                          Builder(builder: (_) {
                            final next = OrderStatusRules.merchantNextStatus(
                                order.status, order.deliveryType);
                            final label = OrderStatusRules.merchantActionLabel(
                                order.status, order.deliveryType);
                            final shape = RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full));
                            if (next == null || label == null) {
                              return GBButton(label: 'View Details', onPressed: () => Get.to(() =>
                                    MerchantOrderDetailScreen(order: order)), variant: GBButtonVariant.outline, height: 36);
                            }
                            final isPending = order.status == 'pending';
                            return GBButton(label: isPending ? 'Accept Order' : label, onPressed: () =>
                                  controller.updateStatus(order.id, next), backgroundColor: isPending
                                    ? AppColors.primary
                                    : AppColors.success, height: 36);
                          }),
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

  Widget _buildStatusBadge(String status, String deliveryType) {
    String? text;
    switch (status) {
      case 'pending':
        text = 'New';
        break;
      case 'ready':
        text = deliveryType == 'pickup' ? 'Ready for Pick up' : 'Ready for Delivery';
        break;
    }
    return GBStatusChip(status: status, label: text);
  }
}
