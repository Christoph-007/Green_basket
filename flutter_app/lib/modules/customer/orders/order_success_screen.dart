import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/config/routes.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  String get _orderId => Get.arguments?['orderId'] ?? '#GB-PENDING';
  String get _estimatedDelivery => Get.arguments?['deliveryTime'] ?? 'Within 2 hours';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120, height: 120,
                  decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 72),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text('Order Placed\nSuccessfully!', textAlign: TextAlign.center, style: AppTextStyles.displayMedium),
                    const SizedBox(height: AppSpacing.md),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.full)),
                      child: Text('Order ID: $_orderId', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.sm)),
                            child: const Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Estimated Delivery', style: AppTextStyles.bodySmall),
                                const SizedBox(height: 2),
                                Text(_estimatedDelivery, style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Text(
                      "You'll receive a confirmation on your registered email",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.offAllNamed(Routes.orderList),
                        icon: const Icon(Icons.my_location_rounded, size: 18),
                        label: const Text('Track Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Get.offAllNamed(Routes.customerHome),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('Continue Shopping'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
