// End-to-end check that the app's real repositories work against the real
// backend: requests match the routes AND the app parses the responses.
//
// Skipped unless API_URL is given. To run:
//   cd backend && MONGODB_URI=mongodb://127.0.0.1:27017/gb_e2e node scripts/seed-e2e.js
//   MONGODB_URI=mongodb://127.0.0.1:27017/gb_e2e PORT=5002 node server.js
//   cd flutter_app && flutter test test/api_integration_test.dart \
//       --dart-define=API_URL=http://127.0.0.1:5002/api
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:greenbasket_app/config/constants.dart';
import 'package:greenbasket_app/data/repositories/auth_repository.dart';
import 'package:greenbasket_app/data/repositories/merchant_repository.dart';
import 'package:greenbasket_app/data/repositories/order_repository.dart';
import 'package:greenbasket_app/data/repositories/product_repository.dart';
import 'package:greenbasket_app/data/repositories/referral_repository.dart';
import 'package:greenbasket_app/data/repositories/wallet_repository.dart';

const apiUrl = String.fromEnvironment('API_URL');

Future<void> loginAs(String email) async {
  final res = await AuthRepository().login(email: email, password: 'password123');
  expect(res['success'], isTrue, reason: 'login $email');
  GetStorage().write(AppConstants.tokenKey, res['token']);
  GetStorage().write(AppConstants.refreshTokenKey, res['refreshToken']);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null; // real network to the local backend
    final dir = await Directory.systemTemp.createTemp('gb_test_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    await GetStorage.init();
  });

  group('Flutter repositories ↔ backend', () {
    late String productId;
    late String orderId;

    test('customer: products, cart with preparation, quote, checkout, cancel', () async {
      await loginAs('e2e.customer@greenbasket.test');
      final orderRepo = OrderRepository();

      final products = await ProductRepository().getProducts();
      final tomato = products.firstWhere((p) => p.name == 'E2E Tomato');
      productId = tomato.id;

      // Category filtering, as the Categories tab uses it
      final categories = await ProductRepository().getCategories();
      final veg = categories.firstWhere((c) => c.name == 'Vegetables');
      final inVeg = await ProductRepository().getProducts(categoryId: veg.id);
      expect(inVeg.map((p) => p.id), contains(productId));
      expect(inVeg.every((p) => p.categoryId == veg.id), isTrue);
      final nearbyVeg = await ProductRepository()
          .getNearbyProducts(lat: 13.09, lng: 80.27, radius: 10, categoryId: veg.id);
      expect((nearbyVeg['products'] as List).isNotEmpty, isTrue);
      final allVeg = await ProductRepository()
          .getNearbyProducts(lat: 0, lng: 0, categoryId: veg.id, allProducts: true);
      expect((allVeg['products'] as List).isNotEmpty, isTrue);

      await orderRepo.clearCart();
      await orderRepo.addToCart(productId: productId, quantity: 2, preparationOption: 'chopped');
      final cart = await orderRepo.getCartModel();
      expect(cart.items, hasLength(1));
      expect(cart.items.first.price, 120); // 100 + 20 chopped
      expect(cart.items.first.preparationOption, 'chopped');

      // Quantity update must hit the "chopped" line
      await orderRepo.updateCartItem(productId: productId, quantity: 3, preparation: 'chopped');
      expect((await orderRepo.getCartModel()).items.first.quantity, 3);

      // Coupon is re-validated by the server and visible in the cart
      await orderRepo.applyCoupon('E2E10');
      final withCoupon = await orderRepo.getCartModel();
      expect(withCoupon.couponCode, 'E2E10');
      expect(withCoupon.couponDiscount, 10);

      // Quotes
      final pickup = await orderRepo.quoteOrder(deliveryType: 'pickup', couponCode: 'E2E10');
      expect(pickup['itemsTotal'], 360);
      expect(pickup['deliveryCharges'], 0);
      expect(pickup['totalAmount'], 350);

      await expectLater(
        orderRepo.quoteOrder(deliveryType: 'home-delivery'),
        throwsA(isA<DioException>().having((e) => e.response?.data['code'], 'code', 'ADDRESS_REQUIRED')),
      );

      final addresses = await orderRepo.getAddresses();
      expect(addresses, isNotEmpty);
      final delivery = await orderRepo.quoteOrder(
          deliveryType: 'home-delivery', addressId: addresses.first.id, couponCode: 'E2E10');
      expect(delivery['deliveryCharges'], 20); // "Near" zone
      expect(delivery['totalAmount'], 370);

      // Place the order exactly as the checkout screen does
      final placed = await orderRepo.checkout(
        addressId: addresses.first.id,
        paymentMethod: 'cod',
        deliveryType: 'home-delivery',
        couponCode: 'E2E10',
      );
      expect(placed['success'], isTrue);
      final order = placed['data']['order'];
      expect(order['totalAmount'], delivery['totalAmount']); // quote == charge
      orderId = order['_id'];

      final mine = await orderRepo.getOrders();
      expect(mine.any((o) => o.id == orderId), isTrue);
      final detail = await orderRepo.getOrder(orderId);
      expect(detail.deliveryType, 'home-delivery');

      // Real cancellation (the button used to only show a snackbar)
      final cancelled = await orderRepo.cancelOrder(orderId, 'integration test');
      expect(cancelled['success'], isTrue);
      expect((await orderRepo.getOrder(orderId)).status, 'cancelled');
    });

    test('customer: wallet and referral screens get real data', () async {
      await loginAs('e2e.customer@greenbasket.test');
      final wallet = await WalletRepository().getWallet();
      expect(wallet.balance, isA<double>());
      expect(await WalletRepository().getTransactions(), isA<List>());

      final referral = await ReferralRepository().getOrCreateCode();
      expect(referral['referralCode'], isNotEmpty);
      final stats = await ReferralRepository().getStats();
      expect(stats['stats'], isA<Map>());
    });

    test('merchant: delivery zones round-trip with the app field names', () async {
      await loginAs('e2e.merchant@greenbasket.test');
      final repo = MerchantRepository();
      final before = await repo.getDeliveryZones();
      expect(before.first['radius'], isNotNull); // mapped from radiusKm

      await repo.createZone({'name': 'Far', 'radius': 25.0, 'charge': 90, 'minOrder': 300, 'active': true});
      final zones = await repo.getDeliveryZones();
      final far = zones.firstWhere((z) => z['name'] == 'Far');
      expect(far['radius'], 25);
      expect(far['charge'], 90);
      expect(far['minOrder'], 300);

      await repo.toggleZone(far['_id'], false);
      final toggled = (await repo.getDeliveryZones()).firstWhere((z) => z['name'] == 'Far');
      expect(toggled['active'], isFalse);
      await repo.deleteZone(far['_id']);
    });
  }, skip: apiUrl.isEmpty ? 'Set --dart-define=API_URL=... to run against a backend' : false);
}
