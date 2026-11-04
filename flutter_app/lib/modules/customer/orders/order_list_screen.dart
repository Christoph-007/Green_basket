import '../nav_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/common/gb_loader.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../utils/responsive_helper.dart';

class OrderListController extends GetxController {
  final _repo = OrderRepository();
  final _reviewRepo = ReviewRepository();
  final activeOrders = <OrderModel>[].obs;
  final pastOrders = <OrderModel>[].obs;
  final isLoading = false.obs;
  // Track which orders have already been reviewed: orderId -> rating
  final reviewedOrders = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final all = await _repo.getOrders();
      activeOrders.value = all.where((o) => o.isActive).toList();
      pastOrders.value = all.where((o) => !o.isActive).toList();
      await _loadReviewedOrders();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
    isLoading.value = false;
  }

  Future<void> _loadReviewedOrders() async {
    try {
      final data = await _reviewRepo.getMyReviews();
      final reviews = data['reviews'] as List<dynamic>? ?? [];
      final Map<String, int> map = {};
      for (final r in reviews) {
        final order = r['order'];
        String? orderId;
        if (order is Map) {
          orderId = order['_id']?.toString();
        } else if (order is String) {
          orderId = order;
        }
        if (orderId != null) {
          map[orderId] = (r['rating'] as num?)?.toInt() ?? 0;
        }
      }
      reviewedOrders.value = map;
    } catch (_) {}
  }

  /// Returns null when the review was saved, otherwise the reason to show the user.
  Future<String?> submitReview({
    required String orderId,
    required String merchantId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _reviewRepo.addMerchantReview(
        merchantId: merchantId,
        orderId: orderId,
        rating: rating,
        comment: comment,
      );
      reviewedOrders[orderId] = rating;
      return null;
    } on DioException catch (e) {
      debugPrint('submitReview error: ${e.response?.data ?? e.message}');
      final body = e.response?.data;
      final reason = body is Map ? (body['error'] ?? body['message']) : null;
      return reason?.toString() ?? 'Could not reach the server. Please try again.';
    } catch (e) {
      debugPrint('submitReview error: $e');
      return 'Something went wrong. Please try again.';
    }
  }
}

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(OrderListController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(tooltip: 'Back', 
            icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.textPrimary),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Get.back();
              } else {
                Get.offAllNamed(Routes.customerHome);
              }
            },
          ),
          title: const Text('My Orders', style: AppTextStyles.titleLarge),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Past Orders'),
            ],
          ),
        ),
        body: Obx(() {
          if (ctrl.isLoading.value) return const GBListSkeleton(itemHeight: 130);
          return TabBarView(
            children: [
              _OrdersList(orders: ctrl.activeOrders, isActive: true),
              _OrdersList(orders: ctrl.pastOrders, isActive: false),
            ],
          );
        }),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderModel> orders;
  final bool isActive;
  const _OrdersList({required this.orders, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    if (orders.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
          child: EmptyState(
            icon: isActive ? Icons.local_shipping_outlined : Icons.receipt_long_outlined,
            title: isActive ? 'No active orders' : 'No past orders',
            message: isActive
                ? 'Your active orders will appear here'
                : 'Your order history will appear here',
            actionLabel: isActive ? 'Start Shopping' : null,
            onAction: isActive ? () => NavController.to.openCategories() : null,
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => Get.find<OrderListController>().fetchOrders(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: orders.length,
            itemBuilder: (context, i) => _OrderCard(order: orders[i]),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  void _showRatingSheet(BuildContext context) {
    final ctrl = Get.find<OrderListController>();
    int selectedRating = 0;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Rate your experience', style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text(
                  order.merchantName != null
                      ? 'How was your order from ${order.merchantName}?'
                      : 'How was this order?',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                // Star picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return Semantics(button: true, child: GestureDetector(
                      onTap: () => setState(() => selectedRating = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          selectedRating >= star
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 44,
                          color: selectedRating >= star
                              ? AppColors.secondary
                              : AppColors.border,
                        ),
                      ),
                    ));
                  }),
                ),
                const SizedBox(height: 20),
                // Comment field
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText:
                        'Share your experience (optional but appreciated)...',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    fillColor: AppColors.background,
                    filled: true,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: GBButton(
                    label: selectedRating == 0
                        ? 'Select a rating first'
                        : 'Submit Review',
                    isLoading: isSubmitting,
                    backgroundColor: selectedRating == 0
                        ? AppColors.border
                        : AppColors.primary,
                    foregroundColor: selectedRating == 0
                        ? AppColors.textSecondary
                        : Colors.white,
                    onPressed: selectedRating == 0
                        ? null
                        : () async {
                            setState(() => isSubmitting = true);
                            final comment = commentCtrl.text.trim();
                            final merchantId = order.merchantId ??
                                (order.items.isNotEmpty
                                    ? order.items.first.merchantId
                                    : '');
                            final error = await ctrl.submitReview(
                              orderId: order.id,
                              merchantId: merchantId,
                              rating: selectedRating,
                              comment: comment,
                            );
                            setState(() => isSubmitting = false);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (error == null) {
                              GBSnack.success(
                                'Review Submitted ⭐',
                                'Thank you for your feedback!',
                                duration: const Duration(seconds: 3),
                              );
                            } else {
                              GBSnack.error('Could Not Submit', error);
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OrderListController>();
    return Semantics(button: true, child: GestureDetector(
      onTap: () =>
          Get.toNamed(Routes.orderDetail, arguments: {'orderId': order.id}),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Order #${order.orderNumber}',
                      style: AppTextStyles.titleMedium,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.items.length} item${order.items.length == 1 ? '' : 's'} • ${AppHelpers.formatCurrency(order.total)}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              AppHelpers.formatDateTime(order.createdAt),
              style: AppTextStyles.bodySmall,
            ),
            // Active order tracking row
            if (order.isActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(order.deliveryType == 'pickup' ? Icons.store_outlined : Icons.local_shipping_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      order.deliveryType == 'pickup' && order.status == 'ready' ? 'Ready for Pickup' : AppHelpers.getOrderStatusLabel(order.status),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.primary),
                    ),
                    const Spacer(),
                    const Text('Track',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppColors.primary),
                  ],
                ),
              ),
            ],
            // ── Rate Merchant button: only on delivered past orders ──
            if (order.status == 'delivered' || order.status == 'completed') ...[
              const SizedBox(height: 12),
              Obx(() {
                final existingRating = ctrl.reviewedOrders[order.id];
                if (existingRating != null) {
                  // Already reviewed – show stars
                  return Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < existingRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'You reviewed this',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.success),
                      ),
                    ],
                  );
                }
                // Not reviewed yet
                return GestureDetector(
                  onTap: () => _showRatingSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warningAmber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: AppColors.warningAmber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_outline_rounded,
                            color: AppColors.warningAmber, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Rate this order',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.warningAmber),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    ));
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get color {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'preparing':
        return AppColors.secondary;
      case 'dispatched':
        return AppColors.primary;
      case 'delivered':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        AppHelpers.getOrderStatusLabel(status),
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
