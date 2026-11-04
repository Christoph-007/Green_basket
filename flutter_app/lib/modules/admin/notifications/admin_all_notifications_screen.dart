import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import 'package:greenbasket_app/utils/helpers.dart';

class AdminAllNotificationsScreen extends StatefulWidget {
  const AdminAllNotificationsScreen({super.key});

  @override
  State<AdminAllNotificationsScreen> createState() => _AdminAllNotificationsScreenState();
}

class _AdminAllNotificationsScreenState extends State<AdminAllNotificationsScreen> {
  final _repo = AdminRepository();
  final ScrollController _scrollController = ScrollController();
  
  final List<dynamic> _notifications = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasMore = true;
  int? _total;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 && !_isLoading && _hasMore) {
        _fetchNotifications();
      }
    });
  }

  Future<void> _fetchNotifications() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await _repo.getSentNotifications(page: _page, limit: 20);
      final notifs = result['notifications'] as List<dynamic>;
      setState(() {
        _total = result['total'] as int;
        if (notifs.isEmpty) {
          _hasMore = false;
        } else {
          _notifications.addAll(notifs);
          _page++;
          if (notifs.length < 20) _hasMore = false;
        }
      });
    } catch (e) {
      GBSnack.error('Error', 'Failed to fetch notifications');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Sent Notifications'),
            if (_total != null)
              Text('Total: $_total', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: _notifications.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
                      SizedBox(height: AppSpacing.md),
                      Text('No notifications sent yet', style: AppTextStyles.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _notifications.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _notifications.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final notif = _notifications[index];
                    return _buildNotificationCard(notif);
                  },
                ),
    );
  }

  Widget _buildNotificationCard(dynamic notif) {
    final sentAt = DateTime.tryParse(notif['createdAt'] ?? '') ?? DateTime.now();
    final audience = notif['userModel'] == 'User'
        ? 'Customers'
        : notif['userModel'] == 'Merchant'
            ? 'Merchants'
            : notif['userModel'] == 'Driver'
                ? 'Agents'
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
                Icon(Icons.notifications_active_outlined, color: AppColors.primaryText, size: 16),
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
            ),
            if (notif['imageUrl'] != null && (notif['imageUrl'] as String).isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  notif['imageUrl'],
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ],
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
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryText),
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
  }
}
