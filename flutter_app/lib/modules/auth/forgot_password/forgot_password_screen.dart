import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../widgets/common/gb_button.dart';
import '../../../widgets/common/gb_text_field.dart';
import '../../../utils/validators.dart';
import '../auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _authCtrl = Get.find<AuthController>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _authCtrl.forgotPassword(_emailCtrl.text.trim());
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
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_reset_outlined,
                    size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text('Forgot Password?', style: AppTextStyles.displayMedium),
              const SizedBox(height: 12),
              Text(
                'Enter your registered email and we\'ll send you a 6-digit code to reset your password.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),

              GBTextField(
                label: 'Email',
                hint: 'Enter your registered email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),

              Obx(() {
                if (_authCtrl.errorMessage.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _authCtrl.errorMessage.value,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              Obx(() => GBButton(
                    label: 'Send Reset Code',
                    onPressed: _submit,
                    isLoading: _authCtrl.isLoading.value,
                    isFullWidth: true,
                  )),
              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Back to Sign In',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
