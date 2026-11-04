import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/theme_mode_selector.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../utils/helpers.dart';
import '../../../modules/auth/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Profile', showBack: false),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(20),
              child: Obx(() {
                final user = authCtrl.user.value;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'G',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User',
                            style: AppTextStyles.headlineMedium,
                          ),
                          Text(
                            user?.email ?? '',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _TierBadge(tier: user?.loyaltyTier ?? 'bronze'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(tooltip: 'Edit', 
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                      ),
                      onPressed: () => Get.toNamed(Routes.editProfile),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),

            // Stats row
            Obx(() {
              // ignore: unused_local_variable
              final user = authCtrl.user.value;
              return Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _StatItem(
                      label: 'Orders',
                      value: 'View',
                      icon: Icons.receipt_long_outlined,
                      onTap: () => Get.toNamed(Routes.orderList),
                    ),
                    _Divider(),
                    _StatItem(
                      label: 'Wishlist',
                      value: 'View',
                      icon: Icons.favorite_border,
                      onTap: () => Get.toNamed(Routes.wishlist),
                    ),
                    _Divider(),
                    _StatItem(
                      label: 'Points',
                      value: '${user?.loyaltyPoints ?? 0}',
                      icon: Icons.stars_rounded,
                      onTap: () => Get.toNamed(Routes.loyalty),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            const ThemeModeSelector(),
            const SizedBox(height: 8),

            _MenuSection(
              title: 'Shopping',
              items: [
                _MenuItem(
                  icon: Icons.favorite_border,
                  label: 'Wishlist',
                  onTap: () => Get.toNamed(Routes.wishlist),
                ),
                _MenuItem(
                  icon: Icons.stars_rounded,
                  label: 'Loyalty Points',
                  onTap: () => Get.toNamed(Routes.loyalty),
                ),
                _MenuItem(
                  icon: Icons.local_offer_outlined,
                  label: 'Offers & Discounts',
                  onTap: () => Get.toNamed(Routes.customerOffers),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _MenuSection(
              title: 'Account',
              items: [
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: 'My Addresses',
                  onTap: () => Get.toNamed(Routes.addresses),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notification History',
                  onTap: () => Get.toNamed(Routes.notifications),
                ),
                _MenuItem(
                  icon: Icons.settings_suggest_outlined,
                  label: 'Notification Settings',
                  onTap: () => Get.toNamed(Routes.notificationSettings),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _MenuSection(
              title: 'Support',
              items: [
                _MenuItem(
                  icon: Icons.assignment_return_outlined,
                  label: 'Returns',
                  onTap: () => Get.toNamed(Routes.returns),
                ),
                _MenuItem(
                  icon: Icons.report_problem_outlined,
                  label: 'Disputes',
                  onTap: () => Get.toNamed(Routes.disputes),
                ),
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Help & FAQ',
                  onTap: () =>
                      GBSnack.plain('Help & FAQ', 'Help center coming soon'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Logout
            Container(
              color: AppColors.surface,
              child: ListTile(
                onTap: () => _confirmLogout(authCtrl),
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  'Logout',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(AuthController authCtrl) {
    Get.defaultDialog(
      title: 'Logout',
      middleText: 'Are you sure you want to logout?',
      textConfirm: 'Logout',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () {
        Get.back();
        authCtrl.logout();
      },
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  Color get color {
    switch (tier) {
      case 'silver':
        return AppColors.neutralGrey;
      case 'gold':
        return AppColors.amber;
      case 'platinum':
        return AppColors.chartPurple;
      default:
        return AppColors.chartBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            AppHelpers.getLoyaltyTierLabel(tier),
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(button: true, child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.titleMedium),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      )),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.map(
            (item) => Column(children: [item, const Divider(height: 1)]),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: AppTextStyles.titleMedium),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textHint,
      ),
    );
  }
}
