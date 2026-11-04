import 'package:get/get.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../../config/constants.dart';
import 'storage_service.dart';

/// Singleton Socket.IO service that mirrors the backend event rooms.
///
/// Backend rooms: `{userType}_{userId}` — authenticated via JWT in handshake.
///
/// Events consumed (from backend sockets):
///   • order_status_update   – OrderSocket.notifyOrderStatusUpdate
///   • order_location_update – OrderSocket.updateOrderLocation
///   • new_order             – OrderSocket.notifyNewOrder        (merchant)
///   • order_cancelled       – OrderSocket.notifyOrderCancellation
///   • order_count_update    – OrderSocket.updateMerchantOrderCount
///   • notification          – NotificationSocket.sendNotification
///   • broadcast_notification– NotificationSocket.broadcastNotification
///   • low_stock_alert       – InventorySocket.notifyLowStock    (merchant)
///   • stock_updated         – InventorySocket.updateStock        (merchant)
///   • out_of_stock          – InventorySocket.notifyOutOfStock   (merchant)
class SocketService extends GetxService {
  static SocketService get to => Get.find<SocketService>();

  sio.Socket? _socket;
  bool _disposed = false;

  // ── Observable streams for UI consumption ───────────────────────────
  final orderStatusUpdate = Rxn<Map<String, dynamic>>();
  final orderLocationUpdate = Rxn<Map<String, dynamic>>();
  final newMerchantOrder = Rxn<Map<String, dynamic>>();
  final orderPaid = Rxn<Map<String, dynamic>>();
  final orderCancelled = Rxn<Map<String, dynamic>>();
  final merchantOrderCount = Rxn<Map<String, dynamic>>();
  final notification = Rxn<Map<String, dynamic>>();
  final lowStockAlert = Rxn<Map<String, dynamic>>();
  final stockUpdated = Rxn<Map<String, dynamic>>();

  // ── Connection state ───────────────────────────────────────────────
  final isConnected = false.obs;

  // ── Connect ────────────────────────────────────────────────────────
  void connect() {
    final token = StorageService().token;
    if (token == null || token.isEmpty) return;

    // Tear down old connection
    disconnect();
    _disposed = false;

    _socket = sio.io(
      AppConstants.socketUrl,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _registerListeners();
    _socket!.connect();
  }

  void _registerListeners() {
    final s = _socket;
    if (s == null) return;

    s.onConnect((_) {
      if (!_disposed) isConnected.value = true;
      _log('connected');
    });

    s.onDisconnect((_) {
      if (!_disposed) isConnected.value = false;
      _log('disconnected');
    });

    s.onConnectError((err) {
      if (!_disposed) isConnected.value = false;
      _log('connect_error: $err');
    });

    // ── Order events ─────────────────────────────────────────────────
    s.on('order_status_update', (data) {
      if (_disposed) return;
      orderStatusUpdate.value = _toMap(data);
    });

    s.on('order_location_update', (data) {
      if (_disposed) return;
      orderLocationUpdate.value = _toMap(data);
    });

    s.on('new_order', (data) {
      if (_disposed) return;
      newMerchantOrder.value = _toMap(data);
    });

    // An online order was paid (merchant)
    s.on('order_paid', (data) {
      if (_disposed) return;
      orderPaid.value = _toMap(data);
    });

    s.on('order_cancelled', (data) {
      if (_disposed) return;
      orderCancelled.value = _toMap(data);
    });

    s.on('order_count_update', (data) {
      if (_disposed) return;
      merchantOrderCount.value = _toMap(data);
    });

    // ── Notification events ──────────────────────────────────────────
    s.on('notification', (data) {
      if (_disposed) return;
      notification.value = _toMap(data);
      _showInAppNotification(_toMap(data));
    });

    s.on('broadcast_notification', (data) {
      if (_disposed) return;
      notification.value = _toMap(data);
      _showInAppNotification(_toMap(data));
    });

    // ── Inventory events (merchant) ──────────────────────────────────
    s.on('low_stock_alert', (data) {
      if (_disposed) return;
      lowStockAlert.value = _toMap(data);
    });

    s.on('stock_updated', (data) {
      if (_disposed) return;
      stockUpdated.value = _toMap(data);
    });

    s.on('out_of_stock', (data) {
      if (_disposed) return;
      lowStockAlert.value = _toMap(data); // reuse for both alerts
    });
  }

  // ── Emit helpers ───────────────────────────────────────────────────
  void emit(String event, [dynamic data]) {
    if (_socket?.connected == true) {
      _socket!.emit(event, data);
    }
  }

  /// Acknowledge a notification was read
  void markNotificationRead(String notificationId) {
    emit('notification_read', notificationId);
  }

  // ── Disconnect ─────────────────────────────────────────────────────
  void disconnect() {
    _disposed = true;
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  // ── Helpers ────────────────────────────────────────────────────────
  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }

  void _showInAppNotification(Map<String, dynamic> payload) {
    final title = payload['title']?.toString() ?? 'Notification';
    final message = payload['message']?.toString() ?? '';
    GBSnack.plain(title, message, position: SnackPosition.TOP, duration: const Duration(seconds: 4));
  }

  void _log(String msg) {
    // ignore: avoid_print
    print('[SocketService] $msg');
  }
}
