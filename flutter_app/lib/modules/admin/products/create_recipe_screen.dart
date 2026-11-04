import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import '../admin_controller.dart';

class CreateRecipeScreen extends StatefulWidget {
  final Map<String, dynamic>? recipe;

  const CreateRecipeScreen({super.key, this.recipe});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AdminRepository();
  bool _isPublishing = false;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');
  final _cookTimeController = TextEditingController(text: '30');
  final _prepTimeController = TextEditingController(text: '15');

  String _selectedCategory = 'Lunch';
  final _categories = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  final List<Map<String, TextEditingController>> _ingredients = [];
  final List<TextEditingController> _steps = [];
  final List<String> _unitOptions = ['piece', 'kg', 'g', 'cup', 'tbsp', 'tsp', 'liter', 'ml', 'pinch', 'to-taste', 'bundle'];

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      final r = widget.recipe!;
      _nameController.text = r['name']?.toString() ?? '';
      _descController.text = r['description']?.toString() ?? '';
      _servingsController.text = r['servings']?.toString() ?? '4';
      _cookTimeController.text = r['cookTime']?.toString() ?? '30';
      _prepTimeController.text = r['prepTime']?.toString() ?? '15';

      final cat = r['category']?.toString() ?? '';
      final matchedCat = _categories.firstWhere((c) => c.toLowerCase() == cat.toLowerCase(), orElse: () => 'Lunch');
      _selectedCategory = matchedCat;

      final ings = r['ingredients'] as List?;
      if (ings != null && ings.isNotEmpty) {
        for (var ing in ings) {
          _ingredients.add({
            'name': TextEditingController(text: ing['name']?.toString() ?? ''),
            'qty': TextEditingController(text: ing['quantity']?.toString() ?? ''),
            'unit': TextEditingController(text: ing['unit']?.toString() ?? 'piece'),
          });
        }
      } else {
        _ingredients.add({'name': TextEditingController(), 'qty': TextEditingController(), 'unit': TextEditingController()});
      }

      final instrs = r['instructions'] as List?;
      if (instrs != null && instrs.isNotEmpty) {
        // the backend stores instructions as [{stepNumber: 1, instruction: "..."}]
        for (var inst in instrs) {
          if (inst is Map) {
            _steps.add(TextEditingController(text: inst['instruction']?.toString() ?? ''));
          } else {
            _steps.add(TextEditingController(text: inst.toString()));
          }
        }
      } else {
        _steps.add(TextEditingController());
      }
    } else {
      _ingredients.add({'name': TextEditingController(), 'qty': TextEditingController(), 'unit': TextEditingController()});
      _steps.add(TextEditingController());
    }
  }

  void _addIngredient() {
    setState(() => _ingredients.add({
          'name': TextEditingController(),
          'qty': TextEditingController(),
          'unit': TextEditingController(),
        }));
  }

  void _removeIngredient(int index) {
    if (_ingredients.length > 1) {
      _ingredients[index].forEach((_, c) => c.dispose());
      setState(() => _ingredients.removeAt(index));
    }
  }

  void _addStep() {
    setState(() => _steps.add(TextEditingController()));
  }

  void _removeStep(int index) {
    if (_steps.length > 1) {
      _steps[index].dispose();
      setState(() => _steps.removeAt(index));
    }
  }

  void _publish() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isPublishing = true);
      try {
        final payload = {
          'name': _nameController.text.trim(),
          'description': _descController.text.trim().isEmpty
              ? 'No description provided.'
              : _descController.text.trim(),
          'category': _selectedCategory.toLowerCase(),
          'servings': int.tryParse(_servingsController.text) ?? 4,
          'prepTime': int.tryParse(_prepTimeController.text) ?? 15,
          'cookTime': int.tryParse(_cookTimeController.text) ?? 30,
          'ingredients': _ingredients
              .where((ing) => ing['name']!.text.trim().isNotEmpty)
              .toList()
              .asMap()
              .entries
              .map((e) => {
                    'name': e.value['name']!.text.trim(),
                    'quantity': double.tryParse(e.value['qty']!.text.trim()) ?? 1.0,
                    'unit': e.value['unit']!.text.trim().isEmpty
                        ? 'piece'
                        : e.value['unit']!.text.trim(),
                  })
              .toList(),
          'instructions': _steps
              .asMap()
              .entries
              .where((e) => e.value.text.trim().isNotEmpty)
              .map((e) => {
                    'stepNumber': e.key + 1,
                    'instruction': e.value.text.trim(),
                  })
              .toList(),
        };

        if (widget.recipe != null) {
          await _repo.updateRecipe(widget.recipe!['_id'] ?? widget.recipe!['id'], payload);
        } else {
          await _repo.createRecipe(payload);
        }

        // Refresh the admin recipes list so the new recipe shows immediately
        final adminController = Get.find<AdminController>();
        await adminController.fetchRecipes();
        Get.back();
        GBSnack.success(widget.recipe != null ? 'Recipe Updated' : 'Recipe Published', '${_nameController.text} has been successfully saved.');
      } catch (e) {
        GBSnack.error('Error', 'Failed to save recipe: $e');
      } finally {
        if (mounted) setState(() => _isPublishing = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _servingsController.dispose();
    _cookTimeController.dispose();
    _prepTimeController.dispose();
    for (final ing in _ingredients) {
      ing.forEach((_, c) => c.dispose());
    }
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Create Recipe', leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        )),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: AppSpacing.md),
              _buildCategoryPicker(),
              const SizedBox(height: AppSpacing.md),
              _buildImageUpload(),
              const SizedBox(height: AppSpacing.md),
              _buildTimingsRow(),
              const SizedBox(height: AppSpacing.md),
              _buildIngredients(),
              const SizedBox(height: AppSpacing.md),
              _buildInstructions(),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: GBButton(label: 'Publish Recipe', isLoading: _isPublishing, onPressed: _publish),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Basic Info', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Recipe Name'),
              validator: (v) => v == null || v.isEmpty ? 'Recipe name is required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Meal Type', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: AppColors.primary,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return Card(
      child: InkWell(
        onTap: () => GBSnack.plain('Not available yet', 'Recipe photo upload is coming soon. The recipe is saved without a photo.', position: SnackPosition.BOTTOM),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.textHint),
              SizedBox(height: AppSpacing.sm),
              Text('Tap to upload recipe image', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimingsRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Details', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Servings',
                      suffixText: 'ppl',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prep Time',
                      suffixText: 'min',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cook Time',
                      suffixText: 'min',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredients() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ingredients', style: AppTextStyles.titleLarge),
                TextButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            ..._ingredients.asMap().entries.map((e) {
              final i = e.key;
              final ing = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: ing['name'],
                        decoration: InputDecoration(labelText: 'Ingredient ${i + 1}'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: ing['qty'],
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: ing['unit']!.text.isEmpty ? null : ing['unit']!.text,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        isExpanded: true,
                        items: _unitOptions
                            .map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) ing['unit']!.text = val;
                        },
                      ),
                    ),
                    IconButton(tooltip: 'Decrease', 
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                      onPressed: () => _removeIngredient(i),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Instructions', style: AppTextStyles.titleLarge),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Step'),
                ),
              ],
            ),
            ..._steps.asMap().entries.map((e) {
              final i = e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 12, right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _steps[i],
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Step ${i + 1} instructions...',
                        ),
                      ),
                    ),
                    IconButton(tooltip: 'Decrease', 
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                      onPressed: () => _removeStep(i),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
