import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_text_field.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/user_repository.dart';

import 'package:greenbasket_app/modules/auth/auth_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  DateTime? _selectedDob;

  // Dietary preferences toggle state
  final Set<String> _dietPrefs = {};
  final List<Map<String, String>> _dietOptions = [
    {'label': 'Vegetarian', 'value': 'vegetarian'},
    {'label': 'Vegan', 'value': 'vegan'},
    {'label': 'Gluten-Free', 'value': 'gluten-free'},
    {'label': 'Dairy-Free', 'value': 'dairy-free'},
    {'label': 'Organic Only', 'value': 'organic-only'},
  ];

  final Set<String> _allergens = {};
  final List<String> _allAllergens = [
    'Nuts',
    'Dairy',
    'Gluten',
    'Soy',
    'Eggs',
  ];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final user = Get.find<AuthController>().user.value;
    if (user != null) {
      _nameCtrl.text = user.name;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone;
      if (user.dateOfBirth != null) {
        _selectedDob = user.dateOfBirth;
        _dobCtrl.text = DateFormat('d MMMM yyyy').format(user.dateOfBirth!);
      }
      
      _dietPrefs.addAll(user.dietaryPreferences);
      _allergens.addAll(user.allergies);
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final repo = UserRepository();
      await repo.updateProfile({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'dateOfBirth': _selectedDob?.toIso8601String(),
        'dietaryPreferences': _dietPrefs.toList(),
        'allergies': _allergens.toList(),
      });
      
      // Refresh AuthController profile
      await Get.find<AuthController>().fetchProfile();

      Get.back();
      GBSnack.success('Profile Updated', 'Your profile has been saved successfully', position: SnackPosition.BOTTOM);
    } catch (e) {
      GBSnack.error('Error', 'Failed to update profile: $e', position: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Edit Profile', backIcon: Icons.arrow_back_ios_new_rounded, actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              'Save',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.primaryText),
            ),
          ),
        ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile image
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_rounded,
                                color: AppColors.primaryText, size: 50),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Semantics(button: true, child: GestureDetector(
                              onTap: () => GBSnack.plain('Not available yet', 'Changing your profile photo is coming soon.', position: SnackPosition.BOTTOM),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 14),
                              ),
                            )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Personal details section
                    const _SectionHeader(title: 'Personal Details'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildField(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Phone number is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Semantics(button: true, child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDob ?? DateTime(1995),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now()
                              .subtract(const Duration(days: 365 * 10)),
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
                            _selectedDob = picked;
                            _dobCtrl.text =
                                DateFormat('d MMMM yyyy').format(picked);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: _buildField(
                          controller: _dobCtrl,
                          label: 'Date of Birth',
                          icon: Icons.cake_outlined,
                          suffixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                    )),
                    const SizedBox(height: AppSpacing.xl),

                    // Dietary preferences
                    const _SectionHeader(title: 'Dietary Preferences'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Select all that apply',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _dietOptions.map((opt) {
                        final label = opt['label']!;
                        final value = opt['value']!;
                        final selected = _dietPrefs.contains(value);
                        return Semantics(button: true, child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _dietPrefs.remove(value);
                              } else {
                                _dietPrefs.add(value);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selected) ...[
                                  const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  label,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ));
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Allergens
                    const _SectionHeader(title: 'Allergens to Avoid'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'We will filter products with these allergens',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _allAllergens.map((allergen) {
                        final selected = _allergens.contains(allergen);
                        return Semantics(button: true, child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _allergens.remove(allergen);
                              } else {
                                _allergens.add(allergen);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: selected
                                    ? AppColors.error
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selected) ...[
                                  Icon(Icons.warning_amber_rounded,
                                      color: AppColors.errorText, size: 14),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  allergen,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: selected
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ));
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: GBButton(label: 'Save Changes', isLoading: _isSaving, onPressed: _save, backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    IconData? suffixIcon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return GBTextField(label: label, controller: controller, keyboardType: keyboardType ?? TextInputType.text, validator: validator, enabled: enabled, prefixIcon: icon, suffix: suffixIcon != null
            ? Icon(suffixIcon,
                color: AppColors.textSecondary, size: 18)
            : null);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.titleLarge);
  }
}
