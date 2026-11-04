part of 'returns_admin_screen.dart';

extension _ReturnsAdminScreenStateSections2 on _ReturnsAdminScreenState {
  void _showReturnDetail(Map<String, dynamic> ret) {
    final status = (ret['status'] ?? 'requested').toString();
    final returnId = ret['returnId']?.toString() ?? '';
    final userName = (ret['user'] is Map) ? ret['user']['name']?.toString() ?? 'N/A' : 'N/A';
    final userEmail = (ret['user'] is Map) ? ret['user']['email']?.toString() ?? '' : '';
    final orderId = (ret['order'] is Map) ? ret['order']['orderId']?.toString() ?? '' : '';
    final orderAmount = (ret['order'] is Map) ? ret['order']['totalAmount'] : null;
    final refundAmount = (ret['refundAmount'] as num?)?.toDouble() ?? 0;
    final reason = ret['reason']?.toString() ?? '';
    final returnType = ret['type']?.toString() ?? 'return';
    final refundMethod = ret['refundMethod']?.toString() ?? 'wallet';
    final createdAt = _formatDate(ret['createdAt']?.toString());
    final processedAt = _formatDate(ret['processedAt']?.toString());
    final items = ret['items'] as List? ?? [];
    final rejectionReason = ret['rejectionReason']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              const SizedBox(height: AppSpacing.md),

              // Title
              Row(
                children: [
                  Icon(_statusIcon(status), size: 22, color: _statusColor(status)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Return #$returnId', style: AppTextStyles.headlineMedium)),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _statusLabel(status),
                  style: AppTextStyles.labelSmall.copyWith(color: _statusColor(status)),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Info rows
              _detailRow('Customer', userName),
              if (userEmail.isNotEmpty) _detailRow('Email', userEmail),
              _detailRow('Order', '#$orderId'),
              if (orderAmount != null) _detailRow('Order Total', AppHelpers.formatCurrencyFlexible(orderAmount)),
              _detailRow('Type', returnType.toUpperCase()),
              _detailRow('Refund Amount', '₹${refundAmount.toStringAsFixed(0)}'),
              _detailRow('Refund Method', refundMethod.replaceAll('_', ' ')),
              _detailRow('Requested', createdAt),
              if (processedAt.isNotEmpty) _detailRow('Processed', processedAt),

              const SizedBox(height: AppSpacing.md),
              Text('Reason', style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text(reason, style: AppTextStyles.bodyMedium),

              if (rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Rejection: $rejectionReason',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Items
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Items', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                ...items.map((item) {
                  final it = item as Map<String, dynamic>;
                  final productName = (it['product'] is Map) ? it['product']['name']?.toString() ?? 'Item' : 'Item';
                  final qty = it['quantity'] ?? 1;
                  final itemReason = it['reason']?.toString() ?? '';
                  final cond = (it['condition'] ?? '').toString().replaceAll('_', ' ');
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('$productName (x$qty)', style: AppTextStyles.labelLarge)),
                            if (cond.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(cond, style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
                              ),
                          ],
                        ),
                        if (itemReason.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(itemReason, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  );
                }),
              ],

              // Action button for pending
              if (status.toLowerCase() == 'requested') ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: GBButton(label: 'Process This Return', onPressed: () {
                      Navigator.pop(ctx);
                      _showProcessDialog(ret);
                    }),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
