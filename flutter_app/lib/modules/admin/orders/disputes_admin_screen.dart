import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import 'package:intl/intl.dart';

class DisputesAdminScreen extends StatefulWidget {
  const DisputesAdminScreen({super.key});

  @override
  State<DisputesAdminScreen> createState() => _DisputesAdminScreenState();
}

class _DisputesAdminScreenState extends State<DisputesAdminScreen>
    with SingleTickerProviderStateMixin {
  final _repo = AdminRepository();
  late TabController _tabController;
  String _selectedFilter = 'All';
  bool _isLoading = true;

  // Actual backend categories
  final _filters = [
    'All',
    'damaged_item',
    'wrong_item',
    'missing_item',
    'late_delivery',
    'refund_issue',
  ];

  List<Map<String, dynamic>> _disputes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDisputes();
  }

  Future<void> _fetchDisputes() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getDisputes();
      _disputes = data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      GBSnack.error('Error', 'Failed to load disputes');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- helpers ---------------------------------------------------------------

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- tab mapping -----------------------------------------------------------

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

  // --- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Disputes'),
        leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'Under Review'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDisputes,
              child: Column(
                children: [
                  _buildSummaryStats(),
                  _buildFilterChips(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [0, 1, 2].map((tab) {
                        final disputes = _filteredDisputes(tab);
                        return disputes.isEmpty
                            ? const Center(
                                child: Text('No disputes in this category.'))
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.all(AppSpacing.md),
                                itemCount: disputes.length,
                                itemBuilder: (_, i) =>
                                    _buildDisputeCard(disputes[i]),
                              );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- summary stats ---------------------------------------------------------

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

  Widget _statDivider() =>
      Container(width: 1, height: 36, color: AppColors.border);

  // --- filter chips ----------------------------------------------------------

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final filter = _filters[i];
          final isSelected = _selectedFilter == filter;
          final chipLabel =
              filter == 'All' ? 'All' : _categoryLabel(filter);
          return ChoiceChip(
            label: Text(chipLabel),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            selectedColor: AppColors.primary,
            labelStyle: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            backgroundColor: AppColors.surface,
            side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border),
          );
        },
      ),
    );
  }

  // --- dispute card ----------------------------------------------------------

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
                      color: _priorityColor(priority).withOpacity(0.1),
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
                  const Icon(Icons.receipt_long_outlined,
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
                      color: _statusColor(status).withOpacity(0.1),
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
                  const Icon(Icons.person_outline,
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
                      size: 14, color: AppColors.primary),
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
                          .copyWith(color: AppColors.primary),
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

  // --- detail bottom sheet ---------------------------------------------------

  void _showDisputeDetail(Map<String, dynamic> d) {
    final status = (d['status'] ?? 'open').toString();
    final priority = (d['priority'] ?? 'low').toString();
    final category = (d['category'] ?? '').toString();
    final disputeId = (d['disputeId'] ?? '').toString();
    final description = (d['description'] ?? '').toString();
    final customer = _customerName(d);
    final email = _customerEmail(d);
    final phone = _customerPhone(d);
    final orderId = _orderId(d);
    final orderAmt = _orderAmount(d);
    final days = _daysOpen(d);
    final createdAt = DateTime.tryParse(d['createdAt']?.toString() ?? '');
    final resolution = d['resolution'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title + status
              Row(
                children: [
                  Expanded(
                    child: Text('Dispute Details',
                        style: AppTextStyles.headlineMedium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(_statusLabel(status),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: _statusColor(status))),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(disputeId,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const Divider(height: AppSpacing.xl),

              // Priority + Category + Days
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _chip(
                      _priorityLabel(priority), _priorityColor(priority)),
                  _chip(_categoryLabel(category), AppColors.primary),
                  _chip('${days}d open', AppColors.warning),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Description
              Text('Description', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(description, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.lg),

              // Customer info
              _sectionTitle('Customer'),
              _infoRow(Icons.person_outline, customer),
              if (email.isNotEmpty)
                _infoRow(Icons.email_outlined, email),
              if (phone.isNotEmpty)
                _infoRow(Icons.phone_outlined, phone),
              const SizedBox(height: AppSpacing.lg),

              // Order info
              _sectionTitle('Order'),
              _infoRow(Icons.receipt_long_outlined, 'Order #$orderId'),
              if (orderAmt > 0)
                _infoRow(Icons.currency_rupee,
                    'Order Amount: ₹${orderAmt.toStringAsFixed(0)}'),
              if (createdAt != null)
                _infoRow(Icons.calendar_today_outlined,
                    'Filed: ${DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)}'),
              const SizedBox(height: AppSpacing.lg),

              // Resolution (if any)
              if (resolution != null) ...[
                _sectionTitle('Resolution'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.06),
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            (resolution['type'] ?? '')
                                .toString()
                                .replaceAll('_', ' ')
                                .capitalize ??
                                '',
                            style: AppTextStyles.titleMedium
                                .copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                      if (resolution['description'] != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(resolution['description'].toString(),
                            style: AppTextStyles.bodySmall),
                      ],
                      if (resolution['amount'] != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Amount: ₹${resolution['amount']}',
                          style: AppTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (resolution['resolvedAt'] != null &&
                          DateTime.tryParse(resolution['resolvedAt'].toString()) != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Resolved: ${DateFormat('dd MMM yyyy').format(DateTime.parse(resolution['resolvedAt'].toString()))}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Action buttons for non-resolved disputes
              if (status != 'resolved' && status != 'closed') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showResolveDialog(d);
                        },
                        icon: const Icon(Icons.gavel, size: 18),
                        label: const Text('Resolve'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side:
                              const BorderSide(color: AppColors.success),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(label,
            style: AppTextStyles.labelSmall.copyWith(color: color)),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(t, style: AppTextStyles.titleMedium),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(text, style: AppTextStyles.bodySmall)),
          ],
        ),
      );

  // --- resolve dialog --------------------------------------------------------

  void _showResolveDialog(Map<String, dynamic> d) {
    String resolutionType = 'refund';
    final descController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Resolve Dispute'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: resolutionType,
                  decoration:
                      const InputDecoration(labelText: 'Resolution Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'refund', child: Text('Refund')),
                    DropdownMenuItem(
                        value: 'replacement',
                        child: Text('Replacement')),
                    DropdownMenuItem(
                        value: 'compensation',
                        child: Text('Compensation')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => resolutionType = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                if (resolutionType == 'refund' ||
                    resolutionType == 'compensation')
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Amount (₹)'),
                  ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final body = <String, dynamic>{
                    'resolution': {
                      'type': resolutionType,
                      'description': descController.text.trim(),
                    },
                  };
                  if (amountController.text.isNotEmpty) {
                    body['resolution'] = {
                      ...body['resolution'] as Map<String, dynamic>,
                      'amount':
                          double.tryParse(amountController.text) ?? 0,
                    };
                  }
                  await _repo.resolveDispute(
                      d['_id']?.toString() ?? '', body);
                  GBSnack.success('Success', 'Dispute resolved');
                  _fetchDisputes();
                } catch (e) {
                  GBSnack.error('Error', 'Failed to resolve dispute');
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
              child: const Text('Confirm',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
