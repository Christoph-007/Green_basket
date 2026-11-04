import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';

class GBAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? leading;

  /// Something under the title, usually a [TabBar]. When set, the thin
  /// divider line is not drawn.
  final PreferredSizeWidget? bottom;

  /// Draws a 1 px divider under the bar (when there is no [bottom]).
  final bool showDivider;

  /// Icon for the default back button.
  final IconData backIcon;

  const GBAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.leading,
    this.bottom,
    this.showDivider = true,
    this.backIcon = Icons.arrow_back_ios,
  });

  PreferredSizeWidget? get _bottom {
    if (bottom != null) return bottom;
    if (!showDivider) return null;
    return PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: AppColors.divider),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (_bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.surface,
      foregroundColor: foregroundColor ?? AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBack
          ? (leading ??
              IconButton(
                tooltip: 'Back',
                icon: Icon(backIcon, size: 20),
                onPressed: () => Get.back(),
              ))
          : leading,
      title: Text(title, style: AppTextStyles.titleLarge),
      actions: actions,
      bottom: _bottom,
    );
  }
}
