import 'package:flutter/material.dart';
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

String _apiError(Object e, String fallback) {
  if (e is DioException && e.response?.data is Map) {
    final body = e.response!.data as Map;
    return (body['message'] ?? body['error'] ?? fallback).toString();
  }
  return fallback;
}

class CheckoutController extends GetxController {
  final _repo = OrderRepository();
  final _walletRepo = WalletRepository();

  final isLoading = false.obs;
  final addresses = <AddressModel>[].obs;
  final selectedAddress = Rxn<AddressModel>();
  final selectedPayment = 'cod'.obs;

  /// 'pickup' or 'home-delivery'
  final deliveryType = 'pickup'.obs;

  /// Server-side quote: itemsTotal, deliveryCharges, discount, totalAmount…
  final quote = Rxn<Map<String, dynamic>>();
  final quoteError = ''.obs;
  final isQuoting = false.obs;

  final walletBalance = 0.0.obs;
  final walletLocked = false.obs;

  late Razorpay _razorpay;
  String? _currentInternalOrderId;
  bool _isProcessing = false;
  int _quoteSeq = 0;

  List<Map<String, Object>> get paymentMethods => [
        {
          'id': 'cod',
          'label': deliveryType.value == 'pickup' ? 'Pay at Pickup (Cash)' : 'Cash on Delivery',
          'icon': Icons.money,
        },
        {
          'id': 'razorpay',
          'label': 'Razorpay (Cards/UPI/Netbanking)',
          'icon': Icons.payment,
        },
        {
          'id': 'wallet',
          'label': 'Wallet (${AppHelpers.formatCurrency(walletBalance.value)})',
          'icon': Icons.account_balance_wallet_outlined,
        },
      ];

  double get total => (quote.value?['totalAmount'] as num?)?.toDouble() ?? 0;

  bool isPaymentAvailable(String id) {
    if (id != 'wallet') return true;
    return !walletLocked.value && quote.value != null && walletBalance.value >= total;
  }

