import 'package:flutter/material.dart';
import 'package:greenbasket_app/config/theme.dart';

/// The rounded green header used at the top of the admin tab screens:
/// a menu button that opens the Scaffold drawer, a title, an optional badge
/// or custom widget on the right, and an optional subtitle underneath.
///
/// Defaults match the Orders, Users and Merchants headers. The Finance
/// header passes its own colours, spacing and trailing widget.
class GBGradientHeader extends StatelessWidget {
  final String title;
  final Widget? subtitle;

  /// Shown in a small round badge on the right (ignored if [trailing] is set).
  final IconData? trailingIcon;
  final Widget? trailing;

  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final double bottomPadding;
  final double? menuIconSize;
  final double subtitleGap;
  final TextStyle? titleStyle;

  const GBGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingIcon,
    this.trailing,
    this.colors = const [AppColors.brandForest, AppColors.brandMid],
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.bottomPadding = 28,
    this.menuIconSize,
    this.subtitleGap = 4,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final right = trailing ??
        (trailingIcon == null
            ? null
            : Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(trailingIcon, color: Colors.white, size: 20),
              ));

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: bottomPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: begin, end: end),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Open menu',
                      icon: Icon(Icons.menu,
                          color: Colors.white, size: menuIconSize),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: titleStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (right != null) right,
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: subtitleGap),
            subtitle!,
          ],
        ],
      ),
    );
  }
}
