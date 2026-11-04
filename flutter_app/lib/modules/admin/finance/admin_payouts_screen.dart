import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../admin_controller.dart';
import '../widgets/export_csv_button.dart';

class AdminPayoutsScreen extends StatefulWidget {
  const AdminPayoutsScreen({super.key});

  @override
  State<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends State<AdminPayoutsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.warning;
      case 'Processing':
        return AppColors.info;
      case 'Completed':
        return AppColors.success;
      case 'Rejected':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }

  List<Map<String, dynamic>> _payoutsForTab(int tab) {
    String status = 'Pending';
    if (tab == 1) status = 'Processing';
    if (tab == 2) status = 'Completed';
    return controller.payouts.where((p) => (p['status'] ?? 'Pending') == status).toList().cast<Map<String, dynamic>>();
  }

  void _showProcessDialog(Map<String, dynamic> payout) {
    final amount = payout['amount']?.toString() ?? '0';
    final name = payout['merchant']?['name']?.toString() ?? payout['agent']?['name']?.toString() ?? 'Unknown';
    final id = payout['_id'] ?? payout['id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Process Payout?', style: AppTextStyles.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient: $name', style: AppTextStyles.bodyMedium),
            Text('Amount: ${AppHelpers.formatCurrencyFlexible(amount)}', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GBButton(label: 'Process', onPressed: () {
              controller.processPayout(id, true);
              Navigator.pop(ctx);
            }),
        ],
      ),
    );
  }

  void _showBulkProcessDialog() {
    final pending = _payoutsForTab(0);
    if (pending.isEmpty) return;
    
    double totalAmount = 0;
    for (var p in pending) {
      totalAmount += (p['amount'] as num?)?.toDouble() ?? 0.0;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Bulk Process Payouts?', style: AppTextStyles.titleLarge),
        content: Text(
          'Process all ${pending.length} pending payouts (Total: ${AppHelpers.formatCurrency(totalAmount)})?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GBButton(label: 'Process All', onPressed: () {
              final ids = pending.map((p) => p['_id'] ?? p['id']).cast<String>().toList();
              controller.bulkProcessPayouts(ids, true);
              Navigator.pop(ctx);
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Payout Requests', actions: [
          ExportCsvButton(
            path: '/financial/admin/payouts/export',
            noun: 'payouts',
            params: () => {
              'status': const ['Pending', 'Processing', 'Completed'][_tabController.index],
            },
          ),
        ], bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Processing'),
            Tab(text: 'Completed'),
          ],
        ), leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        )),
      body: Column(
        children: [
          Obx(() => _buildPendingBanner()),
          Expanded(
            child: Obx(() => TabBarView(
              controller: _tabController,
              children: [0, 1, 2].map((tab) {
                final payouts = _payoutsForTab(tab);
                return payouts.isEmpty
                    ? const Center(child: Text('No payouts in this category.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: payouts.length,
                        itemBuilder: (_, i) => _buildPayoutCard(payouts[i]),
                      );
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBanner() {
    final pending = _payoutsForTab(0);
    double totalAmount = 0;
    for (var p in pending) {
      totalAmount += (p['amount'] as num?)?.toDouble() ?? 0.0;
    }

    return Container(
      color: AppColors.warning.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Pending: ${AppHelpers.formatCurrency(totalAmount)}', style: AppTextStyles.titleMedium.copyWith(color: AppColors.warning)),
                Text('${pending.length} payout requests awaiting', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          GBButton(label: 'Process All', onPressed: pending.isNotEmpty ? _showBulkProcessDialog : null, backgroundColor: AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(Map<String, dynamic> payout) {
    final status = payout['status'] as String? ?? 'Pending';
    final name = payout['merchant']?['name']?.toString() ?? payout['agent']?['name']?.toString() ?? 'Unknown';
    final amount = payout['amount']?.toString() ?? '0';
    final date = payout['createdAt']?.toString().split('T')[0] ?? 'N/A';
    final type = payout['merchant'] != null ? 'Merchant' : 'Agent';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    type == 'Merchant' ? Icons.store_outlined : Icons.delivery_dining_outlined,
                    color: AppColors.primary,
                    size: 20
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.titleMedium),
                      Text('$type Payout', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.labelSmall.copyWith(color: _statusColor(status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount', style: AppTextStyles.bodySmall),
                    Text(AppHelpers.formatCurrencyFlexible(amount), style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Requested', style: AppTextStyles.bodySmall),
                    Text(date, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ],
            ),
            if (status == 'Pending') ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: GBButton(label: 'Process Payout', onPressed: () => _showProcessDialog(payout)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
