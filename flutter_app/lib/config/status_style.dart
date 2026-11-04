import 'package:flutter/material.dart';
import 'package:greenbasket_app/config/theme.dart';

/// Foreground colour, background colour, icon and label for an order status.
class OrderStatusInfo {
  final Color fg;
  final Color bg;
  final IconData icon;
  final String label;

  const OrderStatusInfo({
    required this.fg,
    required this.bg,
    required this.icon,
    required this.label,
  });
}

/// One place that says how an order status looks. Every status carries an
/// icon and a label as well as a colour, so meaning never depends on colour
/// alone. Unknown statuses fall back to the "Pending" look.
class OrderStatusStyle {
  OrderStatusStyle._();

  static OrderStatusInfo of(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const OrderStatusInfo(
          fg: AppColors.brandForest,
          bg: AppColors.primaryContainer,
          icon: Icons.check_circle_outline,
          label: 'Delivered',
        );
      case 'completed':
        return const OrderStatusInfo(
          fg: AppColors.brandForest,
          bg: AppColors.primaryContainer,
          icon: Icons.task_alt,
          label: 'Completed',
        );
      case 'confirmed':
        return const OrderStatusInfo(
          fg: AppColors.info,
          bg: AppColors.statusConfirmed,
          icon: Icons.thumb_up_outlined,
          label: 'Confirmed',
        );
      case 'preparing':
        return const OrderStatusInfo(
          fg: AppColors.amberDark,
          bg: AppColors.statusPreparing,
          icon: Icons.soup_kitchen_outlined,
          label: 'Preparing',
        );
      case 'ready':
        return const OrderStatusInfo(
          fg: AppColors.purpleDeep,
          bg: AppColors.purpleContainer,
          icon: Icons.inventory_2_outlined,
          label: 'Ready',
        );
      case 'dispatched':
      case 'out-for-delivery':
      case 'out_for_delivery':
        return const OrderStatusInfo(
          fg: AppColors.secondaryDark,
          bg: AppColors.statusPreparing,
          icon: Icons.local_shipping_outlined,
          label: 'Out for Delivery',
        );
      case 'cancelled':
        return const OrderStatusInfo(
          fg: AppColors.errorStrong,
          bg: AppColors.statusCancelled,
          icon: Icons.cancel_outlined,
          label: 'Cancelled',
        );
      case 'refunded':
        return const OrderStatusInfo(
          fg: AppColors.errorStrong,
          bg: AppColors.statusCancelled,
          icon: Icons.replay,
          label: 'Refunded',
        );
      case 'payment_pending':
        return const OrderStatusInfo(
          fg: AppColors.textSecondary,
          bg: AppColors.neutralSoft,
          icon: Icons.hourglass_empty,
          label: 'Awaiting Payment',
        );
      case 'pending':
      default:
        return const OrderStatusInfo(
          fg: AppColors.warningDeep,
          bg: AppColors.statusPending,
          icon: Icons.schedule,
          label: 'Pending',
        );
    }
  }
}
