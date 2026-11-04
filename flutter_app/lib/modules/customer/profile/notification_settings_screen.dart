import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../data/repositories/auth_repository.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _authRepo = AuthRepository();
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, bool> _pushSettings = {
    'order': true,
    'payment': true,
    'promotion': true,
    'system': true,
  };
  final Map<String, bool> _emailSettings = {
    'order': true,
    'payment': true,
    'otp': true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = await _authRepo.getProfile();
      final notifs = user.notificationSettings;
      
      setState(() {
        if (notifs['push'] is Map) {
          (notifs['push'] as Map).forEach((k, v) {
            if (_pushSettings.containsKey(k)) _pushSettings[k] = v ?? true;
          });
        }
        if (notifs['email'] is Map) {
          (notifs['email'] as Map).forEach((k, v) {
            if (_emailSettings.containsKey(k)) _emailSettings[k] = v ?? true;
          });
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _authRepo.updateProfile({
        'notificationSettings': {
          'push': _pushSettings,
          'email': _emailSettings,
        }
      });
      Get.back();
      GBSnack.success('Success', 'Notification preferences updated', position: SnackPosition.BOTTOM);
    } catch (e) {
      GBSnack.plain('Error', 'Failed to save settings', position: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Notification Channels'),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _settingsGroupHeader('Push Notifications'),
                        _notifToggle(
                          'Order Updates',
                          'Real-time status of your orders',
                          Icons.shopping_bag_outlined,
                          _pushSettings['order']!,
                          (v) => setState(() => _pushSettings['order'] = v),
                        ),
                        _notifToggle(
                          'Payments & Wallet',
                          'Cashback and refund alerts',
                          Icons.account_balance_wallet_outlined,
                          _pushSettings['payment']!,
                          (v) => setState(() => _pushSettings['payment'] = v),
                        ),
                        _notifToggle(
                          'Offers & Promotions',
                          'Discounts and seasonal deals',
                          Icons.local_offer_outlined,
                          _pushSettings['promotion']!,
                          (v) => setState(() => _pushSettings['promotion'] = v),
                        ),
                        _notifToggle(
                          'System & Support',
                          'Important account notices',
                          Icons.info_outline,
                          _pushSettings['system']!,
                          (v) => setState(() => _pushSettings['system'] = v),
                        ),
                        const Divider(height: 1),
                        _settingsGroupHeader('Email Notifications'),
                        _notifToggle(
                          'Order Invoices',
                          'Sent after every successful order',
                          Icons.receipt_long_outlined,
                          _emailSettings['order']!,
                          (v) => setState(() => _emailSettings['order'] = v),
                        ),
                        _notifToggle(
                          'Payment Receipts',
                          'Wallet and top-up confirmations',
                          Icons.payments_outlined,
                          _emailSettings['payment']!,
                          (v) => setState(() => _emailSettings['payment'] = v),
                        ),
                        _notifToggle(
                          'Security Alerts (OTP)',
                          'Mandatory emails for your security',
                          Icons.security_outlined,
                          true, // Mandatory
                          null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Save Preferences'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) =>
      Text(title, style: AppTextStyles.titleLarge);

  Widget _settingsGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _notifToggle(String title, String subtitle, IconData icon, bool value,
      void Function(bool)? onChanged) {
    return SwitchListTile(
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      secondary: Icon(icon, color: AppColors.primary, size: 22),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}
