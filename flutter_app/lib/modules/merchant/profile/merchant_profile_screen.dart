import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_gradient_header.dart';
import 'package:greenbasket_app/widgets/common/theme_mode_selector.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/data/services/storage_service.dart';
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
      appBar: GBBrandAppBar(title: 'Store Profile', showMenu: true),
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
                decoration: BoxDecoration(
                  color: AppColors.surface,
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
                          style: AppTextStyles.displayMedium.copyWith(color: AppColors.primaryText),
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
                                        AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Verified',
                                      style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
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
                  const SizedBox(height: AppSpacing.md),
                  const _AlertSoundCard(),
                  const SizedBox(height: AppSpacing.md),
                  const ThemeModeSelector(),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                    color: color.withValues(alpha: 0.1),
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
                Padding(
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

/// Switch for the sound and vibration played when a new order arrives.
class _AlertSoundCard extends StatefulWidget {
  const _AlertSoundCard();

  @override
  State<_AlertSoundCard> createState() => _AlertSoundCardState();
}

class _AlertSoundCardState extends State<_AlertSoundCard> {
  final _storage = StorageService();
  late bool _on = _storage.orderAlertSound;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        secondary: Icon(Icons.notifications_active_outlined,
            color: AppColors.primaryText),
        title: Text('New order alert sound',
            style: AppTextStyles.titleLarge),
        subtitle: Text(
          'Play a sound and vibrate when an order arrives',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary, height: 1.3),
        ),
        value: _on,
        onChanged: (value) {
          setState(() => _on = value);
          _storage.setOrderAlertSound(value);
        },
      ),
    );
  }
}
