import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../config/theme.dart';
import '../../../utils/validators.dart';
import '../../../widgets/common/gb_button.dart';
import '../../../widgets/common/gb_text_field.dart';
import '../auth_controller.dart';

/// Second step of "forgot password": enter the 6-digit OTP that was emailed
/// and choose a new password. Works for customers and merchants.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _authCtrl = Get.find<AuthController>();
  late String _email;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _email = (args['email'] ?? '') as String;
    _authCtrl.errorMessage.value = '';
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_otpCtrl.text.length != 6) {
      Get.snackbar('Invalid OTP', 'Please enter the complete 6-digit OTP',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _authCtrl.resetPassword(
      email: _email,
      otp: _otpCtrl.text,
      newPassword: _passwordCtrl.text,
    );
  }

  void _resend() => _authCtrl.forgotPassword(_email, openResetScreen: false);

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: AppTextStyles.headlineLarge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.lock_reset_outlined,
                    size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text('Reset Password', style: AppTextStyles.displayMedium),
              const SizedBox(height: 12),
              Text(
                'Enter the 6-digit code sent to',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style:
                    AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              Pinput(
                controller: _otpCtrl,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GBTextField(
                label: 'New Password',
                hint: 'Enter a new password',
                controller: _passwordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: Validators.password,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              GBTextField(
                label: 'Confirm Password',
                hint: 'Re-enter the new password',
                controller: _confirmCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) =>
                    Validators.confirmPassword(v, _passwordCtrl.text),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (_authCtrl.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _authCtrl.errorMessage.value,
                    style:
                        AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                );
              }),
              const SizedBox(height: 16),
              Obx(() => GBButton(
                    label: 'Reset Password',
                    onPressed: _submit,
                    isLoading: _authCtrl.isLoading.value,
                    isFullWidth: true,
                  )),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resend,
                child: Text(
                  'Resend code',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
