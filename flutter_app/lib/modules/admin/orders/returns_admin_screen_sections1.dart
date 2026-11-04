part of 'returns_admin_screen.dart';

extension _ReturnsAdminScreenStateSections1 on _ReturnsAdminScreenState {
  // ── Map backend status to tab index ──────────────────────────────
  // Pending:    requested
  // Processing: approved, pickup_scheduled, picked_up, processed
  // Completed:  refunded, rejected
  int _statusTab(Map<String, dynamic> r) {
    final s = (r['status'] ?? '').toString().toLowerCase();
    if (s == 'refunded' || s == 'rejected') return 2;
    if (s == 'approved' || s == 'pickup_scheduled' || s == 'picked_up' || s == 'processed') return 1;
    return 0; // requested
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'refunded':
        return AppColors.success;
      case 'approved':
      case 'pickup_scheduled':
      case 'picked_up':
      case 'processed':
        return AppColors.info;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning; // requested
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'refunded':
        return Icons.check_circle_outline;
      case 'approved':
        return Icons.thumb_up_outlined;
      case 'pickup_scheduled':
        return Icons.local_shipping_outlined;
      case 'picked_up':
        return Icons.inventory_2_outlined;
      case 'processed':
        return Icons.settings_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.pending_outlined; // requested
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 'Pending';
      case 'pickup_scheduled':
        return 'Pickup Scheduled';
      case 'picked_up':
        return 'Picked Up';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }

  // ── Extract displayable info from return item ─────────────────────
  String _itemSummary(Map<String, dynamic> ret) {
    final items = ret['items'] as List?;
    if (items == null || items.isEmpty) return 'Unknown item';
    if (items.length == 1) {
      final it = items[0] as Map<String, dynamic>;
      final name = it['product'] is Map ? (it['product']['name'] ?? 'Item') : 'Item';
      final qty = it['quantity'] ?? 1;
      return qty > 1 ? '$name (x$qty)' : name.toString();
    }
    return '${items.length} items';
  }

  String _itemCondition(Map<String, dynamic> ret) {
    final items = ret['items'] as List?;
    if (items == null || items.isEmpty) return '';
    final cond = (items[0] as Map<String, dynamic>)['condition']?.toString() ?? '';
    return cond.replaceAll('_', ' ');
  }

  void _showProcessDialog(Map<String, dynamic> ret) {
    _refundController.text = (ret['refundAmount'] ?? 0).toString();
    _approving = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          title: Text('Process Return #${ret['returnId'] ?? ''}', style: AppTextStyles.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      (ret['user'] is Map ? ret['user']['name'] : null)?.toString() ?? 'Customer',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Item: ${_itemSummary(ret)}', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 4),
              Text('Type: ${(ret['type'] ?? 'return').toString().toUpperCase()}', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Text('Reason: ${ret['reason'] ?? ''}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Approve'),
                      selected: _approving,
                      onSelected: (_) => setDialogState(() => _approving = true),
                      selectedColor: AppColors.success,
                      labelStyle: AppTextStyles.labelSmall.copyWith(
                        color: _approving ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Reject'),
                      selected: !_approving,
                      onSelected: (_) => setDialogState(() => _approving = false),
                      selectedColor: AppColors.error,
                      labelStyle: AppTextStyles.labelSmall.copyWith(
                        color: !_approving ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_approving) ...[
                const SizedBox(height: AppSpacing.md),
                GBTextField(label: 'Refund Amount', controller: _refundController, keyboardType: TextInputType.number, prefixText: '₹'),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            GBButton(label: _approving ? 'Approve & Refund' : 'Reject', onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final retId = (ret['_id'] ?? ret['id'] ?? '').toString();
                  await _repo.processReturn(retId, {
                    'action': _approving ? 'approve' : 'reject',
                    'refundAmount': double.tryParse(_refundController.text) ?? 0,
                  });
                  _fetchReturns();
                  if (_approving) {
                    GBSnack.success('Return Approved',
                        'Refund of ₹${_refundController.text} will be processed.');
                  } else {
                    GBSnack.error('Return Rejected', 'Return has been rejected.');
                  }
                } catch (e) {
                  GBSnack.error('Error', 'Failed to process return');
                }
              }, backgroundColor: _approving ? AppColors.success : AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final pending = _returns.where((r) => _statusTab(r) == 0).length;
    final totalRefunded = _returns
        .where((r) => r['status']?.toString().toLowerCase() == 'refunded')
        .fold<double>(0, (sum, r) => sum + ((r['refundAmount'] as num?)?.toDouble() ?? 0));
    final processing = _returns.where((r) => _statusTab(r) == 1).length;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _statItem('Pending', '$pending', Icons.pending_outlined, AppColors.warning),
          Container(width: 1, height: 48, color: AppColors.border),
          _statItem('Total Refunded', '₹${totalRefunded.toStringAsFixed(0)}', Icons.currency_rupee, AppColors.success),
          Container(width: 1, height: 48, color: AppColors.border),
          _statItem('Processing', '$processing', Icons.sync_outlined, AppColors.info),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.titleMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildReturnCard(Map<String, dynamic> ret) {
    final status = (ret['status'] ?? 'requested').toString();
    final returnId = ret['returnId']?.toString() ?? ret['_id']?.toString() ?? '';
    final userName = (ret['user'] is Map) ? ret['user']['name']?.toString() : null;
    final userEmail = (ret['user'] is Map) ? ret['user']['email']?.toString() : null;
    final orderId = (ret['order'] is Map) ? ret['order']['orderId']?.toString() : null;
    final refundAmount = (ret['refundAmount'] as num?)?.toDouble() ?? 0;
    final reason = ret['reason']?.toString() ?? '';
    final returnType = ret['type']?.toString() ?? 'return';
    final createdAt = _formatDate(ret['createdAt']?.toString());
    final condition = _itemCondition(ret);
    final isPending = status.toLowerCase() == 'requested';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _showReturnDetail(ret),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Return ID + Status + Type
              Row(
                children: [
                  Icon(_statusIcon(status), size: 18, color: _statusColor(status)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('#$returnId', style: AppTextStyles.titleMedium),
                  ),
                  if (returnType == 'exchange')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text('Exchange', style: AppTextStyles.labelSmall.copyWith(color: AppColors.secondary)),
                    ),
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
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Item summary
              Text(_itemSummary(ret), style: AppTextStyles.bodyMedium),
              const SizedBox(height: 4),

              // Order + date + customer
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (orderId != null)
                    Text('Order #$orderId', style: AppTextStyles.bodySmall),
                  if (createdAt.isNotEmpty)
                    Text('• $createdAt', style: AppTextStyles.bodySmall),
                ],
              ),
              if (userName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(userName, style: AppTextStyles.bodySmall),
                    if (userEmail != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('($userEmail)', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 4),

              // Reason
              Text(
                reason,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Condition tag
              if (condition.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'Condition: $condition',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),

              // Amount + action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: 'Refund: ', style: AppTextStyles.bodySmall),
                        TextSpan(
                          text: '₹${refundAmount.toStringAsFixed(0)}',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryText),
                        ),
                      ],
                    ),
                  ),
                  if (isPending)
                    GBButton(label: 'Process', onPressed: () => _showProcessDialog(ret)),
                  if (status.toLowerCase() == 'rejected' && ret['rejectionReason'] != null)
                    Flexible(
                      child: Text(
                        'Reason: ${ret['rejectionReason']}',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.errorText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
