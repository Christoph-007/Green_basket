import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';


class MerchantAnalyticsController extends GetxController {
  final _repo = MerchantRepository();
  final isLoading = false.obs;

  // Top-level summary cards (from dashboard-stats for totals)
  final totalRevenue = 0.0.obs;
  final totalOrders = 0.obs;
  final deliveredOrders = 0.obs;
  final avgOrderValue = 0.0.obs;
  final revenueGrowth = 0.0.obs;
  final ordersGrowth = 0.0.obs;
  final todayOrders = 0.obs;
  final todayRevenue = 0.0.obs;
  final pendingOrders = 0.obs;

  // Inventory stats
  final totalProducts = 0.obs;
  final activeProducts = 0.obs;
  final lowStockCount = 0.obs;
  final outOfStockCount = 0.obs;
  final inventoryValue = 0.0.obs;

  // Customer stats
  final totalCustomers = 0.obs;
  final newCustomers = 0.obs;
  final returningCustomers = 0.obs;
  final retentionRate = 0.obs;
  final avgOrderFrequency = 0.0.obs;

  // Detailed data
  final topProducts = <Map<String, dynamic>>[].obs;
  final lowPerformers = <Map<String, dynamic>>[].obs;
  final topCustomers = <Map<String, dynamic>>[].obs;
  final dailyBreakdown = <Map<String, dynamic>>[].obs;
  final peakHours = <Map<String, dynamic>>[].obs;
  final paymentMethodBreakdown = Rxn<Map<String, dynamic>>();
  final topSellingDay = ''.obs;

  // Review stats
  final averageRating = 0.0.obs;
  final totalReviews = 0.obs;
  final recentReviews = <Map<String, dynamic>>[].obs;


  // Raw overview (keeping compatibility)
  final monthlyOverview = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      isLoading.value = true;
      
      // Fetch all analytics in parallel
      final results = await Future.wait([
        _repo.getDashboardStats(),
        _repo.getSalesAnalytics(),
        _repo.getInventoryAnalytics(),
        _repo.getCustomerAnalytics(),
        _repo.getProductAnalytics(),
        _repo.getMyStoreReviews(),
      ]);

      final dashData = (results[0]['data'] ?? results[0]) as Map<String, dynamic>;
      final salesData = (results[1]['data'] ?? results[1]) as Map<String, dynamic>;
      final invData = (results[2]['data'] ?? results[2]) as Map<String, dynamic>;
      final custData = (results[3]['data'] ?? results[3]) as Map<String, dynamic>;
      final prodData = (results[4]['data'] ?? results[4]) as Map<String, dynamic>;
      final reviewData = (results[5]['data'] ?? results[5]) as Map<String, dynamic>;


      // Dashboard broad stats (all orders, not just delivered)
      totalOrders.value = (dashData['totalOrders'] ?? 0);
      totalRevenue.value = (dashData['totalRevenue'] ?? 0).toDouble();
      avgOrderValue.value = (dashData['averageOrderValue'] ?? 0).toDouble();
      todayOrders.value = (dashData['todayOrders'] ?? 0);
      todayRevenue.value = (dashData['todayRevenue'] ?? 0).toDouble();
      pendingOrders.value = (dashData['pendingOrders'] ?? 0);

      // Sales Analytics (delivered orders only - growth metrics)
      final summary = salesData['summary'] ?? {};
      deliveredOrders.value = (summary['totalOrders'] ?? 0);
      revenueGrowth.value = (summary['revenueGrowth'] ?? 0.0).toDouble();
      ordersGrowth.value = (summary['ordersGrowth'] ?? 0.0).toDouble();

      // Inventory Summary
      totalProducts.value = (invData['totalProducts'] ?? 0);
      activeProducts.value = (invData['activeProducts'] ?? 0);
      lowStockCount.value = (invData['lowStockProducts'] ?? 0);
      outOfStockCount.value = (invData['outOfStockProducts'] ?? 0);
      inventoryValue.value = (invData['inventoryValue'] ?? 0.0).toDouble();

      // Customer Summary
      totalCustomers.value = (custData['totalCustomers'] ?? 0);
      newCustomers.value = (custData['newCustomers'] ?? 0);
      returningCustomers.value = (custData['returningCustomers'] ?? 0);
      retentionRate.value = (custData['retentionRate'] ?? 0);
      avgOrderFrequency.value = (custData['averageOrderFrequency'] ?? 0).toDouble();

      // Lists
      topProducts.assignAll(List<Map<String, dynamic>>.from(prodData['bestSellers'] ?? []));
      lowPerformers.assignAll(List<Map<String, dynamic>>.from(prodData['lowPerformers'] ?? []));
      topCustomers.assignAll(List<Map<String, dynamic>>.from(custData['topCustomers'] ?? []));
      dailyBreakdown.assignAll(List<Map<String, dynamic>>.from(salesData['dailyBreakdown'] ?? []));
      peakHours.assignAll(List<Map<String, dynamic>>.from(salesData['peakHours'] ?? []));
      paymentMethodBreakdown.value = (salesData['paymentMethodBreakdown'] as Map<String, dynamic>?) ?? {};
      topSellingDay.value = (salesData['topSellingDay'] ?? 'N/A').toString();

      // Reviews Summary
      averageRating.value = (reviewData['averageRating'] ?? 0.0).toDouble();
      totalReviews.value = (reviewData['totalReviews'] ?? 0);
      recentReviews.assignAll(List<Map<String, dynamic>>.from(reviewData['reviews'] ?? []));

      // Compatibility for legacy screen fields
      monthlyOverview.value = {
        'revenue': totalRevenue.value,
        'salesCount': totalOrders.value,
        'visitorsCount': totalCustomers.value,
        'conversionRate': retentionRate.value,
      };

    } catch (e) {
      debugPrint('[MerchantAnalyticsController] fetchAnalytics error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Expanded reviews for the reviews screen
  final allReviews = <Map<String, dynamic>>[].obs;
  final isReviewsLoading = false.obs;

  Future<void> replyToCustomerReview(String reviewId, String reply) async {

    try {
      final success = await _repo.replyToReview(reviewId, reply);
      if (success) {
        GBSnack.success('Success', 'Reply posted successfully');
        // Refresh to show the new reply
        fetchAnalytics();
      } else {
        GBSnack.error('Error', 'Failed to post reply');
      }
    } catch (e) {
      GBSnack.error('Error', 'An unexpected error occurred');
    }
  }
}

