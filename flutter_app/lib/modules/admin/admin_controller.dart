import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/repositories/admin_repository.dart';

class AdminController extends GetxController {
  final _repo = AdminRepository();
  final isLoading = false.obs;
  
  final totalUsersCount = 0.obs;
  final totalOrdersCount = 0.obs;
  final revenueValue = "₹0.00".obs;
  final pendingActionsCount = 0.obs;
  
  final merchantApprovalsCount = 0.obs;
  
  final recentOrdersList = [].obs;
  final orders = <dynamic>[].obs;
  final stats = <String, dynamic>{}.obs;

  final merchants = <dynamic>[].obs;
  final users = <dynamic>[].obs;
  final products = <dynamic>[].obs;
  final payouts = <dynamic>[].obs;
  final categories = <dynamic>[].obs;
  final recipes = <dynamic>[].obs;
  final financialReport = <String, dynamic>{}.obs;
  final financialPeriod = 'all'.obs; // all | month | quarter | year
  final financialError = ''.obs;
  final isFinanceLoading = false.obs;
  final recentPayouts = <dynamic>[].obs;

  // Month-by-month / year-by-year statement
  final statement = <String, dynamic>{}.obs;
  final statementBasis = 'calendar'.obs; // calendar | fy
  final statementYear = RxnInt();
  final statementError = ''.obs;
  final isStatementLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    await Future.wait([
      fetchStats(),
      fetchOrders(),
      fetchMerchants(),
      fetchUsers(),
      fetchProducts(),
      fetchPayouts(),
      fetchCategories(),
      fetchRecipes(),
      fetchFinancialReport(),
      fetchStatement(),
    ]);
  }

  Future<void> fetchFinancialReport({String? period}) async {
    if (period != null) financialPeriod.value = period;
    isFinanceLoading.value = true;
    try {
      final data = await _repo.getFinancialReports(period: financialPeriod.value);
      financialReport.value = data;
      financialError.value = '';
    } catch (e) {
      debugPrint('fetchFinancialReport error: $e');
      financialError.value = _errorMessage(e);
    }
    try {
      recentPayouts.assignAll(await _repo.getCompletedPayouts());
    } catch (e) {
      debugPrint('fetchRecentPayouts error: $e');
    }
    isFinanceLoading.value = false;
  }

  Future<void> fetchStatement({String? basis, int? year}) async {
    if (basis != null && basis != statementBasis.value) {
      statementBasis.value = basis;
      statementYear.value = null; // year meaning differs between calendar / FY
    }
    if (year != null) statementYear.value = year;
    isStatementLoading.value = true;
    try {
      statement.value = await _repo.getFinancialStatement(
          basis: statementBasis.value, year: statementYear.value);
      statementError.value = '';
    } catch (e) {
      debugPrint('fetchStatement error: $e');
      statementError.value = _errorMessage(e);
    }
    isStatementLoading.value = false;
  }

  String _errorMessage(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['error'] != null) return d['error'].toString();
      if (d is Map && d['message'] != null) return d['message'].toString();
      return e.message ?? 'Network error';
    }
    return e.toString();
  }

  Future<List<dynamic>> getRevenueOrders() async {
    try {
      return await _repo.getRevenueOrders(period: financialPeriod.value);
    } catch (e) {
      debugPrint('getRevenueOrders error: $e');
      return [];
    }
  }

  Future<void> fetchStats() async {
    try {
      isLoading.value = true;
      final response = await _repo.getStats();
      final data = response['data'] ?? response;
      stats.value = data;
      
      totalUsersCount.value = data['totalUsers'] ?? 0;
      totalOrdersCount.value = data['totalOrders'] ?? 0;
      revenueValue.value = "₹${data['revenue'] ?? data['totalRevenue'] ?? 0}";
      pendingActionsCount.value = data['pendingActions'] ?? 0;
      
      merchantApprovalsCount.value = data['pendingMerchants'] ?? 0;
      
      recentOrdersList.assignAll(data['recentOrders'] ?? []);
    } catch (e) {
      debugPrint('fetchStats error: $e');
    }
    finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOrders() async {
    try {
      final response = await _repo.getAllOrders();
      orders.assignAll(response);
    } catch (e) {
      debugPrint('fetchOrders error: $e');
    }
  }

  Future<void> fetchMerchants() async {
    try {
      final data = await _repo.getAllMerchants();
      merchants.assignAll(data);
    } catch (e) {
      debugPrint('fetchMerchants error: $e');
    }
  }

  Future<void> fetchUsers() async {
    try {
      final data = await _repo.getUsers();
      users.assignAll(data);
    } catch (e) {
      debugPrint('fetchUsers error: $e');
    }
  }

  Future<void> fetchProducts() async {
    try {
      final data = await _repo.getAllProducts();
      products.assignAll(data);
    } catch (e) {
      debugPrint('fetchProducts error: $e');
    }
  }

  Future<void> fetchPayouts() async {
    try {
      final data = await _repo.getPayoutRequests();
      payouts.assignAll(data);
    } catch (e) {
      debugPrint('fetchPayouts error: $e');
    }
  }

  Future<void> fetchCategories() async {
    try {
      final data = await _repo.getAllCategories();
      categories.assignAll(data);
    } catch (e) {
      debugPrint('fetchCategories error: $e');
    }
  }

  Future<void> toggleCategoryStatus(String id, bool isActive) async {
    try {
      await _repo.updateCategory(id, {'isActive': isActive});
      // Update the local list optimistically
      final idx = categories.indexWhere((c) => (c['_id'] ?? c['id']) == id);
      if (idx != -1) {
        final updated = Map<String, dynamic>.from(categories[idx] as Map);
        updated['isActive'] = isActive;
        categories[idx] = updated;
      }
    } catch (e) {
      debugPrint('toggleCategoryStatus error: $e');
      Get.snackbar('Error', 'Failed to update category status',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError);
    }
  }

  Future<void> deleteCategoryById(String id) async {
    try {
      await _repo.deleteCategory(id);
      categories.removeWhere((c) => (c['_id'] ?? c['id']) == id);
      Get.snackbar('Deleted', 'Category removed successfully',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError);
    } catch (e) {
      debugPrint('deleteCategoryById error: $e');
      Get.snackbar('Error', 'Failed to delete category',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError);
    }
  }

  Future<void> fetchRecipes() async {
    try {
      final data = await _repo.getAllRecipes();
      recipes.assignAll(data);
    } catch (e) {
      debugPrint('fetchRecipes error: $e');
    }
  }

  Future<void> verifyMerchant(String id, bool approved, {String? rejectionReason}) async {
    try {
      await _repo.verifyMerchant(id, approved, rejectionReason: rejectionReason);
      Get.snackbar('Success', approved ? 'Merchant Approved' : 'Merchant Rejected',
          backgroundColor: approved ? Get.theme.primaryColor : Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onPrimary);
      fetchAll();
    } catch (e) {
      debugPrint('verifyMerchant error: $e');
      Get.snackbar('Error', 'Failed to verify merchant');
    }
  }

  Future<void> toggleUserBlock(String id) async {
    try {
      await _repo.toggleUserBlock(id);
      await fetchUsers(); // Re-fetch to update state
    } catch (e) {
      debugPrint('toggleUserBlock error: $e');
    }
  }

  Future<void> toggleProductStatus(String id, String status) async {
    try {
      await _repo.updateProduct(id, {'status': status.toLowerCase()});
      await fetchProducts(); // Refresh the list
    } catch (e) {
      debugPrint('toggleProductStatus error: $e');
      Get.snackbar('Error', 'Failed to update product status');
    }
  }

  Future<void> deleteProductById(String id) async {
    try {
      await _repo.deleteProduct(id);
      await fetchProducts(); // Refresh the list
      await fetchStats(); // Update stats if needed
    } catch (e) {
      debugPrint('deleteProductById error: $e');
      Get.snackbar('Error', 'Failed to delete product');
    }
  }

  Future<void> toggleMerchantBlock(String id) async {
    try {
      await _repo.toggleMerchantBlock(id);
      await fetchMerchants(); // Re-fetch to update state
    } catch (e) {
      debugPrint('toggleMerchantBlock error: $e');
      Get.snackbar('Error', 'Failed to update merchant status');
    }
  }


  Future<void> processPayout(String id, bool approved) async {
    try {
      await _repo.processPayout(id);
      fetchPayouts();
      fetchStats();
      Get.snackbar('Success', 'Payout Processed');
    } catch (e) {
      debugPrint('processPayout error: $e');
      Get.snackbar('Error', 'Failed to process payout');
    }
  }

  Future<void> bulkProcessPayouts(List<String> ids, bool approved) async {
    try {
      await _repo.bulkProcessPayouts();
      fetchPayouts();
      fetchStats();
      Get.snackbar('Success', 'Bulk Payouts Processed');
    } catch (e) {
      debugPrint('bulkProcessPayouts error: $e');
      Get.snackbar('Error', 'Failed to process bulk payouts');
    }
  }

  Future<Map<String, dynamic>> getOrderDetail(String id) async {
    return await _repo.getOrderDetail(id);
  }

  Future<void> logout() async {
    // Implement logout logic
    Get.offAllNamed('/login');
  }
}
