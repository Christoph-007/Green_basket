import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/modules/merchant/merchant_controller.dart';
import '../settings/store_settings_screen.dart';
import '../zones/delivery_zones_screen.dart';
import '../widgets/merchant_drawer.dart';

class MerchantProfileScreen extends StatelessWidget {
  const MerchantProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MerchantController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Store Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Builder(
          builder: (context) {
            return IconButton(tooltip: 'Open menu', 
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: const MerchantDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Store header — loaded from real profile
            Obx(() {
              final storeName = controller.storeName.value;
              final rating = controller.rating.value;
              final isVerified = controller.isVerified.value;
              final initials = storeName.isNotEmpty
                  ? storeName
                      .split(' ')
                      .take(2)
                      .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                      .join()
                  : '??';

              return Container(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryLight, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName.isNotEmpty ? storeName : 'Your Store',
                            style: AppTextStyles.headlineLarge,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (rating > 0) ...[
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${rating.toStringAsFixed(1)} Rating',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Verified',
                                      style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text('Account Settings', style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  _profileCard(
                    context,
                    'Store Configuration',
                    'Update opening hours, alerts, and business details',
                    Icons.storefront,
                    AppColors.primary,
                    () => Get.to(() => const StoreSettingsScreen()),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _profileCard(
                    context,
                    'Delivery Map Zones',
                    'Configure service radius and standard delivery charges',
                    Icons.my_location,
                    Colors.teal,
                    () => Get.to(() => const DeliveryZonesScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleLarge),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary, height: 1.3)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.arrow_forward_ios,
                      color: AppColors.textHint, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
