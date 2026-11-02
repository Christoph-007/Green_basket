import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../config/theme.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/common/gb_app_bar.dart';
import '../../../widgets/common/gb_loader.dart';
import '../../../widgets/common/empty_state.dart';

class WalletController extends GetxController {
  final _repo = WalletRepository();
  final balance = 0.0.obs;
  final isLocked = false.obs;
  final transactions = <WalletTransaction>[].obs;
  final isLoading = true.obs;
  final isAddingMoney = false.obs;

  Razorpay? _razorpay;

  @override
  void onInit() {
    super.onInit();
    fetchWallet();
  }

  @override
  void onClose() {
    _razorpay?.clear();
    super.onClose();
  }

  Future<void> fetchWallet() async {
    isLoading.value = true;
    try {
      final wallet = await _repo.getWallet();
      balance.value = wallet.balance;
      isLocked.value = wallet.isLocked;
      final txList = await _repo.getTransactions();
      transactions.value = txList;
    } catch (_) {}
    isLoading.value = false;
  }

  /// Top up the wallet: create a Razorpay order on the backend, open the
  /// Razorpay checkout, then let the backend verify and credit the payment.
  Future<void> addMoney(double amount) async {
    if (isAddingMoney.value) return;
    isAddingMoney.value = true;
    try {
      final result = await _repo.addMoney(amount);
      if (result['success'] != true) {
        isAddingMoney.value = false;
        Get.snackbar('Error', result['error'] ?? result['message'] ?? 'Failed to start top-up');
        return;
      }
      final data = Map<String, dynamic>.from(result['data'] ?? {});
      _razorpay ??= Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
      _razorpay!.open({
        'key': data['key'],
        'amount': data['amount'], // paise, from the backend
        'currency': data['currency'] ?? 'INR',
        'order_id': data['orderId'],
        'name': 'GreenBasket',
        'description': 'Wallet top-up',
      });
    } on DioException catch (e) {
      isAddingMoney.value = false;
      final body = e.response?.data;
      Get.snackbar('Error',
          (body is Map ? (body['error'] ?? body['message']) : null) ?? 'Failed to start top-up');
    } catch (_) {
      isAddingMoney.value = false;
      Get.snackbar('Error', 'Failed to open payment');
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final result = await _repo.verifyTopup(
        razorpayPaymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (result['success'] == true) {
        Get.snackbar('Success', 'Money added to wallet',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', result['error'] ?? 'Could not verify payment');
      }
    } on DioException catch (e) {
      final body = e.response?.data;
      Get.snackbar('Payment Verification Failed',
          (body is Map ? (body['error'] ?? body['message']) : null) ?? 'Please contact support if money was deducted.');
    } finally {
      isAddingMoney.value = false;
      await fetchWallet();
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    isAddingMoney.value = false;
    Get.snackbar('Payment Failed', response.message ?? 'Payment was not completed');
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WalletController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GBAppBar(title: 'My Wallet'),
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBLoader();
        return RefreshIndicator(
          onRefresh: ctrl.fetchWallet,
          child: Column(
            children: [
              // Balance card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (ctrl.isLocked.value)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Locked',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppHelpers.formatCurrency(ctrl.balance.value),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: ctrl.isLocked.value
                            ? null
                            : () => _showAddMoneyDialog(context, ctrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Money',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),

              // Transactions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text('Transaction History',
                        style: AppTextStyles.titleLarge),
                    const Spacer(),
                    Text('${ctrl.transactions.length} items',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: ctrl.transactions.isEmpty
                    ? const EmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'No transactions yet',
                        message: 'Your wallet transactions will appear here',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemCount: ctrl.transactions.length,
                        itemBuilder: (context, i) {
                          final tx = ctrl.transactions[i];
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: tx.isCredit
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.error.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tx.isCredit
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: tx.isCredit
                                    ? AppColors.success
                                    : AppColors.error,
                                size: 18,
                              ),
                            ),
                            title: Text(tx.description),
                            subtitle: Text(
                                AppHelpers.formatDate(tx.createdAt)),
                            trailing: Text(
                              '${tx.isCredit ? '+' : '-'}${AppHelpers.formatCurrency(tx.amount)}',
                              style: TextStyle(
                                color: tx.isCredit
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTextStyles.fontFamily,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showAddMoneyDialog(
      BuildContext context, WalletController ctrl) {
    final amountCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Add Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                hintText: 'Enter amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [100, 250, 500, 1000].map((amt) {
                return ActionChip(
                  label: Text('₹$amt'),
                  onPressed: () => amountCtrl.text = '$amt',
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount =
                  double.tryParse(amountCtrl.text.trim()) ?? 0;
              // Same limits the backend enforces in POST /wallet/add-money
              if (amount < 10 || amount > 10000) {
                Get.snackbar('Invalid amount',
                    'Enter an amount between ₹10 and ₹10,000');
                return;
              }
              Get.back();
              ctrl.addMoney(amount);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
