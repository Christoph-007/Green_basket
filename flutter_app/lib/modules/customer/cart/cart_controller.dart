import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
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
    } catch (e) {
      GBSnack.fromError(e, title: 'Cart');
    }
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
      GBSnack.plain('Added to Cart', 'Item has been added to your cart', position: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
    } on DioException catch (e) {
      final body = e.response?.data;
      // One store per cart: offer to start a new cart with this item
      if (e.response?.statusCode == 409 && body is Map && body['code'] == 'DIFFERENT_MERCHANT') {
        _askToReplaceCart(productId, quantity, preparationOption, body['message']?.toString());
        return;
      }
      GBSnack.plain('Error', (body is Map ? body['message'] : null)?.toString() ?? 'Failed to add item to cart', position: SnackPosition.BOTTOM);
    } catch (_) {
      GBSnack.plain('Error', 'Failed to add item to cart', position: SnackPosition.BOTTOM);
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
              GBSnack.plain('Error', 'Could not clear the cart');
            }
          },
          child: const Text('Clear Cart & Add'),
        ),
      ],
    ));
  }

  /// The cart line with this product and preparation, if it is in the cart.
  CartItemModel? _findLine(String productId, String? preparation) {
    for (final line in items) {
      if (line.productId == productId && line.preparationOption == preparation) {
        return line;
      }
    }
    return null;
  }

  /// After a removal, offer to put the item back for a few seconds.
  void _offerUndo(CartItemModel line) {
    GBSnack.withAction(
      'Removed from cart',
      '${line.productName} was removed',
      actionLabel: 'Undo',
      position: SnackPosition.BOTTOM,
      onAction: () async {
        try {
          await _repo.addToCart(
            productId: line.productId,
            quantity: line.quantity,
            preparationOption: line.preparationOption,
          );
          await fetchCart();
        } catch (_) {
          GBSnack.error('Cart', 'Could not restore the item',
              position: SnackPosition.BOTTOM);
        }
      },
    );
  }

  Future<void> updateQuantity(String productId, int quantity,
      {String? preparation}) async {
    // Remember the line first, so a removal can be undone.
    final removedLine = quantity <= 0 ? _findLine(productId, preparation) : null;
    try {
      if (quantity <= 0) {
        await _repo.removeFromCart(productId, preparation: preparation);
      } else {
        await _repo.updateCartItem(
            productId: productId, quantity: quantity, preparation: preparation);
      }
      await fetchCart();
      if (removedLine != null) _offerUndo(removedLine);
    } on DioException catch (e) {
      final body = e.response?.data;
      GBSnack.plain('Cart', (body is Map ? body['message'] : null)?.toString() ?? 'Could not update the cart', position: SnackPosition.BOTTOM);
      await fetchCart();
    } catch (_) {}
  }

  Future<void> removeItem(String productId, {String? preparation}) async {
    final removedLine = _findLine(productId, preparation);
    try {
      await _repo.removeFromCart(productId, preparation: preparation);
      await fetchCart();
      if (removedLine != null) _offerUndo(removedLine);
    } catch (_) {
      GBSnack.error('Cart', 'Could not remove the item',
          position: SnackPosition.BOTTOM);
      await fetchCart();
    }
  }

  Future<void> applyCoupon(String code) async {
    try {
      final result = await _repo.applyCoupon(code);
      if (result['success'] == true) {
        appliedCoupon.value = code;
        discount.value = (result['data']?['discount'] ?? 0).toDouble();
        GBSnack.plain('Coupon Applied', 'Discount of ₹${discount.value.toInt()} applied');
      } else {
        GBSnack.plain('Invalid Coupon', result['message'] ?? 'Coupon not valid');
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
        GBSnack.plain('Error', result['message'] ?? 'Failed to redeem points');
      }
    } catch (_) {
      GBSnack.plain('Error', 'Failed to redeem loyalty points');
    }
  }

  Future<void> clearCoupon() async {
    try {
      await _repo.removeCoupon();
      appliedCoupon.value = '';
      discount.value = 0;
    } catch (_) {
      GBSnack.plain('Error', 'Failed to remove coupon');
    }
  }

  Future<void> clearCart() async {
    try {
      await _repo.clearCart();
      items.clear();
      await clearCoupon();
    } catch (_) {
      GBSnack.plain('Error', 'Failed to clear cart');
    }
  }
}
