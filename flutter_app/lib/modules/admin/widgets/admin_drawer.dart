import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/modules/auth/auth_controller.dart';
import '../products/admin_products_screen.dart';
import '../products/admin_categories_screen.dart';
import '../products/admin_recipes_screen.dart';
import '../orders/returns_admin_screen.dart';
import '../orders/disputes_admin_screen.dart';
import '../offers/admin_offers_screen.dart';
import '../finance/admin_payouts_screen.dart';
import '../finance/commission_settings_screen.dart';
import '../notifications/admin_notifications_screen.dart';
import '../settings/admin_settings_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppColors.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        maxRadius: 30,
                        child: Icon(Icons.shield, color: AppColors.primary, size: 30),
                      ),
                      const SizedBox(height: 12),
                      Text('Admin Portal', style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
                _drawerItem(Icons.inventory_2_outlined, 'Products', () => Get.to(() => const AdminProductsScreen())),
                _drawerItem(Icons.category_outlined, 'Categories', () => Get.to(() => const AdminCategoriesScreen())),
                _drawerItem(Icons.set_meal_outlined, 'Recipes', () => Get.to(() => const AdminRecipesScreen())),
                const Divider(),
                _drawerItem(Icons.keyboard_return, 'Returns', () => Get.to(() => const ReturnsAdminScreen())),
                _drawerItem(Icons.gavel_outlined, 'Disputes', () => Get.to(() => const DisputesAdminScreen())),
                const Divider(),
                _drawerItem(Icons.local_offer_outlined, 'Offers', () => Get.to(() => const AdminOffersScreen())),

                const Divider(),
                _drawerItem(Icons.payment, 'Payouts', () => Get.to(() => const AdminPayoutsScreen())),
                _drawerItem(Icons.percent, 'Commissions', () => Get.to(() => const CommissionSettingsScreen())),
                const Divider(),
                _drawerItem(Icons.notifications_outlined, 'Notifications', () => Get.to(() => const AdminNotificationsScreen())),
                _drawerItem(Icons.settings_outlined, 'Settings', () => Get.to(() => const AdminSettingsScreen())),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Get.back(); // close drawer
              Get.find<AuthController>().logout();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: AppTextStyles.bodyMedium),
      onTap: () {
        Get.back(); // close drawer
        onTap();
      },
      dense: true,
    );
  }
}
