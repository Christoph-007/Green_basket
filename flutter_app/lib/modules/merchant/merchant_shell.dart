import 'package:flutter/material.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'dashboard/merchant_dashboard_screen.dart';
import 'orders/merchant_orders_screen.dart';
import 'products/merchant_products_screen.dart';
import 'analytics/merchant_analytics_screen.dart';
import 'profile/merchant_profile_screen.dart';
import 'package:get/get.dart';
import 'merchant_controller.dart';
import 'products/merchant_product_controller.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key});

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int _currentIndex = 0;

  final _screens = [
    const MerchantDashboardScreen(),
    const MerchantOrdersScreen(),
    const MerchantProductsScreen(),
    const MerchantAnalyticsScreen(),
    const MerchantProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);
            if (i == 0 && Get.isRegistered<MerchantController>()) {
              Get.find<MerchantController>().fetchStats();
              Get.find<MerchantController>().fetchNewOrders();
            } else if (i == 2 && Get.isRegistered<MerchantProductController>()) {
              Get.find<MerchantProductController>().fetchProducts();
            }
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
