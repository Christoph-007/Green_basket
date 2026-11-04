import 'package:flutter/material.dart';
import '../../config/theme.dart';

class GBCard extends StatelessWidget {
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
    final radius = BorderRadius.circular(borderRadius ?? AppRadius.md);
    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: radius,
        border: border,
        boxShadow: shadow ??
            (elevation > 0
                ? [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: elevation * 4,
                      offset: Offset(0, elevation),
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
