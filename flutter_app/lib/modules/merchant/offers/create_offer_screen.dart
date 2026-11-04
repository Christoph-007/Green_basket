import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';

part 'create_offer_screen_widgets.dart';
part 'create_offer_screen_sections.dart';

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _repo = MerchantRepository();
  OfferType _selectedType = OfferType.percentage;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _couponCodeController = TextEditingController();
  final _discountController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxCapController = TextEditingController();
  final _buyQtyController = TextEditingController(text: '2');
  final _getQtyController = TextEditingController(text: '1');
  final _usageLimitController = TextEditingController();

  bool _allProducts = true;
  bool _usageLimitEnabled = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  bool _isLoadingProducts = true;
  List<Map<String, dynamic>> _products = [];
  final Set<String> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    // This is a placeholder for categories if needed, but we focus on products here
    try {
      await _repo.getCategories();
      setState(() => _isLoadingProducts = false);
    } catch (_) {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _loadMyProducts() async {
    if (_products.isNotEmpty) return;
    
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _repo.getMyProducts();
      setState(() {
        _products = products
            .map((p) => {'id': p.id, 'name': p.name})
            .toList();
        _isLoadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _couponCodeController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    _maxCapController.dispose();
    _buyQtyController.dispose();
    _getQtyController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? now : (_startDate ?? now),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createOffer() async {
    if (_titleController.text.trim().isEmpty) {
      GBSnack.plain('Validation Error', 'Please enter an offer title', position: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final String type;
      bool isFlashSale = false;
      
      switch (_selectedType) {
        case OfferType.percentage:
          type = 'percentage';
          break;
        case OfferType.fixed:
          type = 'flat';
          break;
        case OfferType.buyXGetY:
          type = 'bogo'; // Mapping buyXGetY to bogo
          break;
        case OfferType.flashSale:
          type = 'percentage'; // Flash sales usually use percentage
          isFlashSale = true;
          break;
      }

      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'couponCode': _couponCodeController.text.trim().isEmpty 
            ? null 
            : _couponCodeController.text.trim().toUpperCase(),
        'type': type,
        'isFlashSale': isFlashSale,
        'applicableOn': _allProducts ? 'all' : 'products',
        if (!_allProducts && _selectedProductIds.isNotEmpty)
          'products': _selectedProductIds.toList(),
        'startDate': (_startDate ?? DateTime.now()).toIso8601String(),
        'endDate': (_endDate ?? DateTime.now().add(const Duration(days: 7))).toIso8601String(),
        if (_usageLimitEnabled &&
            _usageLimitController.text.trim().isNotEmpty)
          'totalUsageLimit': int.tryParse(_usageLimitController.text.trim()),
      };

      final discountVal = double.tryParse(_discountController.text.trim()) ?? 0.0;
      if (type == 'percentage') {
        payload['discountPercentage'] = discountVal;
      } else if (type == 'flat') {
        payload['discountAmount'] = discountVal;
      } else if (type == 'bogo') {
        payload['buyQuantity'] = int.tryParse(_buyQtyController.text) ?? 2;
        payload['getQuantity'] = int.tryParse(_getQtyController.text) ?? 1;
      }

      if (_minOrderController.text.trim().isNotEmpty) {
        payload['minOrderValue'] =
            double.tryParse(_minOrderController.text.trim());
      }
      if (type == 'percentage' &&
          _maxCapController.text.trim().isNotEmpty) {
        payload['maxDiscountCap'] =
            double.tryParse(_maxCapController.text.trim());
      }

      await _repo.createOffer(payload);
      Get.back(result: true);
      GBSnack.success('Offer Created', 'Your offer is now live!', position: SnackPosition.BOTTOM);
    } catch (_) {
      GBSnack.plain('Error', 'Could not create offer. Please try again.', position: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Create Offer', backIcon: Icons.arrow_back_ios_new, showDivider: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offer type selector
            Text('Offer Type', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _buildTypeSelector(),
            const SizedBox(height: AppSpacing.lg),

            // Flash sale banner
            if (_selectedType == OfferType.flashSale) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.error, AppColors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on,
                        color: Colors.white, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Flash Sale',
                              style: AppTextStyles.titleLarge
                                  .copyWith(color: Colors.white)),
                          Text(
                            'Limited time · High urgency · Max impact',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text('00:00:00',
                            style: AppTextStyles.titleLarge.copyWith(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700)),
                        Text('countdown preview',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: Colors.white60)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Form
            Text('Offer Details', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _titleController,
              label: 'Offer Title',
              hint: 'e.g. Summer Fresh Sale',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your offer details',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _couponCodeController,
              label: 'Coupon Code (Optional)',
              hint: 'e.g. FRESH20',
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppSpacing.md),

            if (_selectedType == OfferType.buyXGetY) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _buyQtyController,
                      label: 'Buy Quantity',
                      hint: '2',
                      keyboardType: TextInputType.number,
                      prefixText: 'Buy ',
                    ),
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text('→', style: TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: _buildTextField(
                      controller: _getQtyController,
                      label: 'Get Free',
                      hint: '1',
                      keyboardType: TextInputType.number,
                      prefixText: 'Get ',
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildTextField(
                controller: _discountController,
                label: _selectedType == OfferType.percentage
                    ? 'Discount Percentage'
                    : 'Discount Amount (₹)',
                hint:
                    _selectedType == OfferType.percentage ? '20' : '50',
                keyboardType: TextInputType.number,
                suffixText:
                    _selectedType == OfferType.percentage ? '%' : null,
                prefixText:
                    _selectedType == OfferType.fixed ? '₹ ' : null,
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _minOrderController,
                    label: 'Min Order (₹)',
                    hint: '200',
                    keyboardType: TextInputType.number,
                    prefixText: '₹ ',
                  ),
                ),
                if (_selectedType == OfferType.percentage) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxCapController,
                      label: 'Max Discount Cap',
                      hint: '100',
                      keyboardType: TextInputType.number,
                      prefixText: '₹ ',
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Applicable products
            Text('Applicable Products', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('All Products',
                        style: AppTextStyles.bodyMedium),
                    subtitle: Text(
                        'Apply offer to your entire catalog',
                        style: AppTextStyles.bodySmall),
                    value: _allProducts,
                    onChanged: (v) {
                      setState(() => _allProducts = v);
                      if (!v && _products.isEmpty) {
                        _loadMyProducts();
                      }
                    },
                    activeColor: AppColors.primary,
                  ),
                  if (!_allProducts) ...[
                    const Divider(height: 1),
                    if (_isLoadingProducts)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text('No products available.',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                      )
                    else
                      ..._products.map((product) {
                        final id = (product['id'] ?? '').toString();
                        final name =
                            (product['name'] ?? 'Product').toString();
                        return CheckboxListTile(
                          title: Text(name,
                              style: AppTextStyles.bodyMedium),
                          value: _selectedProductIds.contains(id),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selectedProductIds.add(id);
                            } else {
                              _selectedProductIds.remove(id);
                            }
                          }),
                          activeColor: AppColors.primary,
                          controlAffinity:
                              ListTileControlAffinity.leading,
                        );
                      }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Validity
            Text('Validity Period', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                    child: _buildDatePicker(
                        'Start Date', _startDate, () => _pickDate(true))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: _buildDatePicker(
                        'End Date', _endDate, () => _pickDate(false))),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Usage limit
            Text('Usage Limit', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Limit usage count',
                        style: AppTextStyles.bodyMedium),
                    value: _usageLimitEnabled,
                    onChanged: (v) =>
                        setState(() => _usageLimitEnabled = v),
                    activeColor: AppColors.primary,
                  ),
                  if (_usageLimitEnabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildTextField(
                        controller: _usageLimitController,
                        label: 'Max uses',
                        hint: '100',
                        keyboardType: TextInputType.number,
                        suffixText: 'uses',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: GBButton(label: 'Create Offer', isLoading: _isSubmitting, onPressed: _createOffer),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = [
      (OfferType.percentage, Icons.percent, 'Percentage\nDiscount'),
      (OfferType.fixed, Icons.discount_outlined, 'Fixed\nAmount'),
      (OfferType.buyXGetY, Icons.redeem_outlined, 'Buy X\nGet Y'),
      (OfferType.flashSale, Icons.flash_on, 'Flash\nSale'),
    ];

    return Row(
      children: types.map((t) {
        final isSelected = _selectedType == t.$1;
        Color color = isSelected ? AppColors.primary : AppColors.textHint;
        return Expanded(
          child: Semantics(button: true, child: GestureDetector(
            onTap: () => setState(() => _selectedType = t.$1),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md, horizontal: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(t.$2, color: color, size: 24),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t.$3,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: color),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )),
        );
      }).toList(),
    );
  }

}
