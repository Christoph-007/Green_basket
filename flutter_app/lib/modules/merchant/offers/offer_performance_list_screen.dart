import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';
import 'offer_analytics_screen.dart';

class OfferPerformanceListScreen extends StatefulWidget {
  const OfferPerformanceListScreen({super.key});

  @override
  State<OfferPerformanceListScreen> createState() => _OfferPerformanceListScreenState();
}

class _OfferPerformanceListScreenState extends State<OfferPerformanceListScreen> {
  final _repo = MerchantRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _offers = [];

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await _repo.getOffers();
      setState(() {
        _offers = offers;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Offer Performance', backIcon: Icons.arrow_back_ios_new, showDivider: false),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.textHint),
                      const SizedBox(height: AppSpacing.md),
                      Text('No offers found', style: AppTextStyles.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _offers.length,
                  itemBuilder: (ctx, i) {
                    final offer = _offers[i];
                    final title = offer['title'] ?? offer['name'] ?? 'Offer';
                    final usedCount = offer['usedCount'] ?? 0;
                    final totalCap = offer['totalUsageLimit'] ?? 0;
                    final isActive = offer['status'] == 'active';

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: InkWell(
                        onTap: () => Get.to(() => const OfferAnalyticsScreen(), arguments: offer),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.show_chart, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: AppTextStyles.titleMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$usedCount${totalCap > 0 ? " / $totalCap" : ""} Redemptions',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.textHint.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: isActive ? AppColors.success : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
