import '../nav_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/common/gb_button.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/gb_loader.dart';
import 'cart_controller.dart';
import '../../../utils/responsive_helper.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CartController>();
    final couponCtrl = TextEditingController();
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('My Cart', style: AppTextStyles.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
        actions: [
          Obx(
            () => ctrl.items.isNotEmpty
                ? TextButton(
                    onPressed: () => _confirmClear(ctrl),
                    child: Text(
                      'Clear',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBLoader();
        if (ctrl.items.isEmpty) {
          return EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Your cart is empty',
            message: 'Add items to start shopping',
            actionLabel: 'Browse Products',
            onAction: () => NavController.to.openCategories(),
          );
        }
        if (responsive.isTablet) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Items
              Expanded(
                flex: 3,
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemCount: ctrl.items.length,
                  itemBuilder: (context, i) {
                    final item = ctrl.items[i];
                    return _CartItemTile(item: item, cartCtrl: ctrl);
                  },
                ),
              ),
              // Right side: Summary
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: _buildSummary(context, ctrl, couponCtrl),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: ctrl.items.length,
                itemBuilder: (context, i) {
                  final item = ctrl.items[i];
                  return _CartItemTile(item: item, cartCtrl: ctrl);
                },
              ),
            ),

            // Coupon + summary
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: _buildSummary(context, ctrl, couponCtrl),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSummary(BuildContext context, CartController ctrl, TextEditingController couponCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loyalty redemption
        Obx(() {
          if (ctrl.appliedCoupon.value.isNotEmpty) {
            return const SizedBox.shrink();
          }

          final hasEnoughPoints = ctrl.loyaltyPoints.value >= 50;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You have ${ctrl.loyaltyPoints.value} points',
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        hasEnoughPoints
                            ? 'Redeem for ₹${ctrl.loyaltyPoints.value} discount'
                            : 'Minimum 50 points required to redeem',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: hasEnoughPoints
                              ? AppColors.textPrimary
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: hasEnoughPoints
                      ? () => ctrl.redeemLoyaltyPoints(
                            ctrl.loyaltyPoints.value,
                          )
                      : null,
                  child: const Text('Redeem'),
                ),
              ],
            ),
          );
        }),

        // Coupon input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: couponCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GBButton(
              label: 'Apply',
              onPressed: () => ctrl.applyCoupon(couponCtrl.text.trim()),
              height: 44,
            ),
          ],
        ),

        Obx(() {
          if (ctrl.appliedCoupon.value.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Coupon "${ctrl.appliedCoupon.value}" applied',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: ctrl.clearCoupon,
                  child: Text(
                    'Remove',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 24),

        // Price breakdown
        Obx(() {
          final subtotal = ctrl.subtotal;
          final delivery = ctrl.deliveryFee;
          final discount = ctrl.discount.value;
          final total = ctrl.total;
          final hasDiscount = discount > 0;

          return Column(
            children: [
              _PriceLine(
                'Subtotal',
                AppHelpers.formatCurrency(subtotal),
              ),
              const SizedBox(height: 8),
              // Depends on pickup vs delivery, the address and the store's
              // delivery zones: the exact amount is quoted at checkout
              _PriceLine(
                'Delivery',
                'Calculated at checkout',
                valueColor: AppColors.textSecondary,
              ),
              if (hasDiscount) ...[
                const SizedBox(height: 8),
                _PriceLine(
                  'Coupon Discount',
                  '-${AppHelpers.formatCurrency(discount)}',
                  valueColor: AppColors.success,
                ),
                const SizedBox(height: 8),
                _PriceLine(
                  'Original Total',
                  AppHelpers.formatCurrency(subtotal + delivery),
                  isStrikethrough: true,
                  valueColor: AppColors.textSecondary,
                ),
              ],
              const Divider(height: 24),
              _PriceLine(
                delivery == 0 ? 'Items Total' : 'Total Amount',
                AppHelpers.formatCurrency(total),
                isBold: true,
              ),
              if (hasDiscount) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You saved ${AppHelpers.formatCurrency(discount)} on this order!',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }),

        const SizedBox(height: 16),
        GBButton(
          label: 'Proceed to Checkout',
          onPressed: () => Get.toNamed(Routes.checkout),
          isFullWidth: true,
          leadingIcon: Icons.shopping_bag_outlined,
        ),
      ],
    );
  }

  void _confirmClear(CartController ctrl) {
    Get.defaultDialog(
      title: 'Clear Cart',
      middleText: 'Are you sure you want to remove all items?',
      textConfirm: 'Clear',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () {
        ctrl.clearCart();
        Get.back();
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final dynamic item;
  final CartController cartCtrl;
  const _CartItemTile({required this.item, required this.cartCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: item.productImage != null
                ? CachedNetworkImage(
                    imageUrl: item.productImage!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: AppColors.primaryContainer,
                    child: const Icon(
                      Icons.eco_outlined,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(item.merchantName, style: AppTextStyles.bodySmall),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.unit.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.preparationOption != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Prep: ${item.preparationOption!}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      AppHelpers.formatCurrency(item.itemTotal),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    // Quantity controls
                    _QtyControl(
                      quantity: item.quantity,
                      onDecrement: () => cartCtrl.updateQuantity(
                        item.productId,
                        item.quantity - 1,
                        preparation: item.preparationOption,
                      ),
                      onIncrement: () => cartCtrl.updateQuantity(
                        item.productId,
                        item.quantity + 1,
                        preparation: item.preparationOption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _QtyControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: Icon(
                quantity <= 1 ? Icons.delete_outline : Icons.remove,
                size: 16,
                color: quantity <= 1 ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$quantity', style: AppTextStyles.titleMedium),
          ),
          InkWell(
            onTap: onIncrement,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: const Icon(Icons.add, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  final bool isStrikethrough;

  const _PriceLine(
    this.label,
    this.value, {
    this.isBold = false,
    this.valueColor,
    this.isStrikethrough = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold ? AppTextStyles.titleLarge : AppTextStyles.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: style.copyWith(
            color: valueColor ?? (isBold ? AppColors.primary : null),
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}
