import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/models/order_model.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:greenbasket_app/modules/auth/auth_controller.dart';
import 'package:greenbasket_app/modules/merchant/merchant_controller.dart';

import '../widgets/merchant_drawer.dart';
import '../orders/merchant_disputes_screen.dart';
import '../merchant_nav_controller.dart';

part 'merchant_dashboard_screen_sections1.dart';
part 'merchant_dashboard_screen_sections2.dart';
part 'merchant_dashboard_screen_sections3.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  final controller = Get.put(MerchantController());
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const MerchantDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              controller.fetchProfile(),
              controller.fetchStats(),
              controller.fetchNewOrders(),
              controller.fetchActiveOrders(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildQuickStats(),
                _buildAttentionRow(),
                _buildDisputesAlert(),
                _buildOrderStatusCards(),
                _buildNewOrders(),
                _buildActiveOrders(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color, IconData) _getStatusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return ('Confirmed', Colors.blue, Icons.check_circle_outline);
      case 'ready':
        return ('Ready', Colors.purple, Icons.inventory_2_outlined);
      case 'dispatched':
      case 'out-for-delivery':
        return ('Ready to pick up', Colors.teal, Icons.shopping_bag_outlined);
      case 'delivered':
        return ('Delivered', AppColors.success, Icons.done_all);
      default:
        return ('Pending', Colors.orange, Icons.schedule);
    }
  }

}
