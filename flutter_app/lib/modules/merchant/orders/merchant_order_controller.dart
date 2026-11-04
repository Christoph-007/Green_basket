import 'package:dio/dio.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
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
      // Anything not yet completed stays in Pending / Preparing
      // (accepted, preparing, ready, out for delivery, delivered-awaiting-completion).
      preparingOrders.assignAll(all.where((o) => [
            'confirmed',
            'preparing',
            'ready',
            'out-for-delivery',
            'dispatched',
            'delivered'
          ].contains(o.status)));
      completedOrders.assignAll(all.where((o) => o.status == 'completed'));
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
      GBSnack.plain('Success', 'Order status updated to $status');
    } catch (e) {
      debugPrint('[MerchantOrderController] updateStatus error: $e');
      String msg = 'Failed to update order status';
      if (e is DioException && e.response?.data is Map) {
        msg = ((e.response!.data as Map)['message'] ?? msg).toString();
      }
      GBSnack.plain('Error', msg);
    }
  }
}
