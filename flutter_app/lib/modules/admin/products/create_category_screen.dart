import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/providers/api_provider.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import '../admin_controller.dart';

class CreateCategoryScreen extends StatefulWidget {
  final Map<String, dynamic>? category;

  const CreateCategoryScreen({super.key, this.category});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AdminRepository();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedIcon = '🛒';
  String? _selectedParentId; // stores the ObjectId of the parent
  bool _isActive = true;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _parentCategories = [];
  bool _loadingParents = true;

  final _icons = [
    '🥦', '🍎', '🥛', '🧺', '🍵', '🌿', '🍗', '🐟', '🥩',
    '🍞', '🧁', '🥗', '🛒', '🏷️', '🍋', '🥕', '🧅', '🫐',
  ];

  @override
  void initState() {
    super.initState();
    _fetchParentCategories();

    if (widget.category != null) {
      final c = widget.category!;
      _nameController.text = c['name']?.toString() ?? '';
      _descController.text = c['description']?.toString() ?? '';
      if (_icons.contains(c['icon']?.toString())) {
        _selectedIcon = c['icon']?.toString() ?? '🛒';
      }
      _isActive = c['isActive'] ?? true;
      if (c['parent'] != null) {
         _selectedParentId = c['parent'] is Map 
            ? c['parent']['_id']?.toString() 
            : c['parent']?.toString();
      }
    }
  }

  Future<void> _fetchParentCategories() async {
    try {
      final response = await ApiProvider().get('/categories');
      final data = response.data;
      if (data['success'] == true && data['data'] is List) {
        setState(() {
          _parentCategories = List<Map<String, dynamic>>.from(data['data']);
          _loadingParents = false;
        });
      }
    } catch (_) {
      setState(() => _loadingParents = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final body = <String, dynamic>{
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'icon': _selectedIcon,
          'isActive': _isActive,
        };
        if (_selectedParentId != null) {
          body['parent'] = _selectedParentId;
        }

        if (widget.category != null) {
          final id = widget.category!['_id']?.toString() ?? widget.category!['id']?.toString() ?? '';
          await _repo.updateCategory(id, body);
        } else {
          await _repo.createCategory(body);
        }

        final adminController = Get.find<AdminController>();
        await adminController.fetchCategories();

        Get.back();
        GBSnack.success(widget.category != null ? 'Category Updated' : 'Category Created', '${_nameController.text} has been saved successfully.');
      } catch (e) {
        String msg = 'Failed to create category';
        if (e.toString().contains('409') || e.toString().contains('already exists')) {
          msg = 'A category with this name already exists';
        }
        GBSnack.error('Error', msg);
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.category != null ? 'Edit Category' : 'Create Category'),
        leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconPicker(),
              const SizedBox(height: AppSpacing.md),
              _buildNameField(),
              const SizedBox(height: AppSpacing.md),
              _buildParentDropdown(),
              const SizedBox(height: AppSpacing.md),
              _buildDescriptionField(),
              const SizedBox(height: AppSpacing.md),
              _buildActiveToggle(),
              const SizedBox(height: AppSpacing.xl),
              _buildSubmitButton(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category Icon', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Center(
                    child: Text(_selectedIcon, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Tap an icon below to select it for your category',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: _icons.length,
              itemBuilder: (_, i) {
                final icon = _icons[i];
                final isSelected = _selectedIcon == icon;
                return Semantics(button: true, child: GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryContainer : AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category Name', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g. Organic Vegetables'),
              validator: (v) => v == null || v.isEmpty ? 'Category name is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Parent Category', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (_loadingParents)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedParentId,
                decoration: const InputDecoration(hintText: 'None (Top-level)'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None (Top-level)'),
                  ),
                  ..._parentCategories.map((c) => DropdownMenuItem<String>(
                        value: c['_id']?.toString(),
                        child: Text(c['name']?.toString() ?? ''),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedParentId = v),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Description', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Briefly describe this category...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active', style: AppTextStyles.titleMedium),
                  Text('Category will be visible to customers', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Switch(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: GBButton(label: widget.category != null ? 'Update Category' : 'Create Category', isLoading: _isSubmitting, onPressed: _submit),
    );
  }
}
