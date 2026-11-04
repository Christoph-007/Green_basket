import 'package:dio/dio.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/models/return_model.dart';
import 'package:greenbasket_app/data/repositories/return_repository.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:greenbasket_app/widgets/common/empty_state.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';

const List<String> _progressSteps = ['Requested', 'Approved', 'Refunded'];

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ReturnRepository();
  late final TabController _tabCtrl;

  List<ReturnModel> _returns = [];
  bool _loading = true;
  String? _error;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getMyReturns();
      if (!mounted) return;
      setState(() => _returns = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load your returns. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(ReturnModel item) async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('Cancel return request?'),
      content: Text('Return ${item.returnId} will be withdrawn.'),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Cancel request',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
    if (confirmed != true) return;

    setState(() => _cancellingId = item.id);
    try {
      await _repo.cancelReturn(item.id);
      GBSnack.plain('Request cancelled', 'Your return request was withdrawn.', position: SnackPosition.BOTTOM);
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = body is Map ? (body['error'] ?? body['message']) : null;
      GBSnack.plain('Could not cancel', message?.toString() ?? 'Please try again.', position: SnackPosition.BOTTOM);
    } catch (_) {
      GBSnack.plain('Could not cancel', 'Please try again.', position: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _returns.where((r) => !r.isCompleted).toList();
    final completed = _returns.where((r) => r.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text('Returns & Refunds', style: AppTextStyles.titleLarge),
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
      body: _buildBody(pending, completed),
    );
  }

  Widget _buildBody(List<ReturnModel> pending, List<ReturnModel> completed) {
    if (_loading && _returns.isEmpty) return const GBPageLoader();
    if (_error != null && _returns.isEmpty) {
      return ErrorState(message: _error, onRetry: _load);
    }
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _buildList(pending, 'No pending returns',
            'Return an item from a delivered order and it will show up here'),
        _buildList(completed, 'No completed returns',
            'Refunded and closed requests will appear here'),
      ],
    );
  }

  Widget _buildList(List<ReturnModel> returns, String title, String message) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: returns.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: EmptyState(
                    icon: Icons.assignment_return_outlined,
                    title: title,
                    message: message,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: returns.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _buildReturnCard(returns[i]),
            ),
    );
  }

  Color _statusColor(ReturnModel item) {
    if (item.isCancelledByCustomer) return AppColors.textSecondary;
    if (item.isRejected) return AppColors.error;
    switch (item.progressStep) {
      case 2:
        return AppColors.success;
      case 1:
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildReturnCard(ReturnModel item) {
    final statusColor = _statusColor(item);
    final currentStep = item.progressStep;
    final showReason = item.isRejected &&
        !item.isCancelledByCustomer &&
        (item.rejectionReason ?? '').isNotEmpty;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.orderNumber.isEmpty
                          ? item.returnId
                          : 'Order ${item.orderNumber}',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.primary),
                    ),
                    if (item.items.isNotEmpty)
                      Text(item.itemsSummary, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      item.statusLabel,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(AppHelpers.formatDate(item.createdAt),
                      style: AppTextStyles.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Reason
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
          if (showReason) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Rejected: ${item.rejectionReason}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.sm),

          // Refund amount
          if (!item.isRejected)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Refund: ${AppHelpers.formatCurrency(item.refundAmount)}'
                '${item.refundMethod == 'wallet' ? ' to wallet' : ''}',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary),
              ),
            ),

          // Progress stepper (not shown once a request was rejected or cancelled)
          if (!item.isRejected) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            const Text('Return Status', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 50,
              child: Row(
                children: List.generate(_progressSteps.length, (i) {
                  final stepDone = i <= currentStep;
                  final isCurrent = i == currentStep;
                  final isLast = i == _progressSteps.length - 1;
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
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
                                _progressSteps[i],
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 11,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: stepDone
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
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
                              color: i < currentStep
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

          // Withdraw a request that nobody has looked at yet
          if (item.canCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _cancellingId == item.id ? null : () => _cancel(item),
                child: _cancellingId == item.id
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cancel request',
                        style: TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