  bool get canPlaceOrder =>
      !isLoading.value &&
      !isQuoting.value &&
      quote.value != null &&
      quoteError.value.isEmpty &&
      isPaymentAvailable(selectedPayment.value);

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void onReady() {
    super.onReady();
    fetchAddresses();
    fetchWallet();
    Get.find<CartController>().fetchCart().then((_) => refreshQuote());
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  Future<void> fetchAddresses() async {
    try {
      final list = await _repo.getAddresses();
      addresses.value = list;
      if (selectedAddress.value == null && addresses.isNotEmpty) {
        selectedAddress.value =
            addresses.firstWhereOrNull((a) => a.isDefault) ?? addresses.firstOrNull;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load addresses', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> fetchWallet() async {
    try {
      final wallet = await _walletRepo.getWallet();
      walletBalance.value = wallet.balance;
      walletLocked.value = wallet.isLocked;
    } catch (_) {}
  }

  void setDeliveryType(String type) {
    if (deliveryType.value == type) return;
    deliveryType.value = type;
    refreshQuote();
  }

  void selectAddress(AddressModel address) {
    selectedAddress.value = address;
    refreshQuote();
  }

  Future<void> addAddress() async {
    await Get.toNamed(Routes.addAddress);
    await fetchAddresses();
    refreshQuote();
  }

  /// Ask the backend for the exact totals (delivery depends on the address
  /// and the store's delivery zones), so what we show is what is charged.
  Future<void> refreshQuote() async {
    final seq = ++_quoteSeq;
    final cartCtrl = Get.find<CartController>();
    if (cartCtrl.items.isEmpty) {
      quote.value = null;
      quoteError.value = 'Your cart is empty';
      return;
    }
    if (deliveryType.value == 'home-delivery' && selectedAddress.value == null) {
      quote.value = null;
      quoteError.value = 'Add a delivery address to continue';
      return;
    }
    isQuoting.value = true;
    try {
      final q = await _repo.quoteOrder(
        deliveryType: deliveryType.value,
        addressId: deliveryType.value == 'home-delivery' ? selectedAddress.value?.id : null,
        couponCode: cartCtrl.appliedCoupon.value,
      );
      if (seq != _quoteSeq) return; // a newer quote is on its way
      quote.value = q;
      quoteError.value = '';
      final couponError = q['couponError'];
      if (couponError != null && cartCtrl.appliedCoupon.value.isNotEmpty) {
        Get.snackbar('Coupon removed', couponError.toString(), snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (seq != _quoteSeq) return;
      quote.value = null;
      quoteError.value = _apiError(e, 'Could not calculate the order total');
    } finally {
      if (seq == _quoteSeq) isQuoting.value = false;
    }
  }

  Future<void> placeOrder() async {
    if (_isProcessing || !canPlaceOrder) return;

    final cartCtrl = Get.find<CartController>();
    if (cartCtrl.items.isEmpty) {
      Get.snackbar('Cart Empty', 'Your cart is empty. Please add items to place an order.');
      return;
    }

    _isProcessing = true;
    isLoading.value = true;

    try {
      final isDelivery = deliveryType.value == 'home-delivery';
      final result = await _repo.checkout(
        addressId: isDelivery ? selectedAddress.value?.id : null,
        paymentMethod: selectedPayment.value,
        deliveryType: deliveryType.value,
        couponCode: cartCtrl.appliedCoupon.value.isNotEmpty ? cartCtrl.appliedCoupon.value : null,
      );

      if (result['success'] != true) {
        Get.snackbar('Error', result['message'] ?? 'Failed to place order',
            snackPosition: SnackPosition.BOTTOM);
        _finish();
        return;
      }

      final orderData = result['data']['order'];
      final totalAmount = (orderData['totalAmount'] as num).toDouble();
      final isOnline = selectedPayment.value == 'razorpay' || orderData['paymentMethod'] == 'online';

      if (!isOnline || totalAmount <= 0) {
        // COD and wallet orders are placed (and wallet paid) immediately
        await cartCtrl.fetchCart();
        if (selectedPayment.value == 'wallet') fetchWallet();
        Get.offAllNamed(Routes.orderList);
        Get.snackbar(
          'Order Placed!',
          'Your order has been placed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        _finish();
        return;
      }

      // Online: create the Razorpay order and open the checkout
      _currentInternalOrderId = orderData['orderId'];
      final payRes = await _repo.createPaymentOrder(
        orderId: _currentInternalOrderId!,
        amount: totalAmount,
        provider: 'razorpay',
      );
      if (payRes['success'] != true) {
        Get.snackbar('Error', payRes['message'] ?? payRes['error'] ?? 'Failed to create payment order');
        _finish();
        return;
      }
      final data = payRes['data'];
      if (data['key'] == null || data['orderId'] == null) {
        Get.snackbar('Error', 'Invalid payment configuration from server');
        _finish();
        return;
      }

      _razorpay.open({
        'key': data['key'],
        'amount': (data['amount'] as num).toInt(), // paise, from the backend
        'name': 'GreenBasket',
        'order_id': data['orderId'],
        'description': 'Order $_currentInternalOrderId',
        'prefill': {
          'contact': data['customer']?['phone'] ?? '',
          'email': data['customer']?['email'] ?? '',
        },
        'timeout': 300,
      });

      // If the payment sheet never reports back, unlock the button
      Future.delayed(const Duration(seconds: 15), () {
        if (isLoading.value && _isProcessing) {
          _finish();
          Get.snackbar('Payment', 'Payment window did not respond. You can retry from your orders.',
              snackPosition: SnackPosition.BOTTOM);
        }
      });
    } catch (e) {
      final msg = _apiError(e, 'Failed to place order');
      if (msg.contains('empty cart')) {
        await cartCtrl.fetchCart();
        Get.offAllNamed(Routes.orderList);
        Get.snackbar('Check Your Orders', 'Your cart is empty. Your order may have already been placed.',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
        refreshQuote(); // e.g. stock or delivery changed
      }
      _finish();
    }
  }

  void _finish() {
    isLoading.value = false;
    _isProcessing = false;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentInternalOrderId == null) return;
    isLoading.value = true;
    try {
      await _repo.verifyPayment({
        'orderId': _currentInternalOrderId,
        'razorpayPaymentId': response.paymentId,
        'razorpayOrderId': response.orderId,
        'razorpaySignature': response.signature,
      });

      final cartCtrl = Get.find<CartController>();
      await cartCtrl.fetchCart();
      Get.offAllNamed(Routes.orderList);
      Get.snackbar(
        'Order Placed!',
        'Payment successful and order placed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      // e.g. 409 when the order expired before payment: the backend refunds it
      Get.snackbar('Payment Verification Failed',
          _apiError(e, 'If money was deducted, it will be refunded automatically.'),
          duration: const Duration(seconds: 6));
    } finally {
      _finish();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _finish();
    Get.snackbar('Payment Failed', 'Error: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar('External Wallet', 'Selected wallet: ${response.walletName}');
  }

  bool get isProcessing => _isProcessing;
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
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, -2))],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: ctrl.canPlaceOrder ? ctrl.placeOrder : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                          ),
                          child: Text(
                            ctrl.isLoading.value
                                ? 'PROCESSING...'
                                : ctrl.quote.value == null
                                    ? 'Place Order'
                                    : 'Place Order — ${AppHelpers.formatCurrency(ctrl.total)}',
                            style: TextStyle(
                              fontSize: responsive.adaptiveFontSize(16),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Obx(() => ctrl.isLoading.value
              ? Container(
                  color: Colors.black.withOpacity(0.15),
                  child: const Center(child: GBLoader()),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final CheckoutController ctrl;
  const _Summary({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final q = ctrl.quote.value;
      Widget child;
      if (ctrl.isQuoting.value && q == null) {
        child = const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      } else if (ctrl.quoteError.value.isNotEmpty) {
        child = Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(ctrl.quoteError.value,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
            ),
          ],
        );
      } else if (q != null) {
        final delivery = (q['deliveryCharges'] as num?)?.toDouble() ?? 0;
        final discount = (q['discount'] as num?)?.toDouble() ?? 0;
        final isDelivery = q['deliveryType'] == 'home-delivery';
        child = Column(
          children: [
            _Row('Subtotal', AppHelpers.formatCurrency((q['itemsTotal'] as num).toDouble())),
            if (isDelivery) ...[
              const SizedBox(height: 8),
              _Row(
                q['zone'] is Map ? 'Delivery (${(q['zone'] as Map)['name']})' : 'Delivery Fee',
                delivery == 0 ? 'FREE' : AppHelpers.formatCurrency(delivery),
              ),
            ],
            if (discount > 0) ...[
              const SizedBox(height: 8),
              _Row(
                'Coupon ${q['couponCode'] ?? ''}'.trim(),
                '-${AppHelpers.formatCurrency(discount)}',
                valueColor: AppColors.success,
              ),
            ],
            const Divider(height: 16),
            _Row('Total', AppHelpers.formatCurrency(ctrl.total), isBold: true),
          ],
        );
      } else {
        child = const SizedBox.shrink();
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: child,
      );
    });
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: margin,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.titleMedium),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final style = isBold ? AppTextStyles.titleLarge : AppTextStyles.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: style)),
        Text(
          value,
          style: style.copyWith(color: valueColor ?? (isBold ? AppColors.primary : null)),
        ),
      ],
    );
  }
}
