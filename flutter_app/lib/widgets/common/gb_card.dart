import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// The one card look used on every panel: surface fill, 16 px corners, a
/// hairline border and a soft shadow. Use [GBCard] for new cards and
/// [GBCard.decoration] when a Container needs the same look.
class GBCard extends StatelessWidget {
  static const double defaultRadius = AppRadius.lg;

  /// The standard card look as a decoration, for Containers that cannot be a [GBCard].
  static BoxDecoration decoration({Color? color, double? radius}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius ?? defaultRadius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFaint,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Color? color;
  final double elevation;
  final Border? border;

  /// Custom shadows. When null, a soft shadow is derived from [elevation].
  final List<BoxShadow>? shadow;
  final Gradient? gradient;

  const GBCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.color,
    this.elevation = 2,
    this.border,
    this.shadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? defaultRadius);
    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: radius,
        border: border ?? Border.all(color: AppColors.borderLight),
        boxShadow: shadow ??
            (elevation > 0
                ? [
                    BoxShadow(
                      color: AppColors.shadowFaint,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null),
      ),
      child: ClipRRect(
        borderRadius: radius,
        // Material + InkWell give a tap ripple and keyboard focus.
        child: onTap == null
            ? content
            : Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap, child: content),
              ),
      ),
    );
    return card;
  }
}
