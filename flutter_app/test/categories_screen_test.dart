// Categories tab: the selected chip must follow taps, the grid must show the
// selected category's products (even when responses arrive out of order),
// and a category requested from another screen must be selected.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:greenbasket_app/data/models/product_model.dart';
import 'package:greenbasket_app/data/repositories/product_repository.dart';
import 'package:greenbasket_app/modules/customer/cart/cart_controller.dart';
import 'package:greenbasket_app/modules/customer/nav_controller.dart';
import 'package:greenbasket_app/modules/customer/products/categories_screen.dart';
import 'package:greenbasket_app/modules/customer/profile/wishlist_controller.dart';

ProductModel product(String id, String name, String categoryId) =>
    ProductModel.fromJson({
      '_id': id,
      'name': name,
      'price': 50,
      'stock': 10,
      'unit': 'kg',
      'category': {'_id': categoryId, 'name': categoryId},
      'merchant': {'_id': 'm1', 'businessName': 'Farm'},
    });

/// Serves products per category; Dairy answers slowly, Fruits quickly.
class FakeProductRepository extends ProductRepository {
  final requested = <String?>[];

  @override
  Future<List<CategoryModel>> getCategories() async => [
    CategoryModel(id: 'dairy', name: 'Dairy'),
    CategoryModel(id: 'fruits', name: 'Fruits'),
  ];

  @override
  Future<Map<String, dynamic>> getNearbyProducts({
    required double lat,
    required double lng,
    double radius = 5,
    String? categoryId,
    String? search,
    String sort = 'score',
    int page = 1,
    int limit = 20,
    bool allProducts = false,
  }) async {
    requested.add(categoryId);
    final all = [
      product('p1', 'Milk', 'dairy'),
      product('p2', 'Paneer', 'dairy'),
      product('p3', 'Mango', 'fruits'),
    ];
    await Future.delayed(
      Duration(milliseconds: categoryId == 'dairy' ? 300 : 50),
    );
    return {
      'products': categoryId == null
          ? all
          : all.where((p) => p.categoryId == categoryId).toList(),
      'actual_radius_km': radius,
    };
  }
}

/// Chip label colour is white only for the selected chip.
bool isSelected(WidgetTester tester, String label) {
  final text = tester.widget<Text>(find.text(label).first);
  return text.style?.color == Colors.white;
}

/// Pump until [condition] holds. Lets real time pass too (storage reads
/// don't advance on the test's fake clock), so the test doesn't depend on
/// how long the first load takes.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  String reason = '',
}) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for: $reason');
}

bool shows(String text) => find.text(text).evaluate().isNotEmpty;

void main() {
  late FakeProductRepository repo;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('gb_cat_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dir.path,
        );
    await GetStorage.init();
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();
    repo = FakeProductRepository();
    Get.put(NavController());
    Get.put(CartController());
    Get.put(WishlistController());
  });

  // One app instance for all on-screen scenarios: rebuilding GetMaterialApp
  // per test makes GetX dispose the previous screen's controller late, in
  // the middle of the next test.
  testWidgets(
    'category chips: highlight, products, out-of-order responses, requests from other tabs',
    (tester) async {
      // Tall screen so the whole product grid is laid out
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Get.put(CategoriesController(repository: repo));
      await tester.pumpWidget(const GetMaterialApp(home: CategoriesScreen()));
      await pumpUntil(
        tester,
        () => shows('Mango') && shows('Milk'),
        reason: 'initial products',
      );

      // Starts on "All"
      expect(isSelected(tester, 'All'), isTrue);
      expect(find.text('Mango'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);

      // Tapping a chip highlights it immediately and shows only its products
      await tester.tap(find.text('Fruits'));
      await tester.pump();
      expect(isSelected(tester, 'Fruits'), isTrue);
      expect(isSelected(tester, 'All'), isFalse);
      await pumpUntil(
        tester,
        () => shows('Mango') && !shows('Milk'),
        reason: 'fruits products',
      );
      expect(find.text('Mango'), findsOneWidget);

      // A slow older response (Dairy, 300 ms) must not overwrite a newer
      // selection (All, then Fruits again)
      await tester.tap(find.text('Dairy'));
      await tester.pump();
      await tester.tap(find.text('Fruits'));
      // Wait until both requests have answered, then check the newer one won
      await pumpUntil(
        tester,
        () =>
            repo.requested.length >= 4 &&
            !Get.find<CategoriesController>().isLoading.value,
        reason: 'both requests',
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(isSelected(tester, 'Fruits'), isTrue);
      expect(find.text('Mango'), findsOneWidget);
      expect(find.text('Milk'), findsNothing);
      expect(find.text('Paneer'), findsNothing);

      // Another screen (e.g. Home) asks for Dairy while the tab is alive
      Get.find<NavController>().onCategoryRequested!('dairy');
      await pumpUntil(tester, () => shows('Milk'), reason: 'dairy products');
      expect(isSelected(tester, 'Dairy'), isTrue);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Paneer'), findsOneWidget);
      expect(find.text('Mango'), findsNothing);
    },
  );

  test(
    'a category requested before the tab existed is selected on start',
    () async {
      // e.g. tapping "Dairy" on the home screen before Categories was opened
      Get.find<NavController>().pendingCategoryId = 'dairy';
      final ctrl = Get.put(CategoriesController(repository: repo));
      await Future.delayed(const Duration(milliseconds: 600));
      expect(ctrl.selectedCategoryId.value, 'dairy');
      expect(ctrl.products.map((p) => p.name), ['Milk', 'Paneer']);
      expect(Get.find<NavController>().pendingCategoryId, isNull);
    },
  );
}
