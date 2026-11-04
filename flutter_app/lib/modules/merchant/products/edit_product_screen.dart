import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/models/product_model.dart';
import '../../../data/repositories/merchant_repository.dart';

part 'edit_product_screen_sections.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _repo = MerchantRepository();
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isDeleting = false;

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  String? _selectedSubcategory;

  late final TextEditingController _priceController;
  late final TextEditingController _mrpController;
  late final TextEditingController _stockController;
  late String _selectedUnit;
  late final TextEditingController _minOrderController;
  late final TextEditingController _prepTimeController;

  bool _isOrganic = true;
  final _tagsController = TextEditingController();
  final List<String> _tags = [];
  late final TextEditingController _keywordsController;
  
  bool _isLoadingCategories = true;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  // Preparations
  final List<Map<String, dynamic>> _preparationOptions = [];
  final _prepTypeController = TextEditingController();
  final _prepPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _descController = TextEditingController(text: p.description);
    _selectedCategoryId = p.categoryId;
    _selectedSubcategory = null;
    _priceController = TextEditingController(text: p.price.toString());
    _mrpController = TextEditingController(
        text: (p.price * 1.2).toStringAsFixed(0));
    _stockController = TextEditingController(text: p.stock.toString());
    _selectedUnit = p.unit.isNotEmpty ? p.unit : 'kg';
    _minOrderController = TextEditingController(text: '1');
    _prepTimeController = TextEditingController(text: '15');
    _isOrganic = p.isOrganic;
    _keywordsController =
        TextEditingController(text: p.name.toLowerCase());
    
    // Initialize preparations
    _preparationOptions.addAll(p.preparationOptions.map((e) => {
      'type': e.name,
      'price': e.additionalPrice,
    }));

    // Initialise image slots from the product's images list (max 3 shown)
    _existingImages = List.generate(
        3, (i) => i < p.images.length && p.images[i].isNotEmpty);
    
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _repo.getCategories();
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
        // If current product category isn't in the list, we might need to handle it
        // but usually it should be there.
      });
    } catch (_) {
      setState(() => _isLoadingCategories = false);
    }
  }

  // Tracks which image slots are filled from the product's images list
  late final List<bool> _existingImages;

  final List<String> _units = ['kg', 'piece', 'bunch', 'litre', 'gram'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _stockController.dispose();
    _minOrderController.dispose();
    _prepTimeController.dispose();
    _tagsController.dispose();
    _keywordsController.dispose();
    _prepTypeController.dispose();
    _prepPriceController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() => _tags.add(tag.trim()));
      _tagsController.clear();
    }
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await _repo.updateProduct(widget.product.id, {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategoryId,
        'price': double.tryParse(_priceController.text.trim()) ?? widget.product.price,
        'mrp': double.tryParse(_mrpController.text.trim()),
        'stock': int.tryParse(_stockController.text.trim()) ?? widget.product.stock,
        'unit': _selectedUnit,
        'minOrderQty': int.tryParse(_minOrderController.text.trim()) ?? 1,
        'prepTime': int.tryParse(_prepTimeController.text.trim()) ?? 15,
        'isOrganic': _isOrganic,
        'tags': _tags,
        'preparationOptions': _preparationOptions.map((e) => {
          'type': e['type'],
          'additionalPrice': e['price']
        }).toList(),
        'keywords': _keywordsController.text.trim(),
      });
      Get.back(result: true);
      GBSnack.success('Updated', 'Product updated successfully!', position: SnackPosition.BOTTOM);
    } catch (_) {
      GBSnack.plain('Error', 'Could not update product. Please try again.', position: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Delete Product', style: AppTextStyles.titleLarge),
        content: Text(
          'Are you sure you want to delete "${widget.product.name}"? This action cannot be undone.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          GBButton(label: 'Delete', onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);
              try {
                await _repo.deleteProduct(widget.product.id);
                Get.back(result: true);
                GBSnack.success('Deleted', 'Product removed successfully', position: SnackPosition.BOTTOM);
              } catch (_) {
                GBSnack.plain('Error', 'Could not delete product.', position: SnackPosition.BOTTOM);
              } finally {
                if (mounted) setState(() => _isDeleting = false);
              }
            }, backgroundColor: AppColors.error),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Edit Product', actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _isDeleting || _isSaving ? null : _deleteProduct,
            tooltip: 'Delete Product',
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.primary)),
          ),
        ], bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildTabBar(),
        ), leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        )),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _currentStep == 0
                  ? _buildStep1()
                  : _currentStep == 1
                      ? _buildStep2()
                      : _currentStep == 2
                          ? _buildStep3()
                          : _buildStep4(),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Basic', 'Pricing', 'Images', 'Prep'];
    return Container(
      color: AppColors.surface,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = i == _currentStep;
          return Expanded(
            child: Semantics(button: true, child: GestureDetector(
              onTap: () => setState(() => _currentStep = i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            )),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Product Name',
              hint: 'e.g. Fresh Tomatoes',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _descController,
              label: 'Description',
              hint: 'Describe your product...',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDropdown(
              label: 'Category',
              value: _selectedCategoryId,
              items: _categories.map((c) => {
                'id': (c['_id'] ?? c['id']).toString(),
                'name': (c['name'] ?? c['categoryName'] ?? '').toString()
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedCategoryId = v;
                  _selectedSubcategory = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDropdown(
              label: 'Subcategory',
              value: _selectedSubcategory,
              items: [], // Since we don't have dynamic subcategories yet, keeping it simple
              onChanged: (v) =>
                  setState(() => _selectedSubcategory = v),
              enabled: false, // Disabled for now to match dynamic category logic
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceController,
                  label: 'Selling Price (₹)',
                  keyboardType: TextInputType.number,
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _mrpController,
                  label: 'MRP (₹)',
                  keyboardType: TextInputType.number,
                  prefixText: '₹ ',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _stockController,
                  label: 'Stock Quantity',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  onChanged: (v) => setState(() => _selectedUnit = v!),
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: _units
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _minOrderController,
                  label: 'Min Order Qty',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _prepTimeController,
                  label: 'Prep Time (min)',
                  keyboardType: TextInputType.number,
                  suffixText: 'min',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Images', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(3, (i) => _buildImageSlot(i)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Additional Details', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco_outlined,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Organic Product', style: AppTextStyles.bodyMedium),
                  ],
                ),
                Switch(
                  value: _isOrganic,
                  onChanged: (v) => setState(() => _isOrganic = v),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Tags', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              ..._tags.map((tag) => Chip(
                    label: Text(tag,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: AppColors.primaryContainer,
                    side: const BorderSide(color: AppColors.primaryLight),
                  )),
              SizedBox(
                width: 140,
                height: 36,
                child: TextField(
                  controller: _tagsController,
                  style: AppTextStyles.bodySmall,
                  decoration: InputDecoration(
                    hintText: 'Add tag...',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                      borderSide:
                          BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                      borderSide:
                          BorderSide(color: AppColors.border),
                    ),
                    isDense: true,
                  ),
                  onSubmitted: _addTag,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _keywordsController,
            label: 'Search Keywords',
            hint: 'comma separated keywords',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preparation Options', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add choices for customers (e.g. Sliced, Peeled, Chopped)',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _prepTypeController,
                  label: 'Prep Name',
                  hint: 'Sliced',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextField(
                  controller: _prepPriceController,
                  label: '+ Price',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: () {
                  if (_prepTypeController.text.isNotEmpty) {
                    setState(() {
                      _preparationOptions.add({
                        'type': _prepTypeController.text.trim(),
                        'price': double.tryParse(_prepPriceController.text) ?? 0.0,
                      });
                      _prepTypeController.clear();
                      _prepPriceController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_preparationOptions.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _preparationOptions.length,
              itemBuilder: (context, index) {
                final opt = _preparationOptions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text(opt['type']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${opt['price']}'),
                        IconButton(tooltip: 'Delete', 
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => setState(() => _preparationOptions.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

}
