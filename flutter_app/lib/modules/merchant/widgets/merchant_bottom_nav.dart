import 'package:flutter/material.dart';
import '../merchant_controller.dart';
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
      decoration: BoxDecoration(
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
                icon: _OrdersIcon(active: false),
                activeIcon: _OrdersIcon(active: true),
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

/// The Orders tab icon with a count of orders waiting for the seller.
class _OrdersIcon extends StatelessWidget {
  final bool active;
  const _OrdersIcon({required this.active});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(active ? Icons.shopping_bag : Icons.shopping_bag_outlined);
    // Pages opened before the merchant controller exists just show the icon.
    if (!Get.isRegistered<MerchantController>()) return icon;
    final controller = Get.find<MerchantController>();
    return Obx(() {
      final count = controller.pendingCount.value;
      return Semantics(
        label: count > 0 ? 'Orders, $count waiting' : 'Orders',
        excludeSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            icon,
            if (count > 0)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
