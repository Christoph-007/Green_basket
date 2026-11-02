import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../widgets/common/gb_button.dart';
import '../auth_controller.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  final _authCtrl = Get.find<AuthController>();
  late String _email;
  int _secondsLeft = AppConstants.otpResendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _email = args['email'] ?? '';
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = AppConstants.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    if (_otpCtrl.text.length == 6) {
      _authCtrl.verifyOtp(email: _email, otp: _otpCtrl.text);
    } else {
      Get.snackbar('Invalid OTP', 'Please enter the complete 6-digit OTP',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _resend() {
    _authCtrl.resendOtp(_email);
    _startTimer();
  }

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
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
              child: const Icon(Icons.mark_email_read_outlined,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text('Verify Email', style: AppTextStyles.displayMedium),
            const SizedBox(height: 12),
            Text(
              'We\'ve sent a 6-digit code to',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _email,
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 40),

            Pinput(
              controller: _otpCtrl,
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
              ),
              submittedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  color: AppColors.primaryContainer,
                  border: Border.all(color: AppColors.primary),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: AppColors.error),
                ),
              ),
              onCompleted: (_) => _verify(),
            ),
            const SizedBox(height: 16),

            // Error message
            Obx(() {
              if (_authCtrl.errorMessage.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _authCtrl.errorMessage.value,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              );
            }),

            const SizedBox(height: 32),

            Obx(() => GBButton(
                  label: 'Verify',
                  onPressed: _verify,
                  isLoading: _authCtrl.isLoading.value,
                  isFullWidth: true,
                )),
            const SizedBox(height: 24),

            // Resend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive code? ",
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                _secondsLeft > 0
                    ? Text(
                        'Resend in ${_secondsLeft}s',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textHint),
                      )
                    : GestureDetector(
                        onTap: _resend,
                        child: Text(
                          'Resend OTP',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
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
}
