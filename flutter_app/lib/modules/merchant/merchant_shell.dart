import 'package:flutter/material.dart';
import 'merchant_controller.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:greenbasket_app/data/services/storage_service.dart';
import 'package:greenbasket_app/data/services/socket_service.dart';
import 'package:flutter/services.dart';
import 'package:greenbasket_app/widgets/common/offline_banner.dart';
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

  Worker? _orderWorker;

  @override
  void initState() {
    super.initState();
    _nav.index.value = 0; // always start on Home after login
    // The Orders badge and the dashboard share one controller instance.
    if (!Get.isRegistered<MerchantController>()) {
      Get.put(MerchantController());
    }
    _orderWorker = ever(SocketService.to.newMerchantOrder, _onNewOrder);
  }

  @override
  void dispose() {
    _orderWorker?.dispose();
    super.dispose();
  }

  /// A new order arrived: make it impossible to miss.
  void _onNewOrder(Map<String, dynamic>? data) {
    if (data == null) return;
    final raw = data['order'];
    final order = raw is Map ? raw : data;
    final id = (order['orderId'] ?? order['orderNumber'] ?? '').toString();
    final total = order['totalAmount'] ?? order['total'];

    if (StorageService().orderAlertSound) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
    GBSnack.withAction(
      id.isEmpty ? 'New order' : 'New order #$id',
      total == null
          ? 'A customer just placed an order'
          : 'Total ${AppHelpers.formatCurrencyFlexible(total)}',
      actionLabel: 'View',
      position: SnackPosition.TOP,
      duration: const Duration(seconds: 15),
      onAction: () => MerchantNavController.goTo(1),
    );
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
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [OfflineBanner(), MerchantBottomNav()],
      ),
    );
  }
}
