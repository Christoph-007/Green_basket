import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../utils/helpers.dart';
import '../../../utils/order_status.dart';
import '../../../widgets/common/gb_app_bar.dart';
import '../../../widgets/common/gb_loader.dart';
import '../../../widgets/common/empty_state.dart';
import 'return_request_sheet.dart';
import '../../../utils/responsive_helper.dart';

class OrderDetailController extends GetxController {
  final _repo = OrderRepository();
  final isLoading = false.obs;
  final order = Rxn<OrderModel>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final id = args['orderId'] as String? ?? '';
    if (id.isNotEmpty) fetchOrder(id);
  }

  final isCancelling = false.obs;

  Future<void> fetchOrder(String id) async {
    isLoading.value = true;
    try {
      order.value = await _repo.getOrder(id);
    } catch (_) {}
    isLoading.value = false;
  }

  bool get canCancel =>
      order.value != null &&
      OrderStatusRules.customerCancellable.contains(order.value!.status);

  /// Delivered (or, for pickup, completed) orders can be returned.
  bool get canReturn =>
      order.value != null &&
      (order.value!.status == 'delivered' || order.value!.status == 'completed');

  Future<void> openReturnSheet() async {
    final current = order.value;
    if (current == null) return;
    final submitted = await Get.bottomSheet<bool>(
      ReturnRequestSheet(order: current),
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
    );
    if (submitted == true) {
      Get.snackbar('Return requested', 'We will review it within 24 hours.',
          snackPosition: SnackPosition.BOTTOM);
      Get.toNamed(Routes.returns);
    }
  }

  Future<void> cancelOrder(String reason) async {
    final current = order.value;
    if (current == null || isCancelling.value) return;
    isCancelling.value = true;
    try {
      final res = await _repo.cancelOrder(current.id, reason);
      Get.snackbar('Order Cancelled', res['message']?.toString() ?? 'Your order has been cancelled',
          snackPosition: SnackPosition.BOTTOM);
      await fetchOrder(current.id);
    } on DioException catch (e) {
      final body = e.response?.data;
      Get.snackbar('Could not cancel',
          (body is Map ? body['message'] : null)?.toString() ?? 'Please try again',
          snackPosition: SnackPosition.BOTTOM);
      await fetchOrder(current.id);
    } finally {
      isCancelling.value = false;
    }
  }

  void confirmCancel() {
    final reasonCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: const Text('Cancel this order?'),
      content: TextField(
        controller: reasonCtrl,
        decoration: const InputDecoration(labelText: 'Reason (optional)'),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Keep Order')),
        TextButton(
          onPressed: () {
            Get.back();
            cancelOrder(reasonCtrl.text.trim());
          },
          child: const Text('Cancel Order', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(OrderDetailController());
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GBAppBar(title: 'Order Details'),
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBPageLoader();
        if (ctrl.order.value == null) {
          return const ErrorState(message: 'Order not found');
        }
        final order = ctrl.order.value!;
        final steps = OrderStatusRules.timeline(order.deliveryType);
        final currentStep = order.status == 'completed' && !steps.contains('completed')
            ? steps.length - 1
            : steps.indexOf(order.status);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Order #${order.orderNumber}',
                                  style: AppTextStyles.titleLarge,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            _statusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(AppHelpers.formatDateTime(order.createdAt),
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status timeline
                  if (order.status != 'cancelled') ...[
                    Text('Order Timeline', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        children: List.generate(steps.length, (i) {
                          final isDone = i <= currentStep;
                          final isCurrent = i == currentStep;
                          final isLast = i == steps.length - 1;
                          return _TimelineStep(
                            label: AppHelpers.getOrderStatusLabel(steps[i]),
                            isDone: isDone,
                            isCurrent: isCurrent,
                            isLast: isLast,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Items
                  Text('Items Ordered', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemCount: order.items.length,
                      itemBuilder: (context, i) {
                        final item = order.items[i];
                        return Row(
                          children: [
                            if (item.productImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: item.productImage!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.eco_outlined,
                                    color: AppColors.primary),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      style: AppTextStyles.titleMedium),
                                  Text('x${item.quantity}',
                                      style: AppTextStyles.bodySmall),
                                  if (order.status == 'delivered')
                                    GestureDetector(
                                      onTap: () => Get.toNamed(Routes.disputes, arguments: {
                                        'order': order,
                                        'product': item,
                                      }),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Help / Return',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              AppHelpers.formatCurrency(item.itemTotal),
                              style: AppTextStyles.titleMedium,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery address
                  Text('Delivery Address', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.deliveryAddress.label,
                                  style: AppTextStyles.titleMedium),
                              Text(order.deliveryAddress.fullAddress,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        _PriceRow('Subtotal', AppHelpers.formatCurrency(order.subtotal)),
                        const SizedBox(height: 8),
                        _PriceRow('Delivery Fee',
                            AppHelpers.formatCurrency(order.deliveryFee)),
                        if (order.discount > 0) ...[
                          const SizedBox(height: 8),
                          _PriceRow('Discount',
                              '-${AppHelpers.formatCurrency(order.discount)}',
                              color: AppColors.success),
                        ],
                        const Divider(height: 16),
                        _PriceRow('Total', AppHelpers.formatCurrency(order.total),
                            bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cancel button for eligible orders
                  if (ctrl.canCancel)
                    OutlinedButton(
                      onPressed: ctrl.isCancelling.value ? null : ctrl.confirmCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Cancel Order'),
                    ),

                  // Return items from a delivered / completed order
                  if (ctrl.canReturn)
                    OutlinedButton.icon(
                      onPressed: ctrl.openReturnSheet,
                      icon: const Icon(Icons.assignment_return_outlined),
                      label: const Text('Return items'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'delivered':
        color = AppColors.success;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        AppHelpers.getOrderStatusLabel(status),
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  const _TimelineStep({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? AppColors.primary : AppColors.border,
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: AppColors.primary, width: 3)
                    : null,
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDone ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDone ? AppColors.textPrimary : AppColors.textHint,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _PriceRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTextStyles.titleLarge : AppTextStyles.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value,
            style: style.copyWith(
                color: color ?? (bold ? AppColors.primary : null))),
      ],
    );
  }
}
