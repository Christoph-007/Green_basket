import 'package:get/get.dart';

class NavController extends GetxController {
  static NavController get to => Get.find();
  
  final currentIndex = 0.obs;

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
}
