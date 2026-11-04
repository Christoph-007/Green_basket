import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';

/// One way to show a picture from the network.
///
/// While it loads there is a soft shimmer, and if the address is empty or the
/// picture fails there is a tidy icon tile instead of a blank gap or a red
/// error box. Images are cached on disk by [CachedNetworkImage].
class GBNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData fallbackIcon;
  final double? fallbackIconSize;

  /// Decode at most this wide, to keep memory low for small thumbnails.
  final int? memCacheWidth;

  const GBNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.fallbackIcon = Icons.eco_outlined,
    this.fallbackIconSize,
    this.memCacheWidth,
  });

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primaryContainer,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: AppColors.primary, size: fallbackIconSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = url?.trim() ?? '';
    final Widget child = address.isEmpty
        ? _fallback()
        : CachedNetworkImage(
            imageUrl: address,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memCacheWidth,
            placeholder: (_, __) => GBShimmerBox(
              width: width ?? double.infinity,
              height: height ?? double.infinity,
              borderRadius: 0,
            ),
            errorWidget: (_, __, ___) => _fallback(),
          );
    if (borderRadius <= 0) return child;
    return ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: child);
  }
}
