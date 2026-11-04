import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'merchant_analytics_controller.dart';

class MerchantReviewsScreen extends StatelessWidget {
  const MerchantReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Re-use the same controller since it already fetches reviews
    final controller = Get.find<MerchantAnalyticsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Customer Reviews', backgroundColor: Colors.white),
      body: Obx(() {
        final reviews = controller.recentReviews;
        
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No reviews yet', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchAnalytics(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _ReviewCard(review: review, controller: controller);
            },
          ),
        );
      }),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final MerchantAnalyticsController controller;

  const _ReviewCard({required this.review, required this.controller});

  @override
  Widget build(BuildContext context) {
    final customer = review['customer'] as Map? ?? {};
    final name = customer['name'] ?? 'Customer';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] ?? '';
    final date = DateTime.tryParse(review['createdAt'] ?? '') ?? DateTime.now();
    final reply = review['merchantReply'] as Map?;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryContainer,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.titleMedium),
                    Text(AppHelpers.formatDateTime(date), style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (star) => Icon(
                  star < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16,
                  color: Colors.amber,
                )),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(comment, style: AppTextStyles.bodyMedium),
          
          if (reply != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_all_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Your Reply', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(reply['comment'] ?? '', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            GBButton(label: 'Reply to Review', onPressed: () => _showReplyDialog(context), leadingIcon: Icons.reply_rounded, variant: GBButtonVariant.outline, foregroundColor: AppColors.primary),
          ],
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context) {
    final replyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Responding as your store', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: replyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your reply here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          GBButton(label: 'Post Reply', onPressed: () async {
              if (replyController.text.trim().isEmpty) return;
              Get.back();
              await controller.replyToCustomerReview(review['_id'], replyController.text.trim());
            }, backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ],
      ),
    );
  }
}
