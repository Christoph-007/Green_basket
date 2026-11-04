import 'package:flutter/material.dart';
import '../../config/theme.dart';

enum GBButtonVariant { primary, secondary, ghost, outline, danger }

class GBButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final GBButtonVariant variant;
  final IconData? leadingIcon;
  final double? height;

  /// Override the fill colour (filled variants only).
  final Color? backgroundColor;

  /// Override the text and icon colour (and the outline colour for the outline variant).
  final Color? foregroundColor;

  /// Override the inner padding. Null keeps the theme padding.
  final EdgeInsetsGeometry? padding;

  const GBButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.variant = GBButtonVariant.primary,
    this.leadingIcon,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                (variant == GBButtonVariant.primary ||
                        variant == GBButtonVariant.danger)
                    ? Colors.white
                    : AppColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    final button = switch (variant) {
      GBButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: foregroundColor ?? Colors.white,
            padding: padding,
            minimumSize: Size(0, height ?? 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
          child: child,
        ),
      GBButtonVariant.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.secondary,
            // Dark text on orange: white on #FFA726 fails contrast.
            foregroundColor: foregroundColor ?? AppColors.textPrimary,
            padding: padding,
            minimumSize: Size(0, height ?? 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: child,
        ),
      GBButtonVariant.danger => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.error,
            foregroundColor: foregroundColor ?? Colors.white,
            padding: padding,
            minimumSize: Size(0, height ?? 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
          child: child,
        ),
      GBButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            side: BorderSide(color: foregroundColor ?? AppColors.primary),
            minimumSize: Size(0, height ?? 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
          child: child,
        ),
      GBButtonVariant.ghost => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(0, height ?? 52),
          ),
          child: child,
        ),
    };

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
