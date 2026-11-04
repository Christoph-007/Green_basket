import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_network_image.dart';
import 'package:get/get.dart';
import '../../../utils/order_status.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/models/order_model.dart';
import 'package:greenbasket_app/data/repositories/order_repository.dart';
import 'package:greenbasket_app/data/services/socket_service.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';

class OrderTrackingController extends GetxController {
  final _repo = OrderRepository();
  final order = Rxn<OrderModel>();
  final trackingData = Rxn<Map<String, dynamic>>();
  final isLoading = true.obs;

  late final String orderId;
  Worker? _statusWorker;
  Worker? _locationWorker;

  @override
  void onInit() {
    super.onInit();
    orderId = Get.arguments?['orderId'] ?? '';
    fetchTracking();
    _listenToSocket();
  }

  void _listenToSocket() {
    final socket = SocketService.to;

    // Re-fetch order when server pushes a status update for this order
    _statusWorker = ever(socket.orderStatusUpdate, (data) {
      if (data == null) return;
      final updatedOrder = data['order'] as Map<String, dynamic>? ?? data;
      if (updatedOrder['_id'] == orderId ||
          updatedOrder['orderId'] == orderId) {
        fetchTracking();
      }
    });

    // Update location data in real time
    _locationWorker = ever(socket.orderLocationUpdate, (data) {
      if (data == null) return;
      if (data['orderId'] == orderId) {
        trackingData.value = data;
      }
    });
  }

  @override
  void onClose() {
    _statusWorker?.dispose();
    _locationWorker?.dispose();
    super.onClose();
  }

  Future<void> fetchTracking() async {
    isLoading.value = true;
    try {
      final o = await _repo.getOrder(orderId);
      order.value = o;
      // Try to get tracking info
      try {
        final res = await OrderRepository().getOrderTracking(orderId);
        trackingData.value = res;
      } catch (_) {}
    } catch (_) {}
    isLoading.value = false;
  }

  List<_TrackingStep> get steps { // ignore: library_private_types_in_public_api
    final o = order.value;
    if (o == null) return [];
    final isPickup = OrderStatusRules.isPickup(o.deliveryType);
    final statusOrder = OrderStatusRules.timeline(o.deliveryType);

    String currentStatus = o.status;
    // Delivery orders end at 'delivered'; a completed delivery order is done too
    if (currentStatus == 'completed' && !statusOrder.contains('completed')) {
      currentStatus = 'delivered';
    }

    final currentIdx = statusOrder.indexOf(currentStatus);
    final labels = {
      'pending': 'Order Placed',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'ready': 'Ready to pick up',
      'completed': 'Picked Up',
      'out-for-delivery': 'Out for Delivery',
      'delivered': 'Delivered',
    };
    final descriptions = {
      'pending': 'Your order has been received',
      'confirmed': 'Merchant confirmed the order',
      'preparing': 'Your items are being packed',
      'ready': 'Your order is ready to pick up at the store',
      'completed': 'Enjoy your order!',
      'out-for-delivery': 'Your order is on its way',
      'delivered': isPickup ? 'Enjoy your order!' : 'Delivered. Enjoy your order!',
    };
    final icons = {
      'pending': Icons.receipt_long_rounded,
      'confirmed': Icons.check_circle_outline_rounded,
      'preparing': Icons.inventory_2_outlined,
      'dispatched': Icons.shopping_bag_outlined,
      'delivered': Icons.check_circle_outline,
    };

    return statusOrder.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      _StepStatus status;
      if (i < currentIdx) {
        status = _StepStatus.done;
      } else if (i == currentIdx) {
        status = currentStatus == 'delivered'
            ? _StepStatus.done
            : _StepStatus.active;
      } else {
        status = _StepStatus.pending;
      }
      return _TrackingStep(
        label: labels[s] ?? s,
        description: descriptions[s] ?? '',
        status: status,
        icon: icons[s] ?? Icons.circle,
      );
    }).toList();
  }
}

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(OrderTrackingController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(tooltip: 'Back', 
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
              'Track Order ${ctrl.order.value?.orderNumber ?? ''}',
              style: AppTextStyles.titleLarge)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBLoader();
        final o = ctrl.order.value;
        if (o == null) {
          return const Center(child: Text('Order not found'));
        }
        final steps = ctrl.steps;

        return RefreshIndicator(
          onRefresh: ctrl.fetchTracking,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ETA chip
                if (o.estimatedDelivery != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryLight
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'ETA: ${AppHelpers.formatTime(o.estimatedDelivery!)}',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // Stepper
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: List.generate(steps.length, (i) {
                      final step = steps[i];
                      final isLast = i == steps.length - 1;
                      return _buildStep(step, isLast);
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Map placeholder
                Text('Live Location',
                    style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.neutralSoft,
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 180),
                        painter: _MapGridPainter(),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_rounded,
                              color:
                                  AppColors.primary.withValues(alpha: 0.7),
                              size: 40),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.full),
                            ),
                            child: Text(
                              'Live tracking coming soon',
                              style: AppTextStyles.labelSmall
                                  .copyWith(
                                      color:
                                          AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Order items
                Text('Order Items',
                    style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(AppSpacing.md),
                    itemCount: o.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      final item = o.items[i];
                      return Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                  AppRadius.sm),
                            ),
                            child: item.productImage != null
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppRadius.sm),
                                    child: GBNetworkImage(
                                        url: item.productImage,
                                        memCacheWidth: 200),
                                  )
                                : const Icon(Icons.eco_outlined,
                                    color: AppColors.primary,
                                    size: 22),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(item.productName,
                                    style: AppTextStyles
                                        .titleMedium),
                                Text('${item.quantity} × ${AppHelpers.formatCurrency(item.price)}',
                                    style: AppTextStyles
                                        .bodySmall),
                              ],
                            ),
                          ),
                          Text(
                            AppHelpers.formatCurrency(
                                item.itemTotal),
                            style: AppTextStyles.titleMedium
                                .copyWith(
                                    color: AppColors.primary),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Total
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: AppTextStyles.titleLarge),
                      Text(AppHelpers.formatCurrency(o.total),
                          style: AppTextStyles.titleLarge
                              .copyWith(
                                  color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep(_TrackingStep step, bool isLast) {
    final isDone = step.status == _StepStatus.done;
    final isActive = step.status == _StepStatus.active;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: AppMotion.normal,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primary
                    : isActive
                        ? AppColors.primaryContainer
                        : AppColors.border.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(
                        color: AppColors.primary, width: 2)
                    : null,
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : Icon(step.icon,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: 14),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color:
                    isDone ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.md, top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDone || isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                Text(
                  step.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDone || isActive
                        ? AppColors.textSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _StepStatus { done, active, pending }

class _TrackingStep {
  final String label;
  final String description;
  final _StepStatus status;
  final IconData icon;
  const _TrackingStep({
    required this.label,
    required this.description,
    required this.status,
    required this.icon,
  });
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
