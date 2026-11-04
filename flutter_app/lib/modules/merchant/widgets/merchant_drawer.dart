import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/config/routes.dart';
import 'package:greenbasket_app/modules/auth/auth_controller.dart';
import '../financial/financial_screen.dart';
import '../financial/payouts_screen.dart';
import '../offers/create_offer_screen.dart';
import '../offers/offer_analytics_screen.dart';
import '../offers/offers_screen.dart';
import '../settings/store_settings_screen.dart';
import '../orders/merchant_disputes_screen.dart';
import '../merchant_nav_controller.dart';

class MerchantDrawer extends StatelessWidget {
  const MerchantDrawer({super.key});

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
                       child: Icon(Icons.store_rounded,
                          color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text('Merchant Portal', style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
                _drawerGroup('Orders & Products'),
                _drawerItem(Icons.home_outlined, 'Home', () => MerchantNavController.goTo(0)),
                _drawerItem(Icons.list_alt, 'View Orders', () => MerchantNavController.goTo(1)),
                _drawerItem(Icons.gavel_outlined, 'Disputes', () => Get.to(() => const MerchantDisputesScreen())),
                _drawerItem(Icons.add_box, 'Add Product', () => Get.toNamed(Routes.merchantAddProduct)),
                _drawerItem(Icons.upload_file, 'Bulk Upload', () => Get.toNamed(Routes.merchantBulkUpload)),
                _drawerItem(Icons.edit, 'Inventory', () => MerchantNavController.goTo(2)),

                _drawerGroup('Finance & Analytics'),
                _drawerItem(Icons.account_balance_wallet, 'Financial', () => Get.to(() => const FinancialScreen())),
                _drawerItem(Icons.payments, 'Payouts', () => Get.to(() => const PayoutsScreen())),
                _drawerItem(Icons.bar_chart, 'Offer Analytics', () => Get.to(() => const OfferAnalyticsScreen())),
                
                _drawerGroup('Offers'),
                _drawerItem(Icons.local_offer, 'Offers', () => Get.to(() => const OffersScreen())),
                _drawerItem(Icons.add_circle, 'Create Offer', () => Get.to(() => const CreateOfferScreen())),

                _drawerGroup('Settings & profile'),
                _drawerItem(Icons.store, 'Store Settings', () => Get.to(() => const StoreSettingsScreen())),
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

  Widget _drawerGroup(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: AppTextStyles.bodyMedium),
      onTap: () {
        Get.back();
        onTap();
      },
      dense: true,
    );
  }
}
