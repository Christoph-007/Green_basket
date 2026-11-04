import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_card.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';

part 'add_product_screen_sections.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _repo = MerchantRepository();
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;

  // Step 1
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  // Step 2
  final _priceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _stockController = TextEditingController();
  String _selectedUnit = 'kg';
  final _minOrderController = TextEditingController(text: '1');
  final _prepTimeController = TextEditingController(text: '30');

  // Step 3
  bool _isOrganic = false;
  final _tagsController = TextEditingController();
  final _keywordsController = TextEditingController();
  final List<String> _tags = [];

  // Step 4: Preparation
  final List<Map<String, dynamic>> _preparationOptions = [];
  final _prepTypeController = TextEditingController();
  final _prepPriceController = TextEditingController();

  // Dynamic data from API
  List<Map<String, dynamic>> _categories = [];
  final List<String> _units = ['kg', 'piece', 'bunch', 'litre', 'gram', 'pack'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _repo.getCategories();
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    } catch (_) {
      setState(() => _isLoadingCategories = false);
    }
  }

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

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty) {
        GBSnack.plain('Required', 'Please enter a product name');
        return;
      }
      if (_selectedCategoryId == null) {
        GBSnack.plain('Required', 'Please select a category');
        return;
      }
    }
    if (_currentStep == 1) {
      if (_priceController.text.isEmpty || _stockController.text.isEmpty) {
        GBSnack.plain('Required', 'Please fill in price and stock');
        return;
      }
    }
    if (_currentStep < 3) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _submitProduct() async {
    setState(() => _isSubmitting = true);
    try {
      await _repo.addProduct({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategoryId,
        'categoryName': _selectedCategoryName,
        'price': double.tryParse(_priceController.text) ?? 0,
        'mrp': double.tryParse(_mrpController.text) ?? 0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'unit': _selectedUnit,
        'minOrderQuantity': int.tryParse(_minOrderController.text) ?? 1,
        'preparationTime': int.tryParse(_prepTimeController.text) ?? 30,
        'isOrganic': _isOrganic,
        'tags': _tags,
        'preparationOptions': _preparationOptions.map((e) => {
          'type': e['type'],
          'additionalPrice': double.tryParse(e['price'].toString()) ?? 0
        }).toList(),
        'keywords': _keywordsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      });
      Get.back(result: true);
      GBSnack.success('Success', 'Product added successfully!', position: SnackPosition.BOTTOM);
    } catch (e) {
      GBSnack.error('Error', 'Failed to add product: ${e.toString().split(':').last.trim()}',
          position: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Add Product', bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildStepIndicator(),
        ), leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        )),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 0
                    ? _buildStep1()
                    : _currentStep == 1
                        ? _buildStep2()
                        : _currentStep == 2
                            ? _buildStep3()
                            : _buildStep4(),
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Product Information'),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _nameController,
            label: 'Product Name',
            hint: 'e.g. Fresh Tomatoes',
            validator: (v) =>
                v == null || v.isEmpty ? 'Please enter product name' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _descController,
            label: 'Description',
            hint: 'Describe your product...',
            maxLines: 4,
          ),
          const SizedBox(height: AppSpacing.md),
          // Dynamic category dropdown from API
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            onChanged: (v) {
              final cat = _categories
                  .firstWhereOrNull((c) => (c['_id'] ?? c['id']) == v);
              setState(() {
                _selectedCategoryId = v;
                _selectedCategoryName =
                    cat?['name'] ?? cat?['categoryName'] ?? '';
              });
            },
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(labelText: 'Category'),
            hint: const Text('Select category'),
            items: _categories.map((cat) {
              final id = cat['_id'] ?? cat['id'] ?? '';
              final name = cat['name'] ?? cat['categoryName'] ?? '';
              return DropdownMenuItem<String>(
                  value: id.toString(), child: Text(name));
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Pricing & Stock'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceController,
                  label: 'Selling Price (₹)',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  prefixText: '₹ ',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _mrpController,
                  label: 'MRP (₹)',
                  hint: '0.00',
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
                  hint: '0',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
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
                  hint: '1',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _prepTimeController,
                  label: 'Prep Time (min)',
                  hint: '30',
                  keyboardType: TextInputType.number,
                  suffixText: 'min',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.primaryText, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Set MRP higher than selling price to show discount to customers',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primaryText),
                  ),
                ),
              ],
            ),
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
          _sectionHeader('Images'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(3, (i) => _buildImageSlot(i)),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionHeader('Additional Details'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: GBCard.decoration(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco_outlined,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Organic Product',
                        style: AppTextStyles.bodyMedium),
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
          _sectionHeader('Tags'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              ..._tags.map((tag) => Chip(
                    label: Text(tag,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primaryText)),
                    deleteIcon:
                        const Icon(Icons.close, size: 14),
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
            hint: 'tomato, fresh, organic (comma separated)',
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
          _sectionHeader('Preparation Options'),
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
                        'price': double.tryParse(_prepPriceController.text) ?? 0,
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
                          icon: Icon(Icons.delete_outline, color: AppColors.errorText),
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

  Widget _sectionHeader(String title) =>
      Text(title, style: AppTextStyles.titleLarge);

}
