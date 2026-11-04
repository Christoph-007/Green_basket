import 'package:get/get.dart';

class NavController extends GetxController {
  static NavController get to => Get.find();

  /// Bottom-tab indexes in CustomerShell
  static const homeTab = 0;
  static const categoriesTab = 1;
  static const cartTab = 3;

  final currentIndex = 0.obs;

  /// Category requested before the Categories tab's controller existed;
  /// CategoriesController consumes it when it starts.
  String? pendingCategoryId;

  /// Called whenever a category should be shown on the Categories tab.
  /// CategoriesController registers this to react while it is alive.
  void Function(String categoryId)? onCategoryRequested;

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  /// Helper to go to a specific tab in the customer shell
  void toTab(int index) {
    if (Get.currentRoute != '/customer/home') {
      Get.until((route) => Get.currentRoute == '/customer/home');
    }
    changeIndex(index);
  }

  /// Open the Categories tab, optionally with a category selected.
  ///
  /// The Categories screen is a tab of the customer shell. Pushing it as a
  /// separate route (as before) reused the tab's existing controller, so the
  /// requested category was ignored and "All" was shown.
  void openCategories({String? categoryId}) {
    final id = categoryId ?? '';
    toTab(categoriesTab);
    if (onCategoryRequested != null) {
      onCategoryRequested!(id);
    } else {
      pendingCategoryId = id;
    }
  }
}
