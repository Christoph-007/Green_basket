import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';
import 'package:intl/intl.dart';
import 'package:greenbasket_app/modules/merchant/widgets/merchant_bottom_nav.dart';

class MerchantDisputesScreen extends StatefulWidget {
  const MerchantDisputesScreen({super.key});

  @override
  State<MerchantDisputesScreen> createState() => _MerchantDisputesScreenState();
}

class _MerchantDisputesScreenState extends State<MerchantDisputesScreen> with SingleTickerProviderStateMixin {
  final _repo = MerchantRepository();
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _disputes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDisputes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDisputes() async {
    setState(() => _isLoading = true);
    try {
      _disputes = await _repo.getDisputes();
    } catch (e) {
      GBSnack.plain('Error', 'Failed to load disputes');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _statusTab(String status) {
    status = status.toLowerCase();
    if (status == 'resolved' || status == 'closed') return 2;
    if (status == 'investigating') return 1;
    return 0; // open, escalated
  }

  List<Map<String, dynamic>> _filteredDisputes(int tab) {
    return _disputes.where((d) => _statusTab(d['status']?.toString() ?? 'open') == tab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const MerchantBottomNav(highlight: false),
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Disputes', bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'Under Review'),
            Tab(text: 'Resolved'),
          ],
        ), leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ), backgroundColor: AppColors.surface),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDisputes,
              child: TabBarView(
                controller: _tabController,
                children: [0, 1, 2].map((tabIndex) {
                  final disputes = _filteredDisputes(tabIndex);
                  if (disputes.isEmpty) return _buildEmptyState(tabIndex);
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: disputes.length,
                    itemBuilder: (context, index) => _buildDisputeCard(disputes[index]),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    String message = 'No disputes reported yet.';
    if (tabIndex == 1) message = 'No disputes under review.';
    if (tabIndex == 2) message = 'No resolved disputes yet.';
    return ListView(
      children: [
        SizedBox(height: Get.height * 0.2),
        Icon(Icons.gavel_outlined, size: 80, color: AppColors.textSecondary),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            message,
            style: AppTextStyles.titleMedium,
          ),
        ),
        Center(
          child: Text(
            'Keep up the good work!',
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> d) {
    final status = d['status']?.toString() ?? 'open';
    final category = d['category']?.toString() ?? 'Other';
    final orderId = _getOrderId(d);
    final date = _formatDate(d['createdAt']);
    final canResolve = status.toLowerCase() != 'resolved' && status.toLowerCase() != 'closed';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showDisputeDetail(d),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #$orderId',
                    style: AppTextStyles.titleMedium,
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                date,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const Divider(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(Icons.label_outline, size: 16, color: AppColors.primaryText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                d['description']?.toString() ?? '',
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (canResolve) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: GBButton(label: 'Resolve', onPressed: () => _showResolveDialog(d), leadingIcon: Icons.gavel, variant: GBButtonVariant.outline, foregroundColor: AppColors.success),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDisputeDetail(Map<String, dynamic> d) {
    final status = d['status']?.toString() ?? 'open';
    final category = d['category']?.toString() ?? 'Other';
    final orderId = _getOrderId(d);
    final date = _formatDate(d['createdAt']);
    final desc = d['description']?.toString() ?? '';
    final resolution = d['resolution'] as Map<String, dynamic>?;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dispute Detail', style: AppTextStyles.headlineMedium),
                  IconButton(tooltip: 'Close', onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              _detailRow('Status', status.toUpperCase()),
              _detailRow('Order', '#$orderId'),
              _detailRow('Category', category),
              _detailRow('Raised On', date),
              const SizedBox(height: AppSpacing.md),
              Text('Description', style: AppTextStyles.titleMedium),
              const SizedBox(height: 4),
              Text(desc, style: AppTextStyles.bodyMedium),
              if (resolution != null) ...[
                const Divider(height: AppSpacing.xl),
                Text('Resolution', style: AppTextStyles.titleMedium.copyWith(color: AppColors.success)),
                const SizedBox(height: 4),
                _detailRow('Type', (resolution['type'] ?? '').toString().capitalizeFirst!),
                if (resolution['amount'] != null)
                  _detailRow('Amount', '₹${resolution['amount']}'),
                if (resolution['description'] != null)
                  _detailRow('Desc', resolution['description'].toString()),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (status.toLowerCase() != 'resolved' && status.toLowerCase() != 'closed')
                SizedBox(
                  width: double.infinity,
                  child: GBButton(label: 'RESOLVE DISPUTE', onPressed: () {
                      Get.back();
                      _showResolveDialog(d);
                    }, backgroundColor: AppColors.success),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showResolveDialog(Map<String, dynamic> d) {
    String resType = 'refund';
    final amtController = TextEditingController();
    final descController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Resolve Dispute'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: resType,
                items: ['refund', 'replacement', 'partial_refund', 'compensation', 'no_action']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.capitalizeFirst!)))
                    .toList(),
                onChanged: (v) => resType = v!,
                decoration: const InputDecoration(labelText: 'Resolution Type'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: amtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (optional)', prefixText: '₹'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('CANCEL')),
          GBButton(label: 'SUBMIT', onPressed: () async {
              final amt = double.tryParse(amtController.text) ?? 0;
              final desc = descController.text.trim();
              if (desc.isEmpty) {
                GBSnack.plain('Error', 'Please provide a description');
                return;
              }
              Get.back();
              setState(() => _isLoading = true);
              try {
                await _repo.resolveDispute(d['_id'], {
                  'resolutionType': resType,
                  'amount': amt,
                  'description': desc,
                });
                GBSnack.plain('Success', 'Dispute resolved');
                _fetchDisputes();
              } catch (e) {
                GBSnack.plain('Error', 'Failed to resolve dispute');
                setState(() => _isLoading = false);
              }
            }, backgroundColor: AppColors.success),
        ],
      ),
    );
  }

  String _getOrderId(Map<String, dynamic> d) {
    if (d['order'] is Map) {
      return (d['order']['orderId'] ?? d['order']['_id']).toString();
    }
    return 'N/A';
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
        color = AppColors.success;
        break;
      case 'investigating':
        color = AppColors.warning;
        break;
      case 'open':
        color = AppColors.error;
        break;
      default:
        color = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
