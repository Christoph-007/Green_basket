import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'offers_controller.dart';
import 'package:greenbasket_app/modules/merchant/widgets/merchant_bottom_nav.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OffersController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(OffersController());
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDelete(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Delete Offer', style: AppTextStyles.titleLarge),
        content: Text('Delete "$title"? This action cannot be undone.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          GBButton(label: 'Delete', onPressed: () {
              Navigator.pop(ctx);
              controller.deleteOffer(id);
            }, backgroundColor: AppColors.error),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const MerchantBottomNav(highlight: false),
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Offers & Discounts', bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTextStyles.labelLarge,
          unselectedLabelStyle: AppTextStyles.labelLarge,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Scheduled'),
            Tab(text: 'Expired'),
          ],
        ), leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        )),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return TabBarView(
          controller: _tabController,
          children: [
            _buildOfferList(controller.activeOffers, canToggle: true),
            _buildOfferList(controller.scheduledOffers, canToggle: false),
            _buildOfferList(controller.expiredOffers,
                canToggle: false, isExpired: true),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/merchant/offers/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Offer', style: AppTextStyles.labelLarge),
      ),
    );
  }

  Widget _buildOfferList(
    RxList<Map<String, dynamic>> offers, {
    bool canToggle = true,
    bool isExpired = false,
  }) {
    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(
              isExpired ? 'No expired offers' : 'No offers yet',
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isExpired
                  ? 'Your expired offers will appear here'
                  : 'Create your first offer to attract customers',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: offers.length,
      itemBuilder: (ctx, i) => _buildOfferCard(
        offers[i],
        canToggle: canToggle,
        isExpired: isExpired,
      ),
    );
  }

  Widget _buildOfferCard(
    Map<String, dynamic> offer, {
    bool canToggle = true,
    bool isExpired = false,
  }) {
    final id = offer['_id'] ?? offer['id'] ?? '';
    final title = offer['title'] ?? offer['name'] ?? 'Untitled Offer';
    final type = offer['type'] ?? offer['discountType'] ?? 'percentage';
    
    num discountVal = 0;
    String discountDisplay = '';
    
    if (type == 'percentage') {
      discountVal = offer['discountPercentage'] ?? offer['discount'] ?? offer['discountValue'] ?? 0;
      discountDisplay = '${discountVal.toInt()}%';
    } else if (type == 'flat' || type == 'Fixed') {
      discountVal = offer['discountAmount'] ?? offer['discount'] ?? offer['discountValue'] ?? 0;
      discountDisplay = '₹${discountVal.toInt()}';
    } else if (type == 'bogo') {
      discountDisplay = 'BOGO';
    } else if (type == 'free_delivery') {
      discountDisplay = 'FREE';
    }

    final validFromRaw = offer['startDate'] ?? offer['validFrom'] ?? '';
    final validToRaw = offer['endDate'] ?? offer['validTo'] ?? '';
    
    String validFrom = '';
    String validTo = '';
    
    if (validFromRaw.isNotEmpty) {
      final date = DateTime.tryParse(validFromRaw);
      if (date != null) validFrom = '${date.day}/${date.month}/${date.year}';
    }
    if (validToRaw.isNotEmpty) {
      final date = DateTime.tryParse(validToRaw);
      if (date != null) validTo = '${date.day}/${date.month}/${date.year}';
    }

    final usedCount = offer['usedCount'] ?? offer['used'] ?? 0;
    final limit = offer['totalUsageLimit'] ?? offer['limit'] ?? offer['usageLimit'] ?? 0;
    final isActive = offer['status'] == 'active' || offer['active'] == true;
    final double usageRatio =
        limit > 0 ? (usedCount as num) / (limit as num) : 0.0;

    Color typeColor;
    IconData typeIcon;
    switch (type.toLowerCase()) {
      case 'flash':
      case 'flash_sale':
        typeColor = AppColors.error;
        typeIcon = Icons.flash_on;
        break;
      case 'flat':
      case 'fixed':
        typeColor = AppColors.secondary;
        typeIcon = Icons.monetization_on_outlined;
        break;
      case 'bogo':
        typeColor = Colors.orange;
        typeIcon = Icons.redeem_outlined;
        break;
      case 'free_delivery':
        typeColor = Colors.blue;
        typeIcon = Icons.local_shipping_outlined;
        break;
      default:
        typeColor = AppColors.primary;
        typeIcon = Icons.percent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isExpired ? AppColors.border : typeColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.titleMedium),
                          if (offer['description'] != null)
                            Text(offer['description'], 
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        discountDisplay,
                        style: AppTextStyles.titleMedium
                            .copyWith(color: typeColor),
                      ),
                    ),
                  ],
                ),
                if (offer['couponCode'] != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      'Code: ${offer['couponCode']}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
                if (validFrom.isNotEmpty || validTo.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$validFrom – $validTo',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
                if (limit > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage: $usedCount / $limit',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: usageRatio.toDouble(),
                          backgroundColor: AppColors.border,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(typeColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              children: [
                if (!isExpired)
                  IconButton(
                    onPressed: () => Get.toNamed('/merchant/offers/edit',
                        arguments: offer),
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.textSecondary, size: 20),
                    tooltip: 'Edit',
                  ),
                IconButton(
                  onPressed: () => Get.toNamed('/merchant/offers/analytics',
                      arguments: offer),
                  icon: const Icon(Icons.bar_chart_outlined,
                      color: AppColors.primary, size: 20),
                  tooltip: 'Analytics',
                ),
                IconButton(
                  onPressed: () => _confirmDelete(id, title),
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  tooltip: 'Delete',
                ),
                const Spacer(),
                if (canToggle)
                  Row(
                    children: [
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isActive
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Switch(
                        value: isActive,
                        onChanged: (v) =>
                            controller.toggleOffer(id, v),
                        activeColor: AppColors.primary,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
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
