import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Show the hamburger button that opens the screen's drawer (screens with no drawer pass false).
  final bool showMenu;

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
    this.showMenu = true,
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
              Expanded(
                child: Row(
                  children: [
                    if (showMenu)
                      Builder(
                        builder: (context) => IconButton(
                          tooltip: 'Open menu',
                          icon: Icon(Icons.menu,
                              color: Colors.white, size: menuIconSize),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    if (showMenu) const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle ??
                            AppTextStyles.displaySmall
                                .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
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

/// The same green header as [GBGradientHeader], but as a Scaffold `appBar`.
///
/// Used on the main tab screens that have a TabBar or action icons, so
/// every top-level screen in every panel wears the same header. Inner
/// (detail) screens keep the plain back-arrow app bar.
class GBBrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// A small line under the title, for example a count.
  final Widget? subtitle;
  final List<Widget>? actions;

  /// Usually a TabBar. Give it white label and indicator colours.
  final PreferredSizeWidget? bottom;

  /// Show the hamburger that opens the Scaffold drawer. Otherwise a Back
  /// button is shown when the screen can go back.
  final bool showMenu;

  /// Replaces the menu/back button (for example a Back that goes Home when
  /// there is nothing to go back to).
  final Widget? leading;

  const GBBrandAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.bottom,
    this.showMenu = false,
    this.leading,
  });

  double get _toolbarHeight => kToolbarHeight + (subtitle != null ? 18 : 0);

  @override
  Size get preferredSize =>
      Size.fromHeight(_toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _toolbarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      centerTitle: false,
      titleSpacing: (showMenu || canPop || leading != null) ? 0 : 20,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brandForest, AppColors.brandMid],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      leading: leading ??
          (showMenu
          ? Builder(
              builder: (context) => IconButton(
                tooltip: 'Open menu',
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : (canPop
              ? IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null)),
      title: subtitle == null
          ? Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
                ),
                DefaultTextStyle.merge(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                  child: subtitle!,
                ),
              ],
            ),
      actions: actions,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }
}
