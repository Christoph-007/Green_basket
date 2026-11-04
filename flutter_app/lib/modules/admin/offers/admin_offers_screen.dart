import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import 'package:intl/intl.dart';

class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});

  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen>
    with SingleTickerProviderStateMixin {
  final _repo = AdminRepository();
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _platformOffers = [];
  List<Map<String, dynamic>> _merchantOffers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() => _isLoading = true);
    try {
      final all = await _repo.getOffers();
      final allMaps = all.map((e) => e as Map<String, dynamic>).toList();
      // createdBy == 'admin' → platform-wide; 'merchant' → merchant offers
      _platformOffers =
          allMaps.where((o) => o['createdBy'] == 'admin').toList();
      _merchantOffers =
          allMaps.where((o) => o['createdBy'] != 'admin').toList();
    } catch (e) {
      GBSnack.error('Error', 'Failed to load offers');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ────────────────────────── helpers ──────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.textSecondary;
      case 'expired':
        return AppColors.error;
      case 'exhausted':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'expired':
        return 'Expired';
      case 'exhausted':
        return 'Exhausted';
      default:
        return raw.capitalize ?? raw;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'percentage':
        return Icons.percent;
      case 'flat':
        return Icons.money_off;
      case 'bogo':
        return Icons.card_giftcard;
      case 'free_delivery':
        return Icons.local_shipping_outlined;
      case 'bundle':
        return Icons.inventory_2_outlined;
      default:
        return Icons.local_offer;
    }
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'percentage':
        return '% Off';
      case 'flat':
        return 'Flat ₹ Off';
      case 'bogo':
        return 'Buy One Get One';
      case 'free_delivery':
        return 'Free Delivery';
      case 'bundle':
        return 'Bundle Deal';
      default:
        return type.capitalize ?? type;
    }
  }

  String _discountText(Map<String, dynamic> o) {
    final type = (o['type'] ?? '').toString().toLowerCase();
    switch (type) {
      case 'percentage':
        return '${o['discountPercentage'] ?? 0}%';
      case 'flat':
        return '₹${o['discountAmount'] ?? 0}';
      case 'free_delivery':
        return 'Free';
      case 'bogo':
        return 'BOGO';
      case 'bundle':
        return '₹${o['discountAmount'] ?? o['bundlePrice'] ?? 0}';
      default:
        return '';
    }
  }

  Color _discountBgColor(String type) {
    switch (type.toLowerCase()) {
      case 'percentage':
        return AppColors.primaryLight;
      case 'flat':
        return AppColors.blue;
      case 'free_delivery':
        return AppColors.orange;
      case 'bogo':
        return AppColors.purple;
      case 'bundle':
        return AppColors.cyan;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  String _formatDateRange(Map<String, dynamic> o) {
    final start = _formatDate(o['startDate']);
    final end = _formatDate(o['endDate']);
    return '$start  →  $end';
  }

  String _applicableLabel(Map<String, dynamic> o) {
    final on = (o['applicableOn'] ?? 'all').toString().toLowerCase();
    switch (on) {
      case 'categories':
        final n = (o['categories'] as List?)?.length ?? 0;
        return '$n categor${n == 1 ? 'y' : 'ies'}';
      case 'products':
        final n = (o['products'] as List?)?.length ?? 0;
        return '$n product${n == 1 ? '' : 's'}';
      default:
        return 'All items';
    }
  }

  bool _isExpired(Map<String, dynamic> o) {
    final end = DateTime.tryParse((o['endDate'] ?? '').toString());
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }

  // ────────────────────────── build ───────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offers & Promotions'),
        leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Platform (${_platformOffers.length})'),
            Tab(text: 'Merchant (${_merchantOffers.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOfferSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Create Offer', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchOffers,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOffersList(_platformOffers),
                  _buildOffersList(_merchantOffers),
                ],
              ),
            ),
    );
  }

  Widget _buildOffersList(List<Map<String, dynamic>> offers) {
    if (offers.isEmpty) {
      return const Center(child: Text('No offers found.'));
    }
    // Sort: active first, then by creation date desc
    final sorted = List<Map<String, dynamic>>.from(offers)
      ..sort((a, b) {
        final aActive =
            (a['status'] ?? '').toString().toLowerCase() == 'active' ? 0 : 1;
        final bActive =
            (b['status'] ?? '').toString().toLowerCase() == 'active' ? 0 : 1;
        if (aActive != bActive) return aActive.compareTo(bActive);
        final aDate =
            DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
                DateTime(2020);
        final bDate =
            DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
                DateTime(2020);
        return bDate.compareTo(aDate);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _buildOfferCard(sorted[i]),
    );
  }

  // ────────────────────────── offer card ─────────────────────────────────

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final status = (offer['status'] ?? 'active').toString();
    final type = (offer['type'] ?? '').toString();
    final title = (offer['title'] ?? 'Untitled').toString();
    final description = (offer['description'] ?? '').toString();
    final usedCount = (offer['usedCount'] as num?)?.toInt() ?? 0;
    final usagePerUser = (offer['usagePerUser'] as num?)?.toInt() ?? 1;
    final isFlash = offer['isFlashSale'] == true;
    final minOrder = (offer['minOrderValue'] as num?)?.toDouble() ?? 0;
    final expired = _isExpired(offer);
    final couponCode = (offer['couponCode'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: expired ? 0.5 : 1,
      color: expired ? AppColors.surface.withValues(alpha: 0.7) : AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _showOfferDetail(offer),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1 – discount badge + title + status + options
              Row(
                children: [
                  // Discount badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _discountBgColor(type),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _discountText(offer),
                          style: AppTextStyles.labelLarge
                              .copyWith(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          _typeLabel(type),
                          style: AppTextStyles.labelSmall
                              .copyWith(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Title + flash badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(title,
                                  style: AppTextStyles.titleMedium,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (isFlash) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: const Text('⚡ Flash',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.error)),
                              ),
                            ],
                          ],
                        ),
                        if (description.isNotEmpty)
                          Text(description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ),

                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: _statusColor(status)),
                    ),
                  ),

                  // Options
                  IconButton(tooltip: 'More options', 
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: AppColors.textSecondary),
                    onPressed: () => _showOfferOptions(offer),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Row 2 – date range
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(_formatDateRange(offer),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Row 3 – meta chips
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: 4,
                children: [
                  _metaChip(
                      Icons.shopping_bag_outlined, _applicableLabel(offer)),
                  _metaChip(Icons.people_outline, 'Used: $usedCount'),
                  if (minOrder > 0)
                    _metaChip(Icons.receipt_long_outlined,
                        'Min ₹${minOrder.toStringAsFixed(0)}'),
                  if (couponCode.isNotEmpty)
                    _metaChip(
                        Icons.confirmation_number_outlined, couponCode),
                  _metaChip(Icons.repeat, '$usagePerUser/user'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      );

  // ────────────────────────── detail bottom sheet ─────────────────────────

  void _showOfferDetail(Map<String, dynamic> o) {
    final status = (o['status'] ?? 'active').toString();
    final type = (o['type'] ?? '').toString();
    final title = (o['title'] ?? 'Untitled').toString();
    final description = (o['description'] ?? '').toString();
    final usedCount = (o['usedCount'] as num?)?.toInt() ?? 0;
    final usagePerUser = (o['usagePerUser'] as num?)?.toInt() ?? 1;
    final isFlash = o['isFlashSale'] == true;
    final isPublic = o['isPublic'] != false;
    final minOrder = (o['minOrderValue'] as num?)?.toDouble() ?? 0;
    final maxDiscount = (o['maxDiscountAmount'] as num?)?.toDouble();
    final couponCode = (o['couponCode'] ?? '').toString();
    final applicableOn = (o['applicableOn'] ?? 'all').toString();
    final numCategories = (o['categories'] as List?)?.length ?? 0;
    final numProducts = (o['products'] as List?)?.length ?? 0;
    final usedBy = (o['usedBy'] as List?)?.length ?? 0;
    final createdAt = DateTime.tryParse(o['createdAt']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _discountBgColor(type).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(_typeIcon(type),
                        color: _discountBgColor(type), size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.headlineMedium),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    _statusColor(status).withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(_statusLabel(status),
                                  style: AppTextStyles.labelSmall.copyWith(
                                      color: _statusColor(status))),
                            ),
                            if (isFlash) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: const Text('⚡ Flash Sale',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.error)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xl),

              // Description
              if (description.isNotEmpty) ...[
                Text('Description', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Discount details
              Text('Discount Details', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _detailRow('Type', _typeLabel(type)),
              _detailRow('Discount', _discountText(o)),
              if (maxDiscount != null)
                _detailRow(
                    'Max Discount', '₹${maxDiscount.toStringAsFixed(0)}'),
              if (minOrder > 0)
                _detailRow(
                    'Min Order', '₹${minOrder.toStringAsFixed(0)}'),
              if (couponCode.isNotEmpty)
                _detailRow('Coupon Code', couponCode),
              _detailRow('Visibility', isPublic ? 'Public' : 'Private'),
              const SizedBox(height: AppSpacing.lg),

              // Validity
              Text('Validity', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _detailRow('Start', _formatDate(o['startDate'])),
              _detailRow('End', _formatDate(o['endDate'])),
              if (createdAt != null)
                _detailRow('Created',
                    DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)),
              const SizedBox(height: AppSpacing.lg),

              // Applicable on
              Text('Applicable On', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _detailRow(
                  'Scope', applicableOn.capitalize ?? applicableOn),
              if (numCategories > 0)
                _detailRow('Categories', '$numCategories'),
              if (numProducts > 0)
                _detailRow('Products', '$numProducts'),
              const SizedBox(height: AppSpacing.lg),

              // Usage
              Text('Usage', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _detailRow('Times Used', '$usedCount'),
              _detailRow('Per User Limit', '$usagePerUser'),
              _detailRow('Unique Users', '$usedBy'),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Expanded(
                child: Text(value,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  // ────────────────────────── offer options ───────────────────────────────

  void _showOfferOptions(Map<String, dynamic> offer) {
    final status =
        (offer['status'] ?? 'active').toString().toLowerCase();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text((offer['title'] ?? 'Offer').toString(),
                style: AppTextStyles.titleLarge),
            const Divider(),
            ListTile(
              leading: Icon(
                status == 'active'
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                color: AppColors.warning,
              ),
              title: Text(
                  status == 'active' ? 'Deactivate' : 'Activate'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final offerId =
                      (offer['_id'] ?? offer['id'] ?? '').toString();
                  final newStatus =
                      status == 'active' ? 'inactive' : 'active';
                  await _repo.updateOffer(
                      offerId, {'status': newStatus});
                  GBSnack.success('Success', 'Offer ${newStatus == 'active' ? 'activated' : 'deactivated'}');
                  _fetchOffers();
                } catch (e) {
                  GBSnack.error('Error', 'Failed to update offer status');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.error),
              title: const Text('Delete Offer',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Offer'),
                    content: const Text(
                        'Are you sure you want to delete this offer? This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style:
                                  TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    final offerId =
                        (offer['_id'] ?? offer['id'] ?? '').toString();
                    await _repo.deleteOffer(offerId);
                    GBSnack.success('Deleted', 'Offer removed');
                    _fetchOffers();
                  } catch (e) {
                    GBSnack.error('Error', 'Failed to delete offer');
                  }
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  // ────────────────────────── create offer sheet ──────────────────────────

  void _showCreateOfferSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountAmtCtrl = TextEditingController();
    final discountPctCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController(text: '0');
    final usagePerUserCtrl = TextEditingController(text: '1');
    final couponCtrl = TextEditingController();

    String selectedType = 'percentage';
    String applicableOn = 'all';
    bool isFlashSale = false;
    bool isPublic = true;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, sc) => SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin:
                        const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Create New Offer',
                    style: AppTextStyles.headlineMedium),
                const SizedBox(height: AppSpacing.lg),

                // Title
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Offer Title *',
                    hintText: 'e.g. Summer Sale — 20% Off',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of the offer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Type
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Offer Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'percentage',
                        child: Text('Percentage Off')),
                    DropdownMenuItem(
                        value: 'flat',
                        child: Text('Flat Amount Off')),
                    DropdownMenuItem(
                        value: 'free_delivery',
                        child: Text('Free Delivery')),
                    DropdownMenuItem(
                        value: 'bogo',
                        child: Text('Buy One Get One')),
                    DropdownMenuItem(
                        value: 'bundle',
                        child: Text('Bundle Deal')),
                  ],
                  onChanged: (v) => setSheetState(
                      () => selectedType = v ?? 'percentage'),
                ),
                const SizedBox(height: AppSpacing.md),

                // Discount amount / percentage (conditional)
                if (selectedType == 'percentage') ...[
                  TextField(
                    controller: discountPctCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount Percentage *',
                      hintText: 'e.g. 20',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (selectedType == 'flat' ||
                    selectedType == 'bundle') ...[
                  TextField(
                    controller: discountAmtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount Amount *',
                      hintText: 'e.g. 50',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Minimum order value
                TextField(
                  controller: minOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Order Value',
                    hintText: '0 for no minimum',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Applicable on
                DropdownButtonFormField<String>(
                  value: applicableOn,
                  decoration: const InputDecoration(
                    labelText: 'Applicable On',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'all', child: Text('All Items')),
                    DropdownMenuItem(
                        value: 'categories',
                        child: Text('Specific Categories')),
                    DropdownMenuItem(
                        value: 'products',
                        child: Text('Specific Products')),
                  ],
                  onChanged: (v) => setSheetState(
                      () => applicableOn = v ?? 'all'),
                ),
                const SizedBox(height: AppSpacing.md),

                // Coupon code
                TextField(
                  controller: couponCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Coupon Code (optional)',
                    hintText: 'e.g. SAVE20',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Usage per user
                TextField(
                  controller: usagePerUserCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Usage Per User',
                    hintText: '1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Date pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setSheetState(
                                () => startDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(
                                Icons.calendar_today,
                                size: 18),
                          ),
                          child: Text(DateFormat('dd MMM yyyy')
                              .format(startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setSheetState(
                                () => endDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(
                                Icons.calendar_today,
                                size: 18),
                          ),
                          child: Text(DateFormat('dd MMM yyyy')
                              .format(endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Switches
                SwitchListTile(
                  value: isFlashSale,
                  onChanged: (v) =>
                      setSheetState(() => isFlashSale = v),
                  title: const Text('Flash Sale'),
                  subtitle:
                      const Text('Mark as limited-time flash deal'),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: isPublic,
                  onChanged: (v) =>
                      setSheetState(() => isPublic = v),
                  title: const Text('Public Offer'),
                  subtitle: const Text(
                      'Visible to all users (uncheck for coupon-only)'),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _submitCreateOffer(
                      titleCtrl: titleCtrl,
                      descCtrl: descCtrl,
                      type: selectedType,
                      discountPctCtrl: discountPctCtrl,
                      discountAmtCtrl: discountAmtCtrl,
                      minOrderCtrl: minOrderCtrl,
                      applicableOn: applicableOn,
                      couponCtrl: couponCtrl,
                      usagePerUserCtrl: usagePerUserCtrl,
                      startDate: startDate,
                      endDate: endDate,
                      isFlashSale: isFlashSale,
                      isPublic: isPublic,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Create Offer',
                        style: TextStyle(
                            color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitCreateOffer({
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required String type,
    required TextEditingController discountPctCtrl,
    required TextEditingController discountAmtCtrl,
    required TextEditingController minOrderCtrl,
    required String applicableOn,
    required TextEditingController couponCtrl,
    required TextEditingController usagePerUserCtrl,
    required DateTime startDate,
    required DateTime endDate,
    required bool isFlashSale,
    required bool isPublic,
  }) async {
    // Validation
    if (titleCtrl.text.trim().isEmpty) {
      GBSnack.error('Error', 'Title is required');
      return;
    }
    if (type == 'percentage' &&
        discountPctCtrl.text.trim().isEmpty) {
      GBSnack.error('Error', 'Discount percentage is required');
      return;
    }
    if ((type == 'flat' || type == 'bundle') &&
        discountAmtCtrl.text.trim().isEmpty) {
      GBSnack.error('Error', 'Discount amount is required');
      return;
    }
    if (endDate.isBefore(startDate)) {
      GBSnack.error('Error', 'End date must be after start date');
      return;
    }

    final body = <String, dynamic>{
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'type': type,
      'applicableOn': applicableOn,
      'minOrderValue':
          double.tryParse(minOrderCtrl.text.trim()) ?? 0,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isFlashSale': isFlashSale,
      'usagePerUser':
          int.tryParse(usagePerUserCtrl.text.trim()) ?? 1,
      'isPublic': isPublic,
    };

    if (type == 'percentage') {
      body['discountPercentage'] =
          double.tryParse(discountPctCtrl.text.trim()) ?? 0;
    }
    if (type == 'flat' || type == 'bundle') {
      body['discountAmount'] =
          double.tryParse(discountAmtCtrl.text.trim()) ?? 0;
    }
    if (couponCtrl.text.trim().isNotEmpty) {
      body['couponCode'] = couponCtrl.text.trim().toUpperCase();
    }

    try {
      await _repo.createOffer(body);
      Navigator.pop(context);
      GBSnack.success('Success', 'Offer created successfully');
      _fetchOffers();
    } catch (e) {
      final msg = e.toString().contains('coupon')
          ? 'Coupon code already exists'
          : 'Failed to create offer';
      GBSnack.error('Error', msg);
    }
  }
}
