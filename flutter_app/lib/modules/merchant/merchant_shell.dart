import 'package:flutter/material.dart';
import 'package:greenbasket_app/utils/responsive_helper.dart';
import 'package:greenbasket_app/widgets/common/lazy_indexed_stack.dart';
import 'package:get/get.dart';
import 'dashboard/merchant_dashboard_screen.dart';
import 'orders/merchant_orders_screen.dart';
import 'products/merchant_products_screen.dart';
import 'analytics/merchant_analytics_screen.dart';
import 'profile/merchant_profile_screen.dart';
import 'merchant_nav_controller.dart';
import 'widgets/merchant_bottom_nav.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key});

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  final _nav = MerchantNavController.instance;

  final _screens = [
    const MerchantDashboardScreen(),
    const MerchantOrdersScreen(),
    const MerchantProductsScreen(),
    const MerchantAnalyticsScreen(),
    const MerchantProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _nav.index.value = 0; // always start on Home after login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: ResponsiveHelper(context).maxContentWidth),
          child: Obx(() => LazyIndexedStack(
                index: _nav.index.value,
                children: _screens,
              )),
        ),
      ),
      bottomNavigationBar: const MerchantBottomNav(),
    );
  }
}
