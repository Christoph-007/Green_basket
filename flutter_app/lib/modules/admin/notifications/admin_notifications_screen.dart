import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:greenbasket_app/config/routes.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _repo = AdminRepository();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isSending = false;
  bool _isLoading = false;

  String _selectedAudience = 'Customers Only';
  final _audiences = ['Customers Only', 'Merchants Only'];

  final List<String> _selectedTypes = ['Push'];
  final _notifTypes = ['Push', 'Email', 'SMS'];

  List<dynamic> _recentNotifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final result = await _repo.getSentNotifications(limit: 5);
      setState(() {
        _recentNotifications = result['notifications'] as List<dynamic>;
      });
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        if (_selectedTypes.length > 1) _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  void _sendNow() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      GBSnack.warning('Required Fields', 'Please fill in the notification title and body.');
      return;
    }
    setState(() => _isSending = true);
    try {
      await _repo.sendNotification({
        'title': _titleController.text,
        'body': _bodyController.text,
        'audience': _selectedAudience,
        'types': _selectedTypes,
        if (_imageUrlController.text.isNotEmpty) 'imageUrl': _imageUrlController.text,
      });
      GBSnack.success('Notification Sent', '"${_titleController.text}" sent to $_selectedAudience via ${_selectedTypes.join(', ')}.');
      _titleController.clear();
      _bodyController.clear();
      _imageUrlController.clear();
      _fetchNotifications(); // Refresh list
    } catch (e) {
      GBSnack.error('Error', 'Failed to send notification');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scheduleNotification() {
    if (_titleController.text.isEmpty) {
      GBSnack.warning('Required', 'Please fill in the notification title.');
      return;
    }
    // Scheduling is not implemented on the backend yet; be clear that nothing was scheduled.
    GBSnack.info('Not available yet', 'Scheduling is coming soon. Nothing was scheduled; use "Send now" to send it immediately.');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Send Notifications', leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        )),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAudienceSelector(),
            const SizedBox(height: AppSpacing.md),
            _buildTypeSelector(),
            const SizedBox(height: AppSpacing.md),
            _buildContentSection(),
            const SizedBox(height: AppSpacing.md),
            _buildPreviewCard(),
            const SizedBox(height: AppSpacing.md),
            _buildActionButtons(),
            const SizedBox(height: AppSpacing.lg),
            _buildRecentNotifications(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target Audience', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _audiences.map((audience) {
                final isSelected = _selectedAudience == audience;
                return ChoiceChip(
                  label: Text(audience),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedAudience = audience),
                  selectedColor: AppColors.primary,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  avatar: isSelected
                      ? const Icon(Icons.people, color: Colors.white, size: 14)
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification Type', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: _notifTypes.map((type) {
                final isSelected = _selectedTypes.contains(type);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (_) => _toggleType(type),
                      selectedColor: AppColors.primary,
                      labelStyle: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      checkmarkColor: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification Content', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Weekend Sale is Live!',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Body Message',
                hintText: 'Shop now and get up to 20% off on all orders...',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (Optional)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final hasContent = _titleController.text.isNotEmpty || _bodyController.text.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text('Preview', style: AppTextStyles.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: hasContent
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(Icons.eco, color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('GreenBasket', style: AppTextStyles.labelLarge),
                                  Text('now', style: AppTextStyles.labelSmall),
                                ],
                              ),
                              if (_titleController.text.isNotEmpty)
                                Text(_titleController.text, style: AppTextStyles.bodyMedium),
                              if (_bodyController.text.isNotEmpty)
                                Text(
                                  _bodyController.text,
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Text(
                        'Fill in title and body to see preview',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GBButton(label: 'Schedule', onPressed: _scheduleNotification, leadingIcon: Icons.schedule, variant: GBButtonVariant.outline),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSending ? null : _sendNow,
            icon: _isSending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: Text(_isSending ? 'Sending...' : 'Send Now'),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Notifications', style: AppTextStyles.titleLarge),
            if (_recentNotifications.isNotEmpty)
              TextButton(
                onPressed: () => Get.toNamed(Routes.adminAllNotifications),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_isLoading && _recentNotifications.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (_recentNotifications.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('No notifications sent recently', style: AppTextStyles.bodyMedium),
            ),
          )
        else
          ..._recentNotifications.map((notif) {
            final sentAt = DateTime.tryParse(notif['createdAt'] ?? '') ?? DateTime.now();
            final audience = notif['userModel'] == 'User'
                ? 'Customers'
                : notif['userModel'] == 'Merchant'
                    ? 'Merchants'
                    : 'Unknown';

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(notif['title'] ?? 'No Title', style: AppTextStyles.labelLarge),
                        ),
                        Text(AppHelpers.formatDateTime(sentAt), style: AppTextStyles.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['message'] ?? notif['body'] ?? 'No Message',
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            audience,
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                          ),
                        ),
                        const Spacer(),
                        if (notif['type'] != null) ...[
                          Icon(Icons.label_outline, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            (notif['type'] as String),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
