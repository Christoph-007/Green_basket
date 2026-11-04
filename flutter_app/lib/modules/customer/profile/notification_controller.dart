import 'package:get/get.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationController extends GetxController {
  final _repo = NotificationRepository();
  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  final unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    fetchUnreadCount();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      notifications.value = await _repo.getNotifications();
    } catch (e) {
      GBSnack.plain('Error', 'Failed to load notifications');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      unreadCount.value = await _repo.getUnreadCount();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repo.markAsRead(id);
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final n = notifications[index];
        notifications[index] = NotificationModel(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
      fetchUnreadCount();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();
      notifications.value = notifications.map((n) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      unreadCount.value = 0;
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _repo.clearAll();
      notifications.clear();
      unreadCount.value = 0;
    } catch (_) {}
  }
}
