import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../config/constants.dart';
import '../../../widgets/common/gb_button.dart';
import '../../../widgets/common/gb_text_field.dart';
import '../../../utils/validators.dart';
import '../auth_controller.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _authCtrl = Get.find<AuthController>();
  String _selectedRole = AppConstants.roleCustomer;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _authCtrl.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _selectedRole,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(tooltip: 'Back', 
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Account', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Join GreenBasket and get fresh produce delivered',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // Error message
                Obx(() {
                  if (_authCtrl.errorMessage.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border:
                          Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _authCtrl.errorMessage.value,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.errorText),
                    ),
                  );
                }),

                GBTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameCtrl,
                  validator: Validators.name,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                GBTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                GBTextField(
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                GBTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  controller: _passwordCtrl,
                  isPassword: true,
                  validator: Validators.password,
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 16),
                GBTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  controller: _confirmPassCtrl,
                  isPassword: true,
                  validator: (value) =>
                      Validators.confirmPassword(value, _passwordCtrl.text),
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 24),

                // Role selection
                Text('I want to join as', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setState) => Column(
                    children: [
                      _RoleTile(
                        role: AppConstants.roleCustomer,
                        label: 'Customer',
                        description: 'Buy fresh organic produce',
                        icon: Icons.shopping_basket_outlined,
                        isSelected: _selectedRole == AppConstants.roleCustomer,
                        onTap: () =>
                            setState(() => _selectedRole = AppConstants.roleCustomer),
                      ),
                      const SizedBox(height: 8),
                      _RoleTile(
                        role: AppConstants.roleMerchant,
                        label: 'Merchant / Farmer',
                        description: 'Sell your farm produce',
                        icon: Icons.store_outlined,
                        isSelected: _selectedRole == AppConstants.roleMerchant,
                        onTap: () =>
                            setState(() => _selectedRole = AppConstants.roleMerchant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Obx(() => GBButton(
                      label: 'Create Account',
                      onPressed: _submit,
                      isLoading: _authCtrl.isLoading.value,
                      isFullWidth: true,
                    )),
                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      Semantics(button: true, child: GestureDetector(
                        onTap: () => Get.toNamed(Routes.login),
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String role;
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.titleMedium),
                  Text(description,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primaryText, size: 22),
          ],
        ),
      ),
    ));
  }
}
