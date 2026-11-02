import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';

class _ReturnItem {
  final String id;
  final String orderId;
  final String itemName;
  final String reason;
  final String status;
  final double refundAmount;
  final String requestedDate;
  final String statusStep;
  final bool isCompleted;

  const _ReturnItem({
    required this.id,
    required this.orderId,
    required this.itemName,
    required this.reason,
    required this.status,
    required this.refundAmount,
    required this.requestedDate,
    required this.statusStep,
    required this.isCompleted,
  });
}

const List<_ReturnItem> _mockReturns = [
  _ReturnItem(
    id: 'r1',
    orderId: '#GB2024005',
    itemName: 'Organic Bananas × 6',
    reason: 'Item was damaged during delivery',
    status: 'Pickup Scheduled',
    refundAmount: 89.00,
    requestedDate: '18 Mar 2026',
    statusStep: 'pickup_scheduled',
    isCompleted: false,
  ),
  _ReturnItem(
    id: 'r2',
    orderId: '#GB2024003',
    itemName: 'Fresh Orange Juice 1L',
    reason: 'Wrong product delivered',
    status: 'Refunded',
    refundAmount: 145.00,
    requestedDate: '05 Mar 2026',
    statusStep: 'refunded',
    isCompleted: true,
  ),
];

const List<String> _statusSteps = [
  'requested',
  'pickup_scheduled',
  'picked_up',
  'refunded',
];

const Map<String, String> _statusLabels = {
  'requested': 'Requested',
  'pickup_scheduled': 'Pickup Scheduled',
  'picked_up': 'Picked Up',
  'refunded': 'Refunded',
};

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        _mockReturns.where((r) => !r.isCompleted).toList();
    final completed =
        _mockReturns.where((r) => r.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text('Returns & Refunds',
            style: AppTextStyles.titleLarge),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.labelLarge,
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Completed (${completed.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildList(pending),
          _buildList(completed),
        ],
      ),
    );
  }

  Widget _buildList(List<_ReturnItem> returns) {
    if (returns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_return_outlined,
                color: AppColors.textHint, size: 64),
            const SizedBox(height: AppSpacing.md),
            const Text('No returns here',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Completed returns will appear here',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: returns.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _buildReturnCard(returns[i]),
    );
  }

  Widget _buildReturnCard(_ReturnItem item) {
    Color statusColor;
    switch (item.statusStep) {
      case 'refunded':
        statusColor = AppColors.success;
        break;
      case 'picked_up':
        statusColor = AppColors.primary;
        break;
      case 'pickup_scheduled':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    final currentStepIndex = _statusSteps.indexOf(item.statusStep);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.orderId,
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.primary)),
                    Text(item.itemName,
                        style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(item.requestedDate,
                      style: AppTextStyles.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Reason
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(item.reason,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Refund amount
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.currency_rupee_rounded,
                    size: 14, color: AppColors.primary),
                Text(
                  'Refund: ₹${item.refundAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress stepper
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          const Text('Return Status',
              style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 50,
            child: Row(
              children: List.generate(_statusSteps.length, (i) {
                final stepDone = i <= currentStepIndex;
                final isCurrent = i == currentStepIndex;
                final isLast = i == _statusSteps.length - 1;
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              width: isCurrent ? 24 : 18,
                              height: isCurrent ? 24 : 18,
                              decoration: BoxDecoration(
                                color: stepDone
                                    ? AppColors.primary
                                    : AppColors.border,
                                shape: BoxShape.circle,
                              ),
                              child: stepDone
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 12)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _statusLabels[_statusSteps[i]] ?? '',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 9,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: stepDone
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 20),
                            color: i < currentStepIndex
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
