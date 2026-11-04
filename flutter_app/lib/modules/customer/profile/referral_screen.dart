import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../data/repositories/referral_repository.dart';
import '../../../widgets/common/gb_app_bar.dart';
import '../../../widgets/common/gb_button.dart';
import '../../../widgets/common/gb_loader.dart';

class ReferralController extends GetxController {
  final _repo = ReferralRepository();
  final isLoading = true.obs;
  final error = ''.obs;
  final code = ''.obs;
  final shareText = ''.obs;
  final totalReferrals = 0.obs;
  final completedReferrals = 0.obs;
  final totalEarned = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      final codeData = await _repo.getOrCreateCode();
      code.value = (codeData['referralCode'] ?? '').toString();
      shareText.value =
          (codeData['shareText'] ??
                  'Join Green Basket with my referral code ${code.value}')
              .toString();
      final stats = await _repo.getStats();
      final s = Map<String, dynamic>.from(stats['stats'] ?? {});
      totalReferrals.value = (s['totalReferrals'] ?? 0) as int;
      completedReferrals.value = (s['completedReferrals'] ?? 0) as int;
      totalEarned.value = ((s['totalEarned'] ?? 0) as num).toDouble();
    } catch (_) {
      error.value = 'Could not load your referral code. Pull to retry.';
    }
    isLoading.value = false;
  }
}

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ReferralController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GBAppBar(title: 'Refer & Earn'),
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBLoader();
        if (ctrl.code.value.isEmpty) {
          return RefreshIndicator(
            onRefresh: ctrl.load,
            child: ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    ctrl.error.value.isNotEmpty
                        ? ctrl.error.value
                        : 'No referral code available',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }
        final code = ctrl.code.value;
        return RefreshIndicator(
          onRefresh: ctrl.load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: const Icon(
                        Icons.people_outline,
                        size: 52,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Invite Friends & Earn',
                      style: AppTextStyles.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your referral code and earn ₹100 wallet credit for each friend who makes their first order.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            code,
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Semantics(button: true, child: GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              GBSnack.plain('Copied', 'Referral code copied!', position: SnackPosition.BOTTOM);
                            },
                            child: const Icon(
                              Icons.copy_outlined,
                              color: AppColors.primary,
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    GBButton(
                      label: 'Copy Invite Message',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: ctrl.shareText.value),
                        );
                        GBSnack.plain('Copied', 'Invite message copied — paste it to share', position: SnackPosition.BOTTOM);
                      },
                      isFullWidth: true,
                      leadingIcon: Icons.share_outlined,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _StatTile(
                          label: 'Friends joined',
                          value: '${ctrl.totalReferrals.value}',
                        ),
                        const SizedBox(width: 12),
                        _StatTile(
                          label: 'Completed',
                          value: '${ctrl.completedReferrals.value}',
                        ),
                        const SizedBox(width: 12),
                        _StatTile(
                          label: 'Earned',
                          value:
                              '₹${ctrl.totalEarned.value.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
