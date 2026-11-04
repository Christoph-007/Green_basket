part of 'disputes_admin_screen.dart';

extension _DisputesAdminScreenStateSections1 on _DisputesAdminScreenState {
  String _categoryLabel(String raw) {
    switch (raw) {
      case 'damaged_item':
        return 'Damaged Item';
      case 'wrong_item':
        return 'Wrong Item';
      case 'missing_item':
        return 'Missing Item';
      case 'late_delivery':
        return 'Late Delivery';
      case 'refund_issue':
        return 'Refund Issue';
      default:
        return raw.replaceAll('_', ' ').capitalize ?? raw;
    }
  }

  IconData _categoryIcon(String raw) {
    switch (raw) {
      case 'damaged_item':
        return Icons.broken_image_outlined;
      case 'wrong_item':
        return Icons.swap_horiz;
      case 'missing_item':
        return Icons.search_off;
      case 'late_delivery':
        return Icons.schedule;
      case 'refund_issue':
        return Icons.money_off;
      default:
        return Icons.report_outlined;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String _priorityLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'urgent':
        return '🔴 Urgent';
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return raw.capitalize ?? raw;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.error;
      case 'escalated':
        return AppColors.errorDark;
      case 'investigating':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textSecondary;
      default:
        return AppColors.info;
    }
  }

  String _statusLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'escalated':
        return 'Escalated';
      case 'investigating':
        return 'Investigating';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return raw.capitalize ?? raw;
    }
  }

  int _daysOpen(Map<String, dynamic> d) {
    final raw = d['createdAt'];
    if (raw == null) return 0;
    final created = DateTime.tryParse(raw.toString());
    if (created == null) return 0;
    return DateTime.now().difference(created).inDays;
  }

  String _customerName(Map<String, dynamic> d) {
    try {
      final raised = d['raisedBy'];
      if (raised is Map) {
        final user = raised['user'];
        if (user is Map) return user['name']?.toString() ?? 'Unknown';
      }
    } catch (_) {}
    return 'Unknown';
  }

  String _customerEmail(Map<String, dynamic> d) {
    try {
      final raised = d['raisedBy'];
      if (raised is Map) {
        final user = raised['user'];
        if (user is Map) return user['email']?.toString() ?? '';
      }
    } catch (_) {}
    return '';
  }

  String _customerPhone(Map<String, dynamic> d) {
    try {
      final raised = d['raisedBy'];
      if (raised is Map) {
        final user = raised['user'];
        if (user is Map) return user['phone']?.toString() ?? '';
      }
    } catch (_) {}
    return '';
  }

  String _orderId(Map<String, dynamic> d) {
    try {
      final order = d['order'];
      if (order is Map) return order['orderId']?.toString() ?? '—';
    } catch (_) {}
    return '—';
  }

  double _orderAmount(Map<String, dynamic> d) {
    try {
      final order = d['order'];
      if (order is Map) {
        return (order['totalAmount'] as num?)?.toDouble() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  // open, escalated → tab 0 (Open)
  // investigating   → tab 1 (Under Review)
  // resolved, closed → tab 2 (Resolved)
  int _statusTab(Map<String, dynamic> d) {
    final s = (d['status'] ?? '').toString().toLowerCase();
    if (s == 'resolved' || s == 'closed') return 2;
    if (s == 'investigating') return 1;
    return 0; // open, escalated
  }

  List<Map<String, dynamic>> _filteredDisputes(int tab) {
    return _disputes.where((d) {
      final tabMatch = _statusTab(d) == tab;
      final cat = (d['category'] ?? '').toString();
      final filterMatch = _selectedFilter == 'All' || cat == _selectedFilter;
      return tabMatch && filterMatch;
    }).toList();
  }

  Widget _buildSummaryStats() {
    final open = _disputes.where((d) => _statusTab(d) == 0).length;
    final review = _disputes.where((d) => _statusTab(d) == 1).length;
    final resolved = _disputes.where((d) => _statusTab(d) == 2).length;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          _statItem('Open', '$open', AppColors.error),
          _statDivider(),
          _statItem('Under Review', '$review', AppColors.warning),
          _statDivider(),
          _statItem('Resolved', '$resolved', AppColors.success),
        ],
      ),
    );
  }

  Widget _statItem(String label, String count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(count,
              style: AppTextStyles.headlineLarge.copyWith(color: color)),
          Text(label,
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> dispute) {
    final priority = (dispute['priority'] ?? 'low').toString();
    final category = (dispute['category'] ?? '').toString();
    final status = (dispute['status'] ?? 'open').toString();
    final disputeId = (dispute['disputeId'] ?? '').toString();
    final days = _daysOpen(dispute);
    final customer = _customerName(dispute);
    final orderId = _orderId(dispute);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _showDisputeDetail(dispute),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1 – dispute ID + priority + days open
              Row(
                children: [
                  Flexible(
                    child: Text(
                      disputeId.length > 18
                          ? '#${disputeId.substring(disputeId.length - 10)}'
                          : '#$disputeId',
                      style: AppTextStyles.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _priorityColor(priority).withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      _priorityLabel(priority),
                      style: AppTextStyles.labelSmall.copyWith(
                          color: _priorityColor(priority)),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${days}d open',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.warning),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Row 2 – order + status badge
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Order #$orderId',
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: AppTextStyles.labelSmall.copyWith(
                          color: _statusColor(status)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Row 3 – customer name
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(customer,
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Row 4 – category chip + description preview
              Row(
                children: [
                  Icon(_categoryIcon(category),
                      size: 14, color: AppColors.primaryText),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      _categoryLabel(category),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primaryText),
                    ),
                  ),
                ],
              ),
              // Description preview
              if ((dispute['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  dispute['description'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
