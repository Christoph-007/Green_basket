import '../providers/api_provider.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final _api = ApiProvider();

  // GET /api/notifications
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get('/notifications', params: {
      'page': page,
      'limit': limit,
    });
    final list = res.data['data']?['notifications'] ?? res.data['notifications'] ?? [];
    return (list as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  // GET /api/notifications/unread-count
  Future<int> getUnreadCount() async {
    final res = await _api.get('/notifications/unread-count');
    return res.data['data']?['count'] ?? res.data['count'] ?? 0;
  }

  // PATCH /api/notifications/:id/read
  Future<void> markAsRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  // PATCH /api/notifications/read-all
  Future<void> markAllAsRead() async {
    await _api.patch('/notifications/read-all');
  }

  // DELETE /api/notifications/:id
  Future<void> deleteNotification(String id) async {
    await _api.delete('/notifications/$id');
  }

  // DELETE /api/notifications/clear-all
  Future<void> clearAll() async {
    await _api.delete('/notifications/clear-all');
  }
}
