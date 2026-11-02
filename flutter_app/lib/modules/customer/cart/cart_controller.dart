import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/loyalty_repository.dart';

class CartController extends GetxController {
  final _repo = OrderRepository();
  final _loyaltyRepo = LoyaltyRepository();

  final items = <CartItemModel>[].obs;
  final isLoading = false.obs;
  final appliedCoupon = ''.obs;
  final discount = 0.0.obs;

  final deliveryType = 'pickup'.obs;
  final loyaltyPoints = 0.obs;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.itemTotal);
  double get deliveryFee => 0;
  double get total => subtotal + deliveryFee - discount.value;

  @override
  void onInit() {
    super.onInit();
    fetchCart();
    fetchLoyaltyPoints();
  }

  Future<void> fetchCart() async {
    isLoading.value = true;
    try {
      final cart = await _repo.getCartModel();
      items.value = cart.items;
      // The server re-validates the coupon whenever the cart changes
      appliedCoupon.value = cart.couponCode ?? '';
      discount.value = cart.couponDiscount;
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> fetchLoyaltyPoints() async {
    try {
      final res = await _loyaltyRepo.getLoyaltyInfo();
      loyaltyPoints.value = res.points;
    } catch (_) {}
  }

  Future<void> addItem({
    required String productId,
    required int quantity,
    String? preparationOption,
  }) async {
    try {
      await _repo.addToCart(
        productId: productId,
        quantity: quantity,
        preparationOption: preparationOption,
      );
      await fetchCart();
      Get.snackbar(
        'Added to Cart',
        'Item has been added to your cart',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      // One store per cart: offer to start a new cart with this item
      if (e.response?.statusCode == 409 && body is Map && body['code'] == 'DIFFERENT_MERCHANT') {
        _askToReplaceCart(productId, quantity, preparationOption, body['message']?.toString());
        return;
      }
      Get.snackbar('Error',
          (body is Map ? body['message'] : null)?.toString() ?? 'Failed to add item to cart',
          snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Error', 'Failed to add item to cart',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _askToReplaceCart(String productId, int quantity, String? preparationOption, String? message) {
    Get.dialog(AlertDialog(
      title: const Text('Start a new cart?'),
      content: Text(message ??
          'Your cart has items from another store. An order can only contain items from one store.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Keep Cart')),
        TextButton(
          onPressed: () async {
            Get.back();
            try {
              await _repo.clearCart();
              appliedCoupon.value = '';
              discount.value = 0;
              await addItem(
                productId: productId,
                quantity: quantity,
                preparationOption: preparationOption,
              );
            } catch (_) {
              Get.snackbar('Error', 'Could not clear the cart');
            }
          },
          child: const Text('Clear Cart & Add'),
        ),
      ],
    ));
  }

  Future<void> updateQuantity(String productId, int quantity,
      {String? preparation}) async {
    try {
      if (quantity <= 0) {
        await _repo.removeFromCart(productId, preparation: preparation);
      } else {
        await _repo.updateCartItem(
            productId: productId, quantity: quantity, preparation: preparation);
      }
      await fetchCart();
    } on DioException catch (e) {
      final body = e.response?.data;
      Get.snackbar('Cart',
          (body is Map ? body['message'] : null)?.toString() ?? 'Could not update the cart',
          snackPosition: SnackPosition.BOTTOM);
      await fetchCart();
    } catch (_) {}
  }

  Future<void> removeItem(String productId, {String? preparation}) async {
    try {
      await _repo.removeFromCart(productId, preparation: preparation);
      await fetchCart();
    } catch (_) {}
  }

  Future<void> applyCoupon(String code) async {
    try {
      final result = await _repo.applyCoupon(code);
      if (result['success'] == true) {
        appliedCoupon.value = code;
        discount.value = (result['data']?['discount'] ?? 0).toDouble();
        Get.snackbar(
            'Coupon Applied', 'Discount of ₹${discount.value.toInt()} applied');
      } else {
        Get.snackbar('Invalid Coupon', result['message'] ?? 'Coupon not valid');
      }
    } catch (e) {
      String message = 'Failed to apply coupon';
      if (e is DioException) {
        message = e.response?.data?['message'] ?? e.response?.data?['error'] ?? message;
      }
      Get.snackbar('Error', message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer);
    }
  }

  Future<void> redeemLoyaltyPoints(int points) async {
    try {
      final result = await _loyaltyRepo.redeemPoints(points: points);
      if (result['success'] == true) {
        final code = result['data']?['couponCode'];
        if (code != null) {
          await applyCoupon(code);
          await fetchLoyaltyPoints();
        }
      } else {
        Get.snackbar('Error', result['message'] ?? 'Failed to redeem points');
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to redeem loyalty points');
    }
  }

  Future<void> clearCoupon() async {
    try {
      await _repo.removeCoupon();
      appliedCoupon.value = '';
      discount.value = 0;
    } catch (_) {
      Get.snackbar('Error', 'Failed to remove coupon');
    }
  }

  Future<void> clearCart() async {
    try {
      await _repo.clearCart();
      items.clear();
      await clearCoupon();
    } catch (_) {
      Get.snackbar('Error', 'Failed to clear cart');
    }
  }
}
