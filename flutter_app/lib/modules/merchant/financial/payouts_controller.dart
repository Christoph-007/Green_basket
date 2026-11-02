import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';

class PayoutsController extends GetxController {
  final _repo = MerchantRepository();
  final isLoading = false.obs;
  final isRequesting = false.obs;

  // Earnings summary (from /financial/merchants/earnings)
  final availableBalance = 0.0.obs;
  final totalEarned = 0.0.obs;
  final totalWithdrawn = 0.0.obs;
  final nextPayoutDate = ''.obs;
  final minimumPayoutAmount = 0.0.obs;
  final commissionRate = 0.0.obs;

  // Current period
  final currentPeriodRevenue = 0.0.obs;
  final currentPeriodCommission = 0.0.obs;
  final currentPeriodNet = 0.0.obs;
  final currentPeriodOrders = 0.obs;
  final periodStart = ''.obs;
  final periodEnd = ''.obs;

  // Payout history
  final payouts = <Map<String, dynamic>>[].obs;
  final totalPayoutsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPayouts();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> fetchPayouts() async {
    try {
      isLoading.value = true;
      final results = await Future.wait([
        _repo.getPayoutSummary(),
        _repo.getPayouts(),
      ]);

      // Parse earnings summary
      final summary = results[0] as Map<String, dynamic>;
      final data = summary['data'] ?? summary;
      availableBalance.value =
          ((data['pendingAmount'] ?? 0) as num).toDouble();
      totalEarned.value =
          ((data['totalEarned'] ?? 0) as num).toDouble();
      totalWithdrawn.value =
          ((data['totalWithdrawn'] ?? 0) as num).toDouble();
      commissionRate.value =
          ((data['commissionRate'] ?? 0) as num).toDouble();
      minimumPayoutAmount.value =
          ((data['minimumPayoutAmount'] ?? 0) as num).toDouble();

      final rawNextDate = data['nextPayoutDate']?.toString() ?? '';
      nextPayoutDate.value = _formatDate(rawNextDate);

      // Current period
      final period = data['currentPeriod'] as Map<String, dynamic>? ?? {};
      currentPeriodRevenue.value =
          ((period['revenue'] ?? 0) as num).toDouble();
      currentPeriodCommission.value =
          ((period['commission'] ?? 0) as num).toDouble();
      currentPeriodNet.value =
          ((period['netAmount'] ?? 0) as num).toDouble();
      currentPeriodOrders.value =
          ((period['ordersCount'] ?? 0) as num).toInt();
      periodStart.value =
          _formatDate(period['startDate']?.toString());
      periodEnd.value =
          _formatDate(period['endDate']?.toString());

      // Parse payouts list
      final payoutsList = results[1] as List<Map<String, dynamic>>;
      payouts.assignAll(payoutsList);
      totalPayoutsCount.value = payoutsList.length;
    } catch (e) {
      debugPrint('[PayoutsController] fetchPayouts error: $e');
      availableBalance.value = 0;
      totalEarned.value = 0;
      totalWithdrawn.value = 0;
      nextPayoutDate.value = '';
      commissionRate.value = 0;
      minimumPayoutAmount.value = 0;
      currentPeriodRevenue.value = 0;
      currentPeriodCommission.value = 0;
      currentPeriodNet.value = 0;
      currentPeriodOrders.value = 0;
      payouts.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestPayout() async {
    if (availableBalance.value <= 0) {
      Get.snackbar('No Balance', 'No available balance to withdraw',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (availableBalance.value < minimumPayoutAmount.value &&
        minimumPayoutAmount.value > 0) {
      Get.snackbar('Below Minimum',
          'Minimum payout amount is ₹${minimumPayoutAmount.value.toStringAsFixed(0)}',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      isRequesting.value = true;
      final result =
          await _repo.requestPayout(amount: availableBalance.value);
      if (result['success'] == true) {
        Get.snackbar(
          'Payout Requested',
          result['message'] ??
              'Your payout will be credited in 2–3 business days',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        fetchPayouts();
      } else {
        Get.snackbar(
            'Error', result['error'] ?? 'Payout request failed',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not process payout request',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isRequesting.value = false;
    }
  }
}
