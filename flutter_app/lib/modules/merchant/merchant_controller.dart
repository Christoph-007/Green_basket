import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/repositories/merchant_repository.dart';
import '../../data/models/order_model.dart';
import '../../data/services/socket_service.dart';

class MerchantController extends GetxController {
  final _repo = MerchantRepository();
  final isLoading = false.obs;
  final isStoreOpen = true.obs;

  final revenue = '₹0'.obs;
  final orderCount = 0.obs;
  final rating = 0.0.obs;
  final storeName = ''.obs;
  final isVerified = false.obs;

  // Additional dashboard stats
  final totalOrders = 0.obs;
  final totalRevenue = 0.obs;
  final pendingCount = 0.obs;
  final confirmedCount = 0.obs;
  final processingCount = 0.obs;
  final deliveredCount = 0.obs;
  final cancelledCount = 0.obs;
  final totalProducts = 0.obs;
  final activeProducts = 0.obs;
  final lowStockProducts = 0.obs;
  final avgOrderValue = 0.0.obs;
  final disputeCount = 0.obs;

  final newOrders = <OrderModel>[].obs;
  final activeOrders = <OrderModel>[].obs;

  Worker? _newOrderWorker;
  Worker? _orderPaidWorker;
  Worker? _orderCountWorker;
  Worker? _stockWorker;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    fetchStats();
    fetchNewOrders();
    fetchActiveOrders();
    _listenToSocket();
  }

  void _listenToSocket() {
    final socket = SocketService.to;

    // Refresh pending orders when a new order arrives
    _newOrderWorker = ever(socket.newMerchantOrder, (data) {
      if (data != null) fetchNewOrders();
    });

    // An online order was paid: it is now a real order to prepare
    _orderPaidWorker = ever(socket.orderPaid, (data) {
      if (data == null) return;
      fetchNewOrders();
      final order = data['order'] is Map ? data['order'] as Map : data;
      Get.snackbar('Payment received',
          'Order ${order['orderId'] ?? ''} has been paid online',
          snackPosition: SnackPosition.TOP);
    });

    // Update dashboard order counts in real time
    _orderCountWorker = ever(socket.merchantOrderCount, (data) {
      if (data != null) {
        final pending = data['pendingOrders'] ?? data['activeOrders'];
        if (pending is int) orderCount.value = pending;
      }
    });

    // Show snackbar on low-stock / out-of-stock alerts
    _stockWorker = ever(socket.lowStockAlert, (data) {
      if (data == null) return;
      final productName = data['product']?['name'] ?? 'A product';
      final type = data['type'] ?? 'LOW_STOCK';
      final msg = type == 'OUT_OF_STOCK'
          ? '$productName is out of stock!'
          : '$productName is running low (${data['currentStock']} left)';
      Get.snackbar('Inventory Alert', msg, snackPosition: SnackPosition.TOP);
    });
  }

  @override
  void onClose() {
    _newOrderWorker?.dispose();
    _orderPaidWorker?.dispose();
    _orderCountWorker?.dispose();
    _stockWorker?.dispose();
    super.onClose();
  }

  Future<void> fetchProfile() async {
    try {
      final result = await _repo.getProfile();
      final data = result['data'] ?? result;
      storeName.value =
          data['storeName'] ?? data['businessName'] ?? data['name'] ?? '';
      isVerified.value = data['isVerified'] ?? data['verified'] ?? false;
      isStoreOpen.value = data['isStoreOpen'] ?? data['isOpen'] ?? true;
    } catch (e) {
      debugPrint('[MerchantController] fetchProfile error: $e');
    }
  }

  Future<void> fetchStats() async {
    try {
      isLoading.value = true;
      final stats = await _repo.getDashboardStats();
      final data = stats['data'] ?? stats;
      revenue.value = '₹${data['todayRevenue'] ?? data['revenue'] ?? 0}';
      orderCount.value = data['todayOrders'] ?? data['orders'] ?? 0;
      rating.value =
          ((data['storeRating'] ?? data['rating'] ?? 0.0) as num).toDouble();
      isStoreOpen.value =
          data['isStoreOpen'] ?? data['isOpen'] ?? isStoreOpen.value;

      // Additional stats
      totalOrders.value = data['totalOrders'] ?? 0;
      totalRevenue.value = data['totalRevenue'] ?? 0;
      pendingCount.value = data['pendingOrders'] ?? 0;
      confirmedCount.value = data['confirmedOrders'] ?? 0;
      processingCount.value = data['processingOrders'] ?? 0;
      deliveredCount.value = data['deliveredOrders'] ?? 0;
      cancelledCount.value = data['cancelledOrders'] ?? 0;
      totalProducts.value = data['totalProducts'] ?? 0;
      activeProducts.value = data['activeProducts'] ?? 0;
      lowStockProducts.value = data['lowStockProducts'] ?? 0;
      disputeCount.value = data['disputeCount'] ?? data['openDisputes'] ?? 0;
      avgOrderValue.value =
          ((data['averageOrderValue'] ?? 0) as num).toDouble();
    } catch (e) {
      debugPrint('[MerchantController] fetchStats error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchNewOrders() async {
    try {
      final orders = await _repo.getMerchantOrders(status: 'pending');
      newOrders.assignAll(orders);
    } catch (e) {
      debugPrint('[MerchantController] fetchNewOrders error: $e');
    }
  }

  Future<void> fetchActiveOrders() async {
    try {
      final all = await _repo.getMerchantOrders();
      activeOrders.assignAll(
        all.where((o) => ['confirmed', 'ready', 'out-for-delivery', 'dispatched'].contains(o.status)),
      );
    } catch (e) {
      debugPrint('[MerchantController] fetchActiveOrders error: $e');
    }
  }

  Future<void> toggleStoreStatus(bool? val) async {
    try {
      await _repo.toggleStoreStatus();
      isStoreOpen.toggle();
    } catch (e) {
      debugPrint('[MerchantController] toggleStoreStatus error: $e');
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      await _repo.updateOrderStatus(orderId, 'confirmed');
      fetchNewOrders();
      Get.snackbar('Success', 'Order accepted successfully');
    } catch (e) {
      debugPrint('[MerchantController] acceptOrder error: $e');
      Get.snackbar('Error', 'Failed to accept order');
    }
  }

  Future<void> declineOrder(String orderId) async {
    try {
      await _repo.updateOrderStatus(orderId, 'cancelled');
      fetchNewOrders();
      Get.snackbar('Order Declined', 'Order has been cancelled');
    } catch (e) {
      debugPrint('[MerchantController] declineOrder error: $e');
      Get.snackbar('Error', 'Failed to decline order');
    }
  }
}
