import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../widgets/common/gb_app_bar.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/gb_loader.dart';
import 'notification_controller.dart';
import '../../../data/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(NotificationController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(
        title: 'Notifications',
        actions: [
          Obx(() => ctrl.notifications.isNotEmpty
              ? TextButton(
                  onPressed: () => ctrl.markAllAsRead(),
                  child: const Text('Mark All as Read',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                )
              : const SizedBox()),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBLoader();

        if (ctrl.notifications.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none_outlined,
            title: 'No notifications',
            message: 'You\'re all caught up!',
          );
        }

        return RefreshIndicator(
          onRefresh: ctrl.fetchNotifications,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: ctrl.notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final n = ctrl.notifications[index];
              return _NotificationTile(notification: n, ctrl: ctrl);
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationController ctrl;

  const _NotificationTile({required this.notification, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        if (!notification.isRead) {
          ctrl.markAsRead(notification.id);
        }
      },
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surfaceVariant : AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getIcon(notification.type),
          color: notification.isRead ? AppColors.textHint : AppColors.primary,
        ),
      ),
      title: Text(
        notification.title,
        style: AppTextStyles.titleMedium.copyWith(
          color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
          fontSize: 14,
          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, h:mm a').format(notification.createdAt),
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      isThreeLine: true,
      tileColor: notification.isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.02),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order_placed':
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'order_delivered':
        return Icons.check_circle_outline;
      case 'flash_sale':
        return Icons.flash_on_outlined;
      case 'offer_available':
        return Icons.local_offer_outlined;
      case 'payment_success':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }
}
