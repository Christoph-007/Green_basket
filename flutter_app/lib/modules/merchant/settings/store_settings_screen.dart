import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _repo = MerchantRepository();
  bool _isLoading = true;
  bool _isSaving = false;

  final _storeNameController = TextEditingController();
  final _storeDescController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _radiusController = TextEditingController();
  final _minValueController = TextEditingController();
  final _deliveryChargeController = TextEditingController();
  final _freeAboveController = TextEditingController();
  bool _isManualOpen = true;

  final Map<String, bool> _pushSettings = {
    'order': true,
    'payment': true,
    'promotion': true,
    'system': true,
    'lowStock': true,
    'reviews': true,
  };
  final Map<String, bool> _emailSettings = {
    'order': true,
    'payment': true,
    'lowStock': true,
    'system': true,
  };

  bool _autoAccept = false;
  int _defaultPrepTime = 30;

  final List<Map<String, dynamic>> _storeHours = [
    {'day': 'Monday', 'open': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 21, minute: 0)},
    {'day': 'Tuesday', 'open': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 21, minute: 0)},
    {'day': 'Wednesday', 'open': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 21, minute: 0)},
    {'day': 'Thursday', 'open': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 21, minute: 0)},
    {'day': 'Friday', 'open': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 22, minute: 0)},
    {'day': 'Saturday', 'open': true, 'openTime': const TimeOfDay(hour: 7, minute: 0), 'closeTime': const TimeOfDay(hour: 22, minute: 0)},
    {'day': 'Sunday', 'open': false, 'openTime': const TimeOfDay(hour: 9, minute: 0), 'closeTime': const TimeOfDay(hour: 18, minute: 0)},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final result = await _repo.getStoreSettings();
      final data = result['data'] ?? result;
      setState(() {
        _storeNameController.text = data['businessName'] ?? '';
        _storeDescController.text = data['businessDescription'] ?? '';
        _storePhoneController.text = data['phone'] ?? '';
        _isManualOpen = data['isStoreOpen'] ?? true;
        
        final addr = data['address'];
        if (addr is Map) {
          _addressController.text = addr['street'] ?? '';
        } else if (addr is String) {
          _addressController.text = addr;
        }
        
        // Notifications
        final notifs = data['notificationSettings'] ?? {};
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
        
        // Backward compatibility mapping for old fields if any
        if (notifs['newOrders'] != null) _pushSettings['order'] = notifs['newOrders'];
        if (notifs['lowStock'] != null) _pushSettings['lowStock'] = notifs['lowStock'];
        if (notifs['reviews'] != null) _pushSettings['reviews'] = notifs['reviews'];
        
        // Order Settings
        _autoAccept = data['autoAcceptOrders'] ?? data['autoAccept'] ?? false;
        _defaultPrepTime = data['defaultPrepTime'] ?? 30;

        // Delivery Settings
        _radiusController.text = (data['deliveryRadius'] ?? 10).toString();
        _minValueController.text = (data['minimumOrderValue'] ?? 0).toString();
        _deliveryChargeController.text = (data['deliveryCharges'] ?? 0).toString();
        _freeAboveController.text = (data['freeDeliveryAbove'] ?? '').toString();

        // Parse operating hours (Map: { monday: { open, close, isOpen }, ... })
        final hoursRaw = data['operatingHours'] ?? data['storeHours'] ?? data['hours'];
        if (hoursRaw is Map) {
          for (int i = 0; i < _storeHours.length; i++) {
            final dayKey = _storeHours[i]['day'].toString().toLowerCase();
            final h = hoursRaw[dayKey];
            if (h != null) {
              _storeHours[i]['open'] = h['isOpen'] ?? h['open'] ?? true;
              if (h['open'] is String && (h['open'] as String).contains(':')) {
                final parts = (h['open'] as String).split(':');
                _storeHours[i]['openTime'] = TimeOfDay(
                    hour: int.tryParse(parts[0]) ?? 8,
                    minute: int.tryParse(parts[1]) ?? 0);
              }
              if (h['close'] is String && (h['close'] as String).contains(':')) {
                final parts = (h['close'] as String).split(':');
                _storeHours[i]['closeTime'] = TimeOfDay(
                    hour: int.tryParse(parts[0]) ?? 21,
                    minute: int.tryParse(parts[1]) ?? 0);
              }
            }
          }
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickTime(int index, bool isOpen) async {
    final current = isOpen
        ? _storeHours[index]['openTime'] as TimeOfDay
        : _storeHours[index]['closeTime'] as TimeOfDay;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _storeHours[index]['openTime'] = picked;
        } else {
          _storeHours[index]['closeTime'] = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _timeOfDayToString(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> operatingHours = {};
      for (var h in _storeHours) {
        final dayKey = h['day'].toString().toLowerCase();
        operatingHours[dayKey] = {
          'isOpen': h['open'],
          'open': _timeOfDayToString(h['openTime'] as TimeOfDay),
          'close': _timeOfDayToString(h['closeTime'] as TimeOfDay),
        };
      }

      await _repo.saveStoreSettings({
        'businessName': _storeNameController.text.trim(),
        'businessDescription': _storeDescController.text.trim(),
        'phone': _storePhoneController.text.trim(),
        'address': _addressController.text.trim(),
        'notificationSettings': {
          'push': _pushSettings,
          'email': _emailSettings,
        },
        'autoAcceptOrders': _autoAccept,
        'defaultPrepTime': _defaultPrepTime,
        'deliveryRadius': double.tryParse(_radiusController.text) ?? 10,
        'minimumOrderValue': double.tryParse(_minValueController.text) ?? 0,
        'deliveryCharges': double.tryParse(_deliveryChargeController.text) ?? 0,
        'freeDeliveryAbove': double.tryParse(_freeAboveController.text),
        'operatingHours': operatingHours,
        'isStoreOpen': _isManualOpen,
      });
      Get.back();
      GBSnack.success('Settings Saved', 'Store settings updated successfully', position: SnackPosition.BOTTOM);
    } catch (_) {
      GBSnack.plain('Error', 'Failed to save settings. Please try again.', position: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Store Settings', backIcon: Icons.arrow_back_ios_new, showDivider: false),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Store Status'),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: _isManualOpen ? AppColors.success : AppColors.error),
                    ),
                    child: SwitchListTile(
                      title: Text(_isManualOpen ? 'ONLINE / OPEN' : 'OFFLINE / CLOSED', 
                        style: AppTextStyles.titleMedium.copyWith(
                          color: _isManualOpen ? AppColors.success : AppColors.error,
                        ),
                      ),
                      subtitle: Text(_isManualOpen ? 'The store is following your regular operating hours.' : 'The store is manually closed for all customers.'),
                      secondary: Icon(Icons.store_outlined, color: _isManualOpen ? AppColors.success : AppColors.error),
                      value: _isManualOpen,
                      onChanged: (v) => setState(() => _isManualOpen = v),
                      activeColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionHeader('Store Information'),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _storeNameController,
                    label: 'Store Name',
                    hint: 'Your store name',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _storeDescController,
                    label: 'Store Description',
                    hint: 'Brief description of your store...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _storePhoneController,
                    label: 'Store Phone',
                    hint: '+91 XXXXX XXXXX',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Store Address',
                    hint: '123 Street, City, Pincode',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _sectionHeader('Store Hours'),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: _storeHours.asMap().entries.map((e) {
                        final i = e.key;
                        final day = e.value;
                        final isOpen = day['open'] as bool;
                        return Column(
                          children: [
                            if (i > 0) const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 90,
                                        child: Text(day['day'] as String,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w500)),
                                      ),
                                      const Spacer(),
                                      Text(
                                        isOpen ? 'Open' : 'Closed',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: isOpen
                                              ? AppColors.success
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Switch(
                                        value: isOpen,
                                        onChanged: (v) => setState(
                                            () => _storeHours[i]['open'] = v),
                                        activeColor: AppColors.primary,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                  if (isOpen) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _timePickerButton(
                                            'Opens',
                                            _formatTime(
                                                day['openTime'] as TimeOfDay),
                                            () => _pickTime(i, true),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm),
                                          child: Icon(Icons.arrow_forward,
                                              size: 16,
                                              color: AppColors.textHint),
                                        ),
                                        Expanded(
                                          child: _timePickerButton(
                                            'Closes',
                                            _formatTime(
                                                day['closeTime'] as TimeOfDay),
                                            () => _pickTime(i, false),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _sectionHeader('Delivery Settings'),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _radiusController,
                    label: 'Delivery Radius (km)',
                    hint: '10',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _minValueController,
                    label: 'Minimum Order Value (₹)',
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _deliveryChargeController,
                    label: 'Delivery Charge (₹)',
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _freeAboveController,
                    label: 'Free Delivery Above (₹)',
                    hint: 'leave empty if none',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  _sectionHeader('Notification Preferences'),
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
                          'Order Alerts',
                          'Status updates for orders',
                          Icons.shopping_bag_outlined,
                          _pushSettings['order']!,
                          (v) => setState(() => _pushSettings['order'] = v),
                        ),
                        _notifToggle(
                          'Payment Alerts',
                          'Transaction and payout alerts',
                          Icons.payments_outlined,
                          _pushSettings['payment']!,
                          (v) => setState(() => _pushSettings['payment'] = v),
                        ),
                        _notifToggle(
                          'Low Stock',
                          'Alert when products run low',
                          Icons.inventory_2_outlined,
                          _pushSettings['lowStock']!,
                          (v) => setState(() => _pushSettings['lowStock'] = v),
                        ),
                        _notifToggle(
                          'Customer Reviews',
                          'New review notifications',
                          Icons.star_outline,
                          _pushSettings['reviews']!,
                          (v) => setState(() => _pushSettings['reviews'] = v),
                        ),
                        _notifToggle(
                          'System & Promotions',
                          'Important updates and offers',
                          Icons.campaign_outlined,
                          _pushSettings['system']!,
                          (v) => setState(() => _pushSettings['system'] = v),
                        ),
                        const Divider(height: 1),
                        _settingsGroupHeader('Email Notifications'),
                        _notifToggle(
                          'Order Summary',
                          'Detailed order emails',
                          Icons.email_outlined,
                          _emailSettings['order']!,
                          (v) => setState(() => _emailSettings['order'] = v),
                        ),
                        _notifToggle(
                          'Inventory Alerts',
                          'Weekly stock reports',
                          Icons.assessment_outlined,
                          _emailSettings['lowStock']!,
                          (v) => setState(() => _emailSettings['lowStock'] = v),
                        ),
                        _notifToggle(
                          'Financial Reports',
                          'Monthly payout summaries',
                          Icons.pie_chart_outline,
                          _emailSettings['payment']!,
                          (v) => setState(() => _emailSettings['payment'] = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _sectionHeader('Order Management'),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('Auto-accept Orders',
                              style: AppTextStyles.bodyMedium),
                          subtitle: Text(
                            'Automatically confirm incoming orders',
                            style: AppTextStyles.bodySmall,
                          ),
                          secondary: const Icon(Icons.auto_awesome_outlined,
                              color: AppColors.primary),
                          value: _autoAccept,
                          onChanged: (v) => setState(() => _autoAccept = v),
                          activeColor: AppColors.primary,
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Default Prep Time',
                                        style: AppTextStyles.bodyMedium),
                                    Text('$_defaultPrepTime minutes',
                                        style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _stepperButton(Icons.remove, () {
                                    if (_defaultPrepTime > 5) {
                                      setState(() => _defaultPrepTime -= 5);
                                    }
                                  }),
                                  const SizedBox(width: AppSpacing.sm),
                                  Container(
                                    width: 44,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: AppColors.border),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Center(
                                      child: Text('$_defaultPrepTime',
                                          style: AppTextStyles.titleMedium),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _stepperButton(Icons.add,
                                      () => setState(() => _defaultPrepTime += 5)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 8, offset: Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Settings'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) =>
      Text(title, style: AppTextStyles.titleLarge);

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _timePickerButton(String label, String time, VoidCallback onTap) {
    return Semantics(button: true, child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_outlined,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primary)),
                  Text(time,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

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
      void Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      secondary: Icon(icon, color: AppColors.primary, size: 22),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return Semantics(button: true, child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    ));
  }
}
