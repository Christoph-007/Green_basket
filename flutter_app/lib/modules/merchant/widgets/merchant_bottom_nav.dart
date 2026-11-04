import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../merchant_nav_controller.dart';

/// Bottom navigation for the merchant app. Used by [MerchantShell] and by
/// pages opened on top of it (set [highlight] to false there, because they
/// are not one of the five tabs).
class MerchantBottomNav extends StatelessWidget {
  final bool highlight;
  const MerchantBottomNav({super.key, this.highlight = true});

  @override
  Widget build(BuildContext context) {
    final nav = MerchantNavController.instance;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Obx(() => BottomNavigationBar(
            currentIndex: nav.index.value,
            onTap: MerchantNavController.goTo,
            selectedItemColor: highlight ? AppColors.primary : AppColors.textSecondary,
            unselectedItemColor: AppColors.textSecondary,
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
          )),
    );
  }
}
