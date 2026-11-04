import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_card.dart';
import 'package:greenbasket_app/widgets/common/offline_banner.dart';
import 'package:greenbasket_app/utils/responsive_helper.dart';
import 'package:greenbasket_app/widgets/common/lazy_indexed_stack.dart';
import 'package:get/get.dart';
import 'admin_controller.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'users/admin_users_screen.dart';
import 'merchants/admin_merchants_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'finance/admin_finance_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final _screens = [
    const AdminDashboardScreen(),
    const AdminUsersScreen(),
    const AdminMerchantsScreen(),
    const AdminOrdersScreen(),
    const AdminFinanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: ResponsiveHelper(context).maxContentWidth),
          child: LazyIndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
      const OfflineBanner(),
      Container(
        decoration: GBCard.decoration().copyWith(border: Border(top: BorderSide(color: AppColors.divider))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);
            if (i == 4 && Get.isRegistered<AdminController>()) {
              Get.find<AdminController>().fetchFinancialReport();
              Get.find<AdminController>().fetchStatement();
            }
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Merchants',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Finance',
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}
