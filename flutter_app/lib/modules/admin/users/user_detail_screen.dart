import 'package:dio/dio.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../admin_controller.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const UserDetailScreen({super.key, this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final controller = Get.find<AdminController>();
  late Map<String, dynamic> _user;
  late bool _isBlocked;

  @override
  void initState() {
    super.initState();
    _user = widget.user ?? Get.arguments?['user'] ?? {};
    _isBlocked = _user['isBlocked'] ?? false;
  }

  final List<dynamic> _recentOrders = _extractOrders();

  static List<dynamic> _extractOrders() {
    final args = Get.arguments;
    if (args is Map && args['recentOrders'] is List) {
      return args['recentOrders'] as List<dynamic>;
    }
    return [];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.error;
      case 'Pending':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _errorMessage(Object error, String fallback) {
    if (error is DioException) {
      final body = error.response?.data;
      final message = body is Map ? (body['message'] ?? body['error']) : null;
      if (message != null) return message.toString();
    }
    return fallback;
  }

  Future<void> _sendPasswordReset() async {
    final email = _user['email']?.toString() ?? '';
    if (email.isEmpty) {
      GBSnack.warning('No email', 'This user has no email address on file.');
      return;
    }
    try {
      await AuthRepository().forgotPassword(email);
      GBSnack.info('Reset code sent', 'A password reset code was emailed to $email.');
    } catch (e) {
      GBSnack.error('Could not send', _errorMessage(e, 'Please try again.'));
    }
  }

  Future<void> _showSendNotificationDialog() async {
    final userId = (_user['_id'] ?? _user['id'] ?? '').toString();
    if (userId.isEmpty) {
      GBSnack.error('Error', 'This user has no id, so a notification cannot be sent.');
      return;
    }
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notify ${_user['name'] ?? 'user'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (send != true) return;
    try {
      await AdminRepository().sendNotification({
        'userIds': [userId],
        'title': titleCtrl.text.trim(),
        'message': messageCtrl.text.trim(),
        'channels': ['inApp', 'push'],
      });
      GBSnack.success('Notification sent', 'Sent to ${_user['name'] ?? 'the user'}.');
    } catch (e) {
      GBSnack.error('Could not send', _errorMessage(e, 'Please try again.'));
    }
  }

  void _showBlockConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(
          _isBlocked ? 'Unblock User?' : 'Block User?',
          style: AppTextStyles.titleLarge,
        ),
        content: Text(
          _isBlocked
              ? 'Are you sure you want to unblock ${_user['name']}? They will regain access to the platform.'
              : 'Are you sure you want to block ${_user['name']}? They will lose access to the platform.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          GBButton(label: _isBlocked ? 'Unblock' : 'Block', onPressed: () async {
              try {
                await controller.toggleUserBlock(_user['_id']);
                setState(() => _isBlocked = !_isBlocked);
                if (ctx.mounted) Navigator.pop(ctx);
                final blockedTitle = _isBlocked ? 'User Blocked' : 'User Unblocked';
                final blockedText = '${_user['name']} has been ${_isBlocked ? 'blocked' : 'unblocked'}.';
                if (_isBlocked) {
                  GBSnack.error(blockedTitle, blockedText);
                } else {
                  GBSnack.success(blockedTitle, blockedText);
                }
              } catch (e) {
                GBSnack.plain('Error', 'Failed to update user status');
              }
            }, backgroundColor: _isBlocked ? AppColors.success : AppColors.error),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'User Details', actions: [
          TextButton(
            onPressed: _showBlockConfirmDialog,
            child: Text(
              _isBlocked ? 'Unblock' : 'Block',
              style: TextStyle(
                color: _isBlocked ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ], leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        )),
      body: _user.isEmpty
          ? const Center(child: Text('User details not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: AppSpacing.md),
                  _buildStatsRow(),
                  const SizedBox(height: AppSpacing.md),
                  _buildRecentOrders(),
                  const SizedBox(height: AppSpacing.md),
                  _buildActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    (_user['name']?.toString() ?? 'U')
                        .substring(
                          0,
                          _user['name']?.toString().length == 1 ? 1 : 2,
                        )
                        .toUpperCase(),
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_user['name']!, style: AppTextStyles.titleLarge),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              _user['role']?.toString() ?? 'User',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_isBlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            'BLOCKED',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            _infoRow(
              Icons.email_outlined,
              _user['email']?.toString() ?? 'No email',
            ),
            const SizedBox(height: AppSpacing.sm),
            _infoRow(
              Icons.phone_outlined,
              _user['phone']?.toString() ?? 'No phone',
            ),
            const SizedBox(height: AppSpacing.sm),
            _infoRow(
              Icons.calendar_today_outlined,
              'Joined ${_user['createdAt']?.toString().split('T')[0] ?? 'N/A'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statItem(
          'Orders',
          _user['orderCount']?.toString() ?? '0',
          Icons.shopping_basket_outlined,
          Colors.blue,
        ),
        _statItem(
          'Spent',
          AppHelpers.formatCurrencyFlexible(_user['totalSpent']),
          Icons.currency_rupee,
          AppColors.primary,
        ),
        _statItem(
          'Points',
          _user['loyaltyPoints']?.toString() ?? '0',
          Icons.stars_outlined,
          AppColors.secondary,
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: 6,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.titleMedium.copyWith(color: color),
              ),
              Text(
                label,
                style: AppTextStyles.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Orders', style: AppTextStyles.titleLarge),
            if (_recentOrders.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'No recent orders found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ..._recentOrders.map(
                (order) => Column(
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${order['id']}',
                                  style: AppTextStyles.labelLarge,
                                ),
                                Text(
                                  order['date']!,
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            order['amount']!,
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                order['status']!,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              order['status']!,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _statusColor(order['status']!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Actions', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _actionButton(
              icon: Icons.block,
              label: _isBlocked ? 'Unblock Account' : 'Block Account',
              color: _isBlocked ? AppColors.success : AppColors.error,
              onTap: _showBlockConfirmDialog,
            ),
            const SizedBox(height: AppSpacing.sm),
            _actionButton(
              icon: Icons.lock_reset,
              label: 'Reset Password',
              color: AppColors.info,
              onTap: _sendPasswordReset,
            ),
            const SizedBox(height: AppSpacing.sm),
            _actionButton(
              icon: Icons.notifications_outlined,
              label: 'Send Notification',
              color: AppColors.primary,
              onTap: _showSendNotificationDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.labelLarge.copyWith(color: color)),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6), size: 18),
          ],
        ),
      ),
    );
  }
}
