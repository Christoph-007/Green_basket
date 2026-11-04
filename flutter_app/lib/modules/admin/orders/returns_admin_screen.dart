import 'package:flutter/material.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';

class ReturnsAdminScreen extends StatefulWidget {
  const ReturnsAdminScreen({super.key});

  @override
  State<ReturnsAdminScreen> createState() => _ReturnsAdminScreenState();
}

class _ReturnsAdminScreenState extends State<ReturnsAdminScreen>
    with SingleTickerProviderStateMixin {
  final _repo = AdminRepository();
  late TabController _tabController;
  final _refundController = TextEditingController();
  bool _approving = true;
  bool _isLoading = true;

  List<Map<String, dynamic>> _returns = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchReturns();
  }

  Future<void> _fetchReturns() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getReturns();
      _returns = data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('fetchReturns error: $e');
      Get.snackbar('Error', 'Failed to load returns',
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  @override
  void dispose() {
    _tabController.dispose();
    _refundController.dispose();
    super.dispose();
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
                  const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
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
                TextField(
                  controller: _refundController,
                  decoration: const InputDecoration(
                    labelText: 'Refund Amount',
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _approving ? AppColors.success : AppColors.error,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final retId = (ret['_id'] ?? ret['id'] ?? '').toString();
                  await _repo.processReturn(retId, {
                    'action': _approving ? 'approve' : 'reject',
                    'refundAmount': double.tryParse(_refundController.text) ?? 0,
                  });
                  _fetchReturns();
                  Get.snackbar(
                    _approving ? 'Return Approved' : 'Return Rejected',
                    _approving
                        ? 'Refund of ₹${_refundController.text} will be processed.'
                        : 'Return has been rejected.',
                    backgroundColor: _approving ? AppColors.success : AppColors.error,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar('Error', 'Failed to process return',
                      backgroundColor: AppColors.error, colorText: Colors.white);
                }
              },
              child: Text(_approving ? 'Approve & Refund' : 'Reject'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Returns & Refunds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Processing'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReturns,
              child: Column(
                children: [
                  _buildStats(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [0, 1, 2].map((tab) {
                        final list = _returns.where((r) => _statusTab(r) == tab).toList();
                        return list.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.assignment_return_outlined, size: 48, color: AppColors.textHint),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'No returns in this category.',
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: list.length,
                                itemBuilder: (_, i) => _buildReturnCard(list[i]),
                              );
                      }).toList(),
                    ),
                  ),
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
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text('Exchange', style: AppTextStyles.labelSmall.copyWith(color: AppColors.secondary)),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
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
                    const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(userName, style: AppTextStyles.bodySmall),
                    if (userEmail != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('($userEmail)', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
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
                    color: AppColors.warning.withOpacity(0.1),
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
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  if (isPending)
                    ElevatedButton(
                      onPressed: () => _showProcessDialog(ret),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Process'),
                    ),
                  if (status.toLowerCase() == 'rejected' && ret['rejectionReason'] != null)
                    Flexible(
                      child: Text(
                        'Reason: ${ret['rejectionReason']}',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
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
                  color: _statusColor(status).withOpacity(0.1),
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
              const Text('Reason', style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text(reason, style: AppTextStyles.bodyMedium),

              if (rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
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
                const Text('Items', style: AppTextStyles.titleLarge),
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
                                  color: AppColors.warning.withOpacity(0.1),
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showProcessDialog(ret);
                    },
                    child: const Text('Process This Return'),
                  ),
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
