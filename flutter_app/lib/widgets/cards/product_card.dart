import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../data/models/product_model.dart';
import '../common/gb_card.dart';
import '../common/gb_loader.dart';
import '../../../utils/responsive_helper.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final Function(String? preparationId)? onAddToCart;
  final bool isInWishlist;
  final VoidCallback? onWishlistToggle;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.isInWishlist = false,
    this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final imgHeight = constraints.maxWidth * 0.6; // Scale image with card width

        return GBCard(
          onTap: () => Get.toNamed(
            Routes.productDetail,
            arguments: {'productId': product.id},
          ),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Image section (dynamic height) ──────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.md)),
                    child: product.primaryImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.primaryImage.contains('cloudinary.com') 
                                ? product.primaryImage.replaceAll('/upload/', '/upload/w_400,c_fill,g_auto,f_auto,q_auto/') 
                                : product.primaryImage,
                            height: imgHeight,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            memCacheWidth: 400, // Limit memory usage
                            maxWidthDiskCache: 400, // Limit disk usage
                            placeholder: (_, __) => GBShimmerBox(
                              width: double.infinity,
                              height: imgHeight,
                              borderRadius: 0,
                            ),
                            errorWidget: (_, __, ___) =>
                                _PlaceholderImage(height: imgHeight),
                          )
                        : _PlaceholderImage(height: imgHeight),
                  ),

              // Organic badge
              if (product.isOrganic)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Text(
                      'Organic',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Discount badge
              if (product.hasDiscount)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${product.discountPercent}% OFF',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Wishlist button
              if (onWishlistToggle != null)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onWishlistToggle,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isInWishlist
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: isInWishlist
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

              // Closed badge
              if (!product.isStoreOpen)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.md)),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'STORE CLOSED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Info section (fills remaining space) ──────────────
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontSize: responsive.adaptiveFontSize(13),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.merchantName.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      product.merchantName + (product.merchantCity != null ? ', ${product.merchantCity}' : ''),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Nearby Info (Distance & ETA)
                  if (product.distanceLabel != null || product.etaMins != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (product.distanceLabel != null) ...[
                          const Icon(Icons.near_me_outlined, size: 12, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              product.distanceLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (product.distanceLabel != null && product.etaMins != null)
                          const SizedBox(width: 8),
                        if (product.etaMins != null) ...[
                          const Icon(Icons.delivery_dining_outlined, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${product.etaMins} mins',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  const Spacer(),

                  // Price row + add-to-cart button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.hasDiscount)
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  decoration:
                                      TextDecoration.lineThrough,
                                  color: AppColors.textHint,
                                  fontSize: 11,
                                ),
                              ),
                            Text(
                              '₹${product.effectivePrice.toStringAsFixed(0)}/${product.unit}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: responsive.adaptiveFontSize(12),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (onAddToCart != null)
                        GestureDetector(
                          key: Key('add_to_cart_${product.id}'),
                          onTap: !product.isStoreOpen ? null : () {
                            debugPrint('[ProductCard] Tap on Add button for ${product.name}');
                            debugPrint('[ProductCard] Prep Options Count: ${product.preparationOptions.length}');
                            
                            if (product.preparationOptions.isNotEmpty) {
                              _showPreparationPicker(context);
                            } else {
                              onAddToCart!(null);
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: !product.isStoreOpen 
                                  ? Colors.grey 
                                  : (product.preparationOptions.isNotEmpty ? AppColors.secondary : AppColors.primary),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                                product.preparationOptions.isNotEmpty 
                                    ? Icons.tune_rounded 
                                    : Icons.add,
                                color: Colors.white, 
                                size: 22),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  void _showPreparationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choosing Preparation', style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            Text(
              'How would you like your ${product.name}?',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ...product.preparationOptions.map((opt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                  title: Text(opt.name, style: AppTextStyles.titleMedium),
                  trailing: Text(
                    opt.additionalPrice > 0 ? '+₹${opt.additionalPrice.toInt()}' : 'Free',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onAddToCart!(opt.id);
                  },
                )),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final double height;
  const _PlaceholderImage({this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      child: Icon(
          Icons.eco_outlined, size: height * 0.4, color: AppColors.primary),
    );
  }
}
