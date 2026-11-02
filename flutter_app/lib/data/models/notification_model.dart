class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      type: json['type'] ?? 'general',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['read'] ??
          (json['channels']?['inApp']?['read'] ?? false),
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
