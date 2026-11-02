import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/merchant_repository.dart';

class MerchantOrderController extends GetxController {
  final _repo = MerchantRepository();
  final isLoading = false.obs;

  final pendingOrders = <OrderModel>[].obs;
  final preparingOrders = <OrderModel>[].obs;
  final completedOrders = <OrderModel>[].obs;
  final cancelledOrders = <OrderModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllOrders();
  }

  Future<void> fetchAllOrders() async {
    try {
      isLoading.value = true;
      final all = await _repo.getMerchantOrders();

      pendingOrders.assignAll(all.where((o) => o.status == 'pending'));
      preparingOrders.assignAll(
          all.where((o) => ['confirmed', 'preparing', 'ready', 'out-for-delivery', 'dispatched'].contains(o.status)));
      completedOrders.assignAll(
          all.where((o) => o.status == 'delivered' || o.status == 'completed'));
      cancelledOrders.assignAll(
          all.where((o) => o.status == 'cancelled' || o.status == 'refunded'));
    } catch (e) {
      debugPrint('[MerchantOrderController] fetchAllOrders error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStatus(String orderId, String status) async {
    try {
      await _repo.updateOrderStatus(orderId, status);
      fetchAllOrders();
      Get.snackbar('Success', 'Order status updated to $status');
    } catch (e) {
      debugPrint('[MerchantOrderController] updateStatus error: $e');
      String msg = 'Failed to update order status';
      if (e is DioException && e.response?.data is Map) {
        msg = ((e.response!.data as Map)['message'] ?? msg).toString();
      }
      Get.snackbar('Error', msg);
    }
  }
}
