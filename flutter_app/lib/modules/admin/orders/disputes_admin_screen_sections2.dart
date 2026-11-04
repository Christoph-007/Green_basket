part of 'disputes_admin_screen.dart';

extension _DisputesAdminScreenStateSections2 on _DisputesAdminScreenState {
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
                      color: _statusColor(status).withValues(alpha: 0.12),
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
                    color: AppColors.success.withValues(alpha: 0.06),
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
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
