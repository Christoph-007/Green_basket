import 'package:dio/dio.dart';
import 'package:greenbasket_app/widgets/common/gb_text_field.dart';
import 'package:greenbasket_app/widgets/common/gb_card.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_network_image.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/models/order_model.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:greenbasket_app/utils/order_status.dart';
import '../../../data/repositories/merchant_repository.dart';

class MerchantOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const MerchantOrderDetailScreen({super.key, required this.order});

  @override
  State<MerchantOrderDetailScreen> createState() =>
      _MerchantOrderDetailScreenState();
}

class _MerchantOrderDetailScreenState
    extends State<MerchantOrderDetailScreen> {
  final _repo = MerchantRepository();
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  // Rules shared with the backend (lib/utils/order_status.dart)
  String get _nextStatus =>
      OrderStatusRules.merchantNextStatus(_currentStatus, widget.order.deliveryType) ?? '';

  String? get _primaryActionLabel =>
      OrderStatusRules.merchantActionLabel(_currentStatus, widget.order.deliveryType);

  bool get _canCancel => OrderStatusRules.merchantCanCancel(_currentStatus);

  String _errorMessage(Object e, String fallback) {
    if (e is DioException && e.response?.data is Map) {
      final body = e.response!.data as Map;
      return (body['message'] ?? body['error'] ?? fallback).toString();
    }
    return fallback;
  }

  void _confirmCancel() {
    final reasonCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: const Text('Cancel this order?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Stock is returned and the customer is refunded if they prepaid.'),
          const SizedBox(height: 12),
          GBTextField(label: 'Reason (shown to the customer)', controller: reasonCtrl),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Keep Order')),
        TextButton(
          onPressed: () {
            Get.back();
            _setStatus('cancelled', note: reasonCtrl.text.trim());
          },
          child: Text('Cancel Order', style: TextStyle(color: AppColors.errorText)),
        ),
      ],
    ));
  }

  Color get _statusColor {
    switch (_currentStatus.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'preparing':
        return AppColors.secondary;
      case 'ready':
        return AppColors.success;
      case 'dispatched':
      case 'out_for_delivery':
      case 'out-for-delivery':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  Color get _statusBgColor => _statusColor.withValues(alpha: 0.1);

  Future<void> _advanceStatus() async {
    final next = _nextStatus;
    if (next.isEmpty) return;
    await _setStatus(next);
  }

  Future<void> _setStatus(String next, {String? note}) async {
    setState(() => _isUpdating = true);
    try {
      await _repo.updateOrderStatus(widget.order.id, next, note: note);
      setState(() => _currentStatus = next);
      GBSnack.success('Status Updated', 'Order is now ${AppHelpers.getOrderStatusLabel(next)}', position: SnackPosition.BOTTOM);
    } catch (e) {
      GBSnack.plain('Error', _errorMessage(e, 'Could not update order status'), position: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Order #${widget.order.orderNumber}', leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        )),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border:
                        Border.all(color: _statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _currentStatus.capitalizeFirst ?? _currentStatus,
                        style: AppTextStyles.labelLarge
                            .copyWith(color: _statusColor),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  AppHelpers.formatDateTime(widget.order.createdAt),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Customer info card
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Details',
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          (widget.order.customerName?.isNotEmpty == true)
                              ? widget.order.customerName![0].toUpperCase()
                              : 'C',
                          style: AppTextStyles.titleLarge
                              .copyWith(color: AppColors.primaryText),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                widget.order.customerName?.isNotEmpty == true
                                    ? widget.order.customerName!
                                    : 'Customer',
                                style: AppTextStyles.titleMedium),
                            const SizedBox(height: 2),
                            if (widget.order.customerPhone?.isNotEmpty == true)
                              Semantics(button: true, child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.phone_outlined,
                                        size: 14, color: AppColors.primaryText),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.order.customerPhone!,
                                      style: AppTextStyles.bodySmall
                                          .copyWith(
                                              color: AppColors.primaryText),
                                    ),
                                  ],
                                ),
                              ))
                            else
                              Semantics(button: true, child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.phone_outlined,
                                        size: 14, color: AppColors.primaryText),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Contact Customer',
                                      style: AppTextStyles.bodySmall
                                          .copyWith(
                                              color: AppColors.primaryText),
                                    ),
                                  ],
                                ),
                              )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(widget.order.deliveryType == 'pickup' ? Icons.store_outlined : Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                            widget.order.deliveryType == 'pickup' ? 'Self Pickup at Store' :
                            (widget.order.deliveryAddress.line1.isNotEmpty
                                ? widget.order.deliveryAddress.fullAddress
                                : 'Address not available'),
                            style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Items list
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Items', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  ...widget.order.items.map((item) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: item.productImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.sm),
                                      child: GBNetworkImage(
                                          url: item.productImage,
                                          memCacheWidth: 200),
                                    )
                                  : Icon(Icons.eco_outlined,
                                      color: AppColors.primaryText, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      style: AppTextStyles.bodyMedium),
                                  Text('Qty: ${item.quantity}',
                                      style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ),
                            Text(
                              AppHelpers.formatCurrency(item.itemTotal),
                              style: AppTextStyles.titleMedium,
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  _totalRow('Subtotal',
                      AppHelpers.formatCurrency(widget.order.subtotal)),
                  const SizedBox(height: AppSpacing.xs),
                  _totalRow('Delivery',
                      AppHelpers.formatCurrency(widget.order.deliveryFee)),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  _totalRow('Total',
                      AppHelpers.formatCurrency(widget.order.total),
                      isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Special instructions
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notes_outlined,
                          size: 18, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Special Instructions',
                          style: AppTextStyles.titleMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      widget.order.notes?.isNotEmpty == true
                          ? widget.order.notes!
                          : 'No special instructions provided',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: GBCard.decoration(),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_primaryActionLabel != null)
                SizedBox(
                  width: double.infinity,
                  child: GBButton(label: _primaryActionLabel!, isLoading: _isUpdating, onPressed: _advanceStatus),
                ),
              if (_primaryActionLabel != null)
                const SizedBox(height: AppSpacing.sm),
              if (_canCancel)
                SizedBox(
                  width: double.infinity,
                  child: GBButton(label: 'Cancel Order', onPressed: _isUpdating ? null : _confirmCancel, variant: GBButtonVariant.outline, foregroundColor: AppColors.errorText),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: GBCard.decoration(),
      child: child,
    );
  }

  Widget _totalRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.titleMedium
              : AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
        ),
        Text(
          amount,
          style: isTotal
              ? AppTextStyles.titleLarge.copyWith(color: AppColors.primaryText)
              : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}
