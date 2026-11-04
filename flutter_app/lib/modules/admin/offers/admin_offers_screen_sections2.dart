part of 'admin_offers_screen.dart';

extension _AdminOffersScreenStateSections2 on _AdminOffersScreenState {
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
                                child: Text('⚡ Flash Sale',
                                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.errorText)),
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

  void _showOfferOptions(Map<String, dynamic> offer) {
    final status =
        (offer['status'] ?? 'active').toString().toLowerCase();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
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
              leading: Icon(Icons.delete_outline,
                  color: AppColors.errorText),
              title: Text('Delete Offer',
                  style: TextStyle(color: AppColors.errorText)),
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
                          child: Text('Delete',
                              style:
                                  TextStyle(color: AppColors.errorText))),
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
                GBTextField(label: 'Offer Title *', hint: 'e.g. Summer Sale — 20% Off', controller: titleCtrl),
                const SizedBox(height: AppSpacing.md),

                // Description
                GBTextField(label: 'Description', hint: 'Brief description of the offer', controller: descCtrl, maxLines: 2),
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
                  GBTextField(label: 'Discount Percentage *', hint: 'e.g. 20', controller: discountPctCtrl, keyboardType: TextInputType.number, suffixText: '%'),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (selectedType == 'flat' ||
                    selectedType == 'bundle') ...[
                  GBTextField(label: 'Discount Amount *', hint: 'e.g. 50', controller: discountAmtCtrl, keyboardType: TextInputType.number, prefixText: '₹ '),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Minimum order value
                GBTextField(label: 'Minimum Order Value', hint: '0 for no minimum', controller: minOrderCtrl, keyboardType: TextInputType.number, prefixText: '₹ '),
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
                GBTextField(label: 'Coupon Code (optional)', hint: 'e.g. SAVE20', controller: couponCtrl, textCapitalization: TextCapitalization.characters),
                const SizedBox(height: AppSpacing.md),

                // Usage per user
                GBTextField(label: 'Usage Per User', hint: '1', controller: usagePerUserCtrl, keyboardType: TextInputType.number),
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
                  child: GBButton(label: 'Create Offer', onPressed: () => _submitCreateOffer(
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
                    ), backgroundColor: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
