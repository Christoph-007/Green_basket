import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/repositories/merchant_repository.dart';

class FinancialController extends GetxController {
  final _repo = MerchantRepository();
  final isLoading = false.obs;
  final selectedPeriod = 'month'.obs;

  // Summary stats
  final grossSales = 0.0.obs;
  final netEarnings = 0.0.obs;
  final commission = 0.0.obs;
  final pendingPayout = 0.0.obs;
  final chartValues = <double>[].obs;

  // Transactions
  final transactions = <Map<String, dynamic>>[].obs;

  final periodKeys = ['today', 'week', 'month', 'all'];
  final periodLabels = ['Today', 'This Week', 'This Month', 'All Time'];

  @override
  void onInit() {
    super.onInit();
    fetchFinancial();
  }

  Future<void> fetchFinancial() async {
    try {
      isLoading.value = true;
      final results = await Future.wait([
        _repo.getFinancialSummary(period: selectedPeriod.value),
        _repo.getTransactions(period: selectedPeriod.value),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      final txns = results[1] as List<Map<String, dynamic>>;

      final data = summary['data'] ?? summary;
      grossSales.value = ((data['grossSales'] ?? data['totalRevenue'] ?? 0) as num).toDouble();
      netEarnings.value = ((data['netEarnings'] ?? data['netRevenue'] ?? 0) as num).toDouble();
      commission.value = ((data['commission'] ?? data['platformFee'] ?? 0) as num).toDouble();
      pendingPayout.value = ((data['pendingPayout'] ?? data['pending'] ?? 0) as num).toDouble();

      final rawChart = data['chartValues'] as List<dynamic>? ?? [];
      if (rawChart.isNotEmpty) {
        final maxVal = rawChart
            .map((v) => (v as num).toDouble())
            .reduce((a, b) => a > b ? a : b);
        chartValues.value = maxVal > 0
            ? rawChart.map((v) => (v as num).toDouble() / maxVal).toList()
            : rawChart.map((_) => 0.0).toList();
      } else {
        chartValues.value = [];
      }

      transactions.assignAll(txns);
    } catch (e) {
      debugPrint('[FinancialController] fetchFinancial error: $e');
      grossSales.value = 0;
      netEarnings.value = 0;
      commission.value = 0;
      pendingPayout.value = 0;
      chartValues.value = [];
      transactions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void changePeriod(int index) {
    selectedPeriod.value = periodKeys[index];
    fetchFinancial();
  }
}
