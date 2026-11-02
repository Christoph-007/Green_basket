import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../widgets/common/gb_loader.dart';
import '../../../widgets/common/empty_state.dart';
import '../home/home_controller.dart';

class CustomerOffersScreen extends StatelessWidget {
  const CustomerOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We can reuse HomeController since it already fetches available offers
    final homeCtrl = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Offers & Coupons', style: AppTextStyles.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Obx(() {
        if (homeCtrl.isLoading.value) return const GBLoader();

        final offers = homeCtrl.availableOffers;
        if (offers.isEmpty) {
          return EmptyState(
            icon: Icons.local_offer_outlined,
            title: 'No offers available',
            message: 'Check back later for exciting discounts and deals!',
            actionLabel: 'Go Shopping',
            onAction: () => Get.back(),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _OfferTile(offer: offers[index]);
          },
        );
      }),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final Map<String, dynamic> offer;
  const _OfferTile({required this.offer});

  @override
  Widget build(BuildContext context) {
    final type = offer['type'] ?? '';
    final code = offer['couponCode'] ?? '';
    final title = offer['title'] ?? (type == 'percentage' 
        ? '${offer['discountPercentage']}% OFF' 
        : type == 'flat' 
            ? 'Flat ₹${offer['discountAmount']} OFF'
            : 'Special Offer');
    
    final subtitle = offer['description'] ?? 'Limited time deal for you';
    final minOrder = offer['minOrderValue'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.05), AppColors.primary.withOpacity(0.1)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_offer, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (code.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.primary.withOpacity(0.05),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        Get.snackbar(
                          'Code Copied!',
                          'Coupon code "$code" copied to clipboard',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (minOrder > 0)
                    Text('Min. Order: ₹$minOrder', style: AppTextStyles.labelSmall),
                  if (offer['endDate'] != null)
                    Text(
                      'Expires: ${DateTime.tryParse(offer['endDate'].toString())?.toLocal().toString().split(' ')[0] ?? 'Soon'}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
