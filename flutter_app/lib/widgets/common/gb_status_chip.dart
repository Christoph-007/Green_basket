import 'package:flutter/material.dart';
import 'package:greenbasket_app/config/status_style.dart';

/// A pill showing an order status with its icon and label, so meaning is
/// carried by more than colour. Looks come from [OrderStatusStyle].
class GBStatusChip extends StatelessWidget {
  final String status;
  final bool showIcon;

  const GBStatusChip({super.key, required this.status, this.showIcon = true});

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
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: style.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
