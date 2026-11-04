import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_card.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dio/dio.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/common/gb_app_bar.dart';
import '../../../widgets/common/gb_loader.dart';
import '../cart/cart_controller.dart';
import '../../../utils/responsive_helper.dart';

part 'checkout_screen_widgets.dart';

String _apiError(Object e, String fallback) {
  if (e is DioException && e.response?.data is Map) {
    final body = e.response!.data as Map;
    return (body['message'] ?? body['error'] ?? fallback).toString();
  }
  return fallback;
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CheckoutController>();
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GBAppBar(title: 'Checkout'),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(responsive.adaptiveSpacing(16)),
                      child: Obx(() => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Fulfilment ──────────────────────────────
                              Text('How do you want your order?', style: AppTextStyles.titleLarge),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ChoiceTile(
                                      icon: Icons.store_outlined,
                                      label: 'Pickup',
                                      selected: ctrl.deliveryType.value == 'pickup',
                                      onTap: () => ctrl.setDeliveryType('pickup'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ChoiceTile(
                                      icon: Icons.local_shipping_outlined,
                                      label: 'Home Delivery',
                                      selected: ctrl.deliveryType.value == 'home-delivery',
                                      onTap: () => ctrl.setDeliveryType('home-delivery'),
                                    ),
                                  ),
                                ],
                              ),

                              // ── Address (delivery only) ─────────────────
                              if (ctrl.deliveryType.value == 'home-delivery') ...[
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Delivery Address', style: AppTextStyles.titleLarge),
                                    TextButton.icon(
                                      onPressed: ctrl.addAddress,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (ctrl.addresses.isEmpty)
                                  Text('No saved addresses yet.',
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                ...ctrl.addresses.map((a) => _ChoiceTile(
                                      icon: Icons.location_on_outlined,
                                      label: a.label.isNotEmpty ? a.label : 'Address',
                                      subtitle: a.fullAddress,
                                      selected: ctrl.selectedAddress.value?.id == a.id,
                                      onTap: () => ctrl.selectAddress(a),
                                      margin: const EdgeInsets.only(bottom: 8),
                                    )),
                              ],

                              // ── Payment ─────────────────────────────────
                              const SizedBox(height: 24),
                              Text('Payment Method', style: AppTextStyles.titleLarge),
                              const SizedBox(height: 12),
                              ...ctrl.paymentMethods.map((method) {
                                final id = method['id'] as String;
                                final available = ctrl.isPaymentAvailable(id);
                                return _ChoiceTile(
                                  icon: method['icon'] as IconData,
                                  label: method['label'] as String,
                                  subtitle: !available && id == 'wallet'
                                      ? (ctrl.walletLocked.value ? 'Wallet is locked' : 'Insufficient balance')
                                      : null,
                                  selected: ctrl.selectedPayment.value == id,
                                  enabled: available,
                                  onTap: () => ctrl.selectedPayment.value = id,
                                  margin: const EdgeInsets.only(bottom: 8),
                                );
                              }),

                              // ── Summary (from the server quote) ─────────
                              const SizedBox(height: 24),
                              Text('Order Summary', style: AppTextStyles.titleLarge),
                              const SizedBox(height: 12),
                              _Summary(ctrl: ctrl),
                            ],
                          )),
                    ),
                  ),
                ),
              ),

              // ── Place order ───────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: GBCard.decoration(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Obx(
                        () => GBButton(label: ctrl.isLoading.value
                                ? 'PROCESSING...'
                                : ctrl.quote.value == null
                                    ? 'Place Order'
                                    : 'Place Order — ${AppHelpers.formatCurrency(ctrl.total)}', onPressed: ctrl.canPlaceOrder ? ctrl.placeOrder : null, backgroundColor: AppColors.primary, foregroundColor: Colors.white, height: 54),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Obx(() => ctrl.isLoading.value
              ? Container(
                  color: Colors.black.withValues(alpha: 0.15),
                  child: const Center(child: GBLoader()),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

