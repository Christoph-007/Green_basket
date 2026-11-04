import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_text_field.dart';
import 'package:greenbasket_app/widgets/common/gb_card.dart';
import 'package:greenbasket_app/widgets/common/gb_filter_chip.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_gradient_header.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'merchant_analytics_screen.dart';
import '../widgets/admin_drawer.dart';
import '../admin_controller.dart';

class AdminMerchantsScreen extends StatefulWidget {
  const AdminMerchantsScreen({super.key});

  @override
  State<AdminMerchantsScreen> createState() => _AdminMerchantsScreenState();
}

class _AdminMerchantsScreenState extends State<AdminMerchantsScreen> {
  final controller = Get.find<AdminController>();
  String _selectedFilter = 'All';
  String _searchQuery = '';

String _getMerchantStatus(Map<String, dynamic> merchant) {
    final vStatus = merchant['verificationStatus'];
    if (vStatus == 'approved') return 'Active';
    if (vStatus == 'rejected') return 'Rejected';
    if (vStatus == 'pending' || vStatus == 'under-review') return 'Pending';
    
    if (merchant['status'] != null) {
      final s = merchant['status'].toString().toLowerCase();
      if (s == 'active' || s == 'approved') return 'Active';
      if (s == 'rejected') return 'Rejected';
    }
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildAdminHeader(context),
          Expanded(
            child: Obx(() {
              final filteredMerchants = controller.merchants.where((m) {
                final merchant = m as Map<String, dynamic>;
                String status = _getMerchantStatus(merchant);
                bool matchesFilter = _selectedFilter == 'All' || status == _selectedFilter;
                bool matchesSearch = merchant['businessName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                     merchant['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                return matchesFilter && matchesSearch;
              }).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPill('All'),
                        const SizedBox(width: 8),
                        _buildPill('Active'),
                        const SizedBox(width: 8),
                        _buildPill('Pending'),
                        const SizedBox(width: 8),
                        _buildPill('Rejected'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredMerchants.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('No merchants found', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ...filteredMerchants.map((merchant) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildMerchantCard(merchant as Map<String, dynamic>),
                    )),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context) {
    return GBGradientHeader(
      title: 'All Merchants',
      trailingIcon: Icons.storefront,
      subtitle: Text('Admin › Merchants',
          style: AppTextStyles.bodyCompact.copyWith(color: Colors.white.withValues(alpha: 0.9))),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: GBCard.decoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search merchants...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String title) => GBFilterChip(
        label: title,
        selected: _selectedFilter == title,
        onTap: () => setState(() => _selectedFilter = title),
      );

  String _merchantId(Map<String, dynamic> merchant) =>
      (merchant['_id'] ?? merchant['id'] ?? '').toString();

  Future<void> _approve(Map<String, dynamic> merchant) async {
    final id = _merchantId(merchant);
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve merchant?'),
        content: Text(
            '${merchant['businessName'] ?? 'This merchant'} will be able to list products and receive orders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.verifyMerchant(id, true);
  }

  Future<void> _reject(Map<String, dynamic> merchant) async {
    final id = _merchantId(merchant);
    if (id.isEmpty) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectReasonDialog(
          businessName: (merchant['businessName'] ?? 'this merchant').toString()),
    );
    if (reason != null && reason.isNotEmpty) {
      await controller.verifyMerchant(id, false, rejectionReason: reason);
    }
  }

  /// Pending merchants can be approved or rejected; a rejected one can still be approved.
  Widget _buildDecisionButtons(Map<String, dynamic> merchant, String status) {
    return Row(
      children: [
        if (status == 'Pending') ...[
          Expanded(
            child: GBButton(label: 'Reject', onPressed: () => _reject(merchant), variant: GBButtonVariant.outline, foregroundColor: AppColors.errorText),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: GBButton(label: 'Approve', onPressed: () => _approve(merchant)),
        ),
      ],
    );
  }

  Widget _buildMerchantCard(Map<String, dynamic> merchant) {
    final businessName = merchant['businessName'] ?? 'Unknown';
    final email = merchant['email'] ?? 'No email';
    final status = _getMerchantStatus(merchant);
    
    Color color;
    Color statusColor;
    
    switch (status) {
      case 'Active':
        color = AppColors.primarySoft;
        statusColor = AppColors.brandAccent;
        break;
      case 'Pending':
        color = AppColors.amberContainer;
        statusColor = AppColors.warningDeep;
        break;
      default:
        color = AppColors.errorSoft;
        statusColor = AppColors.errorStrong;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
            Get.to(() => const MerchantAnalyticsScreen(), arguments: merchant);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: GBCard.decoration(),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: Text(businessName.isNotEmpty ? businessName[0] : 'M',
                        style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(businessName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(email, style: AppTextStyles.bodyCompact.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                    child: Text(status,
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, color: statusColor)),
                  ),
                  if (merchant['isStoreOpen'] == false) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('CLOSED',
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ),
                  ],
                ],
              ),
              if (status != 'Active') ...[
                const SizedBox(height: 12),
                _buildDecisionButtons(merchant, status),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  final String businessName;
  const _RejectReasonDialog({required this.businessName});

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reject ${widget.businessName}?'),
      content: GBTextField(label: 'Reason (shown to the merchant)', controller: _reasonCtrl, maxLines: 3),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final reason = _reasonCtrl.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(context, reason);
          },
          child: Text('Reject', style: TextStyle(color: AppColors.errorText)),
        ),
      ],
    );
  }
}
