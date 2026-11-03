class ReturnItem {
  final String productName;
  final int quantity;
  final String? condition;

  const ReturnItem({
    required this.productName,
    required this.quantity,
    this.condition,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return ReturnItem(
      productName: product is Map ? (product['name']?.toString() ?? 'Item') : 'Item',
      quantity: ((json['quantity'] as num?) ?? 1).toInt(),
      condition: json['condition']?.toString(),
    );
  }
}

/// A return request, as served by GET /api/returns/my-returns.
class ReturnModel {
  final String id;
  final String returnId;
  final String orderNumber;
  final String type;
  final String reason;
  final String status;
  final double refundAmount;
  final String? refundMethod;
  final String? rejectionReason;
  final String? adminNotes;
  final DateTime createdAt;
  final List<ReturnItem> items;

  const ReturnModel({
    required this.id,
    required this.returnId,
    required this.orderNumber,
    required this.type,
    required this.reason,
    required this.status,
    required this.refundAmount,
    required this.createdAt,
    required this.items,
    this.refundMethod,
    this.rejectionReason,
    this.adminNotes,
  });

  factory ReturnModel.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    return ReturnModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      returnId: json['returnId']?.toString() ?? '',
      orderNumber: order is Map ? (order['orderId']?.toString() ?? '') : '',
      type: json['type']?.toString() ?? 'return',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'requested',
      refundAmount: (json['refundAmount'] as num?)?.toDouble() ?? 0,
      refundMethod: json['refundMethod']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      adminNotes: json['adminNotes']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ReturnItem.fromJson)
          .toList(),
    );
  }

  /// The server marks a request the customer cancelled as "rejected".
  bool get isCancelledByCustomer =>
      status == 'rejected' && rejectionReason == 'Cancelled by user';

  bool get isRejected => status == 'rejected';

  /// Finished for the customer: refunded or rejected/cancelled.
  bool get isCompleted =>
      status == 'refunded' || status == 'processed' || status == 'rejected';

  /// Only a request nobody has looked at yet can be cancelled.
  bool get canCancel => status == 'requested';

  String get statusLabel {
    if (isCancelledByCustomer) return 'Cancelled';
    switch (status) {
      case 'requested':
        return 'Requested';
      case 'approved':
        return 'Approved';
      case 'pickup_scheduled':
        return 'Pickup Scheduled';
      case 'picked_up':
        return 'Picked Up';
      case 'processed':
      case 'refunded':
        return 'Refunded';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  /// Position on the Requested -> Approved -> Refunded progress bar.
  int get progressStep {
    switch (status) {
      case 'approved':
      case 'pickup_scheduled':
      case 'picked_up':
        return 1;
      case 'processed':
      case 'refunded':
        return 2;
      default:
        return 0;
    }
  }

  String get itemsSummary =>
      items.map((i) => '${i.productName} × ${i.quantity}').join(', ');
}
