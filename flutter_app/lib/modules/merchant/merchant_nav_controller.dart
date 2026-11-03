import 'package:get/get.dart';
import 'package:greenbasket_app/config/routes.dart';
import 'merchant_controller.dart';
import 'products/merchant_product_controller.dart';

/// Holds the selected tab of the merchant bottom navigation
/// (0 Home, 1 Orders, 2 Products, 3 Analytics, 4 Profile).
class MerchantNavController extends GetxController {
  final index = 0.obs;

  static MerchantNavController get instance => Get.isRegistered<MerchantNavController>()
      ? Get.find<MerchantNavController>()
      : Get.put(MerchantNavController(), permanent: true);

  /// Switch to a tab from anywhere (drawer, bottom bar, sub-pages).
  /// Any pushed page (Financial, Offers, ...) is closed so the shell shows.
  static void goTo(int i) {
    instance.index.value = i;
    Get.until((route) => route.isFirst || route.settings.name == Routes.merchantDashboard);

    if (i == 0 && Get.isRegistered<MerchantController>()) {
      Get.find<MerchantController>().fetchStats();
      Get.find<MerchantController>().fetchNewOrders();
    } else if (i == 2 && Get.isRegistered<MerchantProductController>()) {
      Get.find<MerchantProductController>().fetchProducts();
    }
  }
}
