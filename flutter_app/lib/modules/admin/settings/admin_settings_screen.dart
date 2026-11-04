import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/providers/api_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _api = ApiProvider();
  // General
  final _appNameController = TextEditingController(text: 'GreenBasket');
  final _supportEmailController = TextEditingController(
    text: 'support@greenbasket.in',
  );
  final _supportPhoneController = TextEditingController(
    text: '+91 1800 123 4567',
  );

  // Payment
  bool _codEnabled = true;
  bool _upiEnabled = true;
  final _minOrderController = TextEditingController(text: '100');

  // Notifications
  bool _fcmEnabled = true;
  bool _emailNotifEnabled = true;

  // Security
  final _sessionTimeoutController = TextEditingController(text: '30');
  bool _twoFaEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  void _fetchSettings() async {
    try {
      final response = await _api.get('/admin/settings');
      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'] ?? {};
        setState(() {
          // General
          final gen = data['general'] ?? {};
          if (gen['appName'] != null) _appNameController.text = gen['appName'];
          if (gen['supportEmail'] != null) {
            _supportEmailController.text = gen['supportEmail'];
          }
          if (gen['supportPhone'] != null) {
            _supportPhoneController.text = gen['supportPhone'];
          }

          // Payment
          final pay = data['payment'] ?? {};
          _codEnabled = pay['codEnabled'] ?? true;
          _upiEnabled = pay['upiEnabled'] ?? true;
          if (pay['minOrderAmount'] != null) {
            _minOrderController.text = pay['minOrderAmount'].toString();
          }

          // Notifications
          final notif = data['notifications'] ?? {};
          _fcmEnabled = notif['fcmEnabled'] ?? true;
          _emailNotifEnabled = notif['emailNotifEnabled'] ?? true;

          // Security
          final sec = data['security'] ?? {};
          if (sec['sessionTimeout'] != null) {
            _sessionTimeoutController.text = sec['sessionTimeout'].toString();
          }
          _twoFaEnabled = sec['twoFaEnabled'] ?? false;
        });
      }
    } catch (e) {
      GBSnack.error('Error', 'Failed to load settings');
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _minOrderController.dispose();
    _sessionTimeoutController.dispose();
    super.dispose();
  }

  void _saveSection(String section) async {
    try {
      final Map<String, dynamic> data = {};
      switch (section) {
        case 'General':
          data['appName'] = _appNameController.text;
          data['supportEmail'] = _supportEmailController.text;
          data['supportPhone'] = _supportPhoneController.text;
          break;
        case 'Payment':
          data['codEnabled'] = _codEnabled;
          data['upiEnabled'] = _upiEnabled;
          data['minOrderAmount'] =
              int.tryParse(_minOrderController.text) ?? 100;
          break;
        case 'Notifications':
          data['fcmEnabled'] = _fcmEnabled;
          data['emailNotifEnabled'] = _emailNotifEnabled;
          break;
        case 'Security':
          data['sessionTimeout'] =
              int.tryParse(_sessionTimeoutController.text) ?? 30;
          data['twoFaEnabled'] = _twoFaEnabled;
          break;
      }
      await _api.put(
        '/admin/settings',
        data: {'section': section.toLowerCase(), ...data},
      );
      GBSnack.success('Saved', '$section settings have been updated.');
    } catch (e) {
      GBSnack.error('Error', 'Failed to save $section settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Platform Settings', leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        )),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _buildGeneralSection(),
            const SizedBox(height: AppSpacing.md),
            _buildPaymentSection(),
            const SizedBox(height: AppSpacing.md),
            _buildNotificationsSection(),
            const SizedBox(height: AppSpacing.md),
            _buildSecuritySection(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.titleLarge),
      ],
    );
  }

  Widget _buildSaveButton(String section) {
    return Align(
      alignment: Alignment.centerRight,
      child: GBButton(label: 'Save $section', onPressed: () => _saveSection(section)),
    );
  }

  Widget _buildGeneralSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General', Icons.settings_outlined),
            const Divider(height: AppSpacing.lg),
            _textField(_appNameController, 'App Name', Icons.apps),
            const SizedBox(height: AppSpacing.md),
            _textField(
              _supportEmailController,
              'Support Email',
              Icons.email_outlined,
              inputType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            _textField(
              _supportPhoneController,
              'Support Phone',
              Icons.phone_outlined,
              inputType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSaveButton('General'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Payment', Icons.payment_outlined),
            const Divider(height: AppSpacing.lg),
            _toggleRow(
              'Cash on Delivery (COD)',
              _codEnabled,
              (v) => setState(() => _codEnabled = v),
            ),
            const Divider(),
            _toggleRow(
              'UPI Payments',
              _upiEnabled,
              (v) => setState(() => _upiEnabled = v),
            ),
            const Divider(height: AppSpacing.lg),
            _textField(
              _minOrderController,
              'Minimum Order Amount (₹)',
              Icons.currency_rupee,
              inputType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSaveButton('Payment'),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Notifications', Icons.notifications_outlined),
            const Divider(height: AppSpacing.lg),
            _toggleRow(
              'FCM Push Notifications',
              _fcmEnabled,
              (v) => setState(() => _fcmEnabled = v),
            ),
            const Divider(),
            _toggleRow(
              'Email Notifications',
              _emailNotifEnabled,
              (v) => setState(() => _emailNotifEnabled = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSaveButton('Notifications'),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Security', Icons.security_outlined),
            const Divider(height: AppSpacing.lg),
            _textField(
              _sessionTimeoutController,
              'Session Timeout (minutes)',
              Icons.timer_outlined,
              inputType: TextInputType.number,
            ),
            const Divider(height: AppSpacing.lg),
            _toggleRow(
              'Two-Factor Authentication (2FA)',
              _twoFaEnabled,
              (v) => setState(() => _twoFaEnabled = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSaveButton('Security'),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
