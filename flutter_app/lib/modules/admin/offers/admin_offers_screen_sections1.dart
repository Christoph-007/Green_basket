part of 'admin_offers_screen.dart';

extension _AdminOffersScreenStateSections1 on _AdminOffersScreenState {
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

  Widget _buildOffersList(List<Map<String, dynamic>> offers) {
    if (offers.isEmpty) {
      return const EmptyState(icon: Icons.local_offer_outlined, title: 'No offers found');
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
                                child: Text('⚡ Flash',
                                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.errorText)),
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
                    icon: Icon(Icons.more_vert,
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
                  Icon(Icons.calendar_today_outlined,
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
}
