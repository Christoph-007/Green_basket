import 'package:flutter/material.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/config/status_style.dart';

/// A pill showing an order status with its icon and label, so meaning is
/// carried by more than colour. Looks come from [OrderStatusStyle].
class GBStatusChip extends StatelessWidget {
  final String status;
  final bool showIcon;

  /// Shown instead of the standard label (for example "Ready for Pick up").
  final String? label;

  const GBStatusChip({super.key, required this.status, this.showIcon = true, this.label});

  @override
  Widget build(BuildContext context) {
    final style = OrderStatusStyle.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(style.icon, size: 14, color: style.fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label ?? style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: style.fg),
            ),
          ),
        ],
      ),
    );
  }
}
