class WalletModel {
  final double balance;
  final bool isLocked;
  final List<WalletTransaction> transactions;

  WalletModel({
    this.balance = 0,
    this.isLocked = false,
    this.transactions = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['balance'] ?? json['wallet']?['balance'] ?? 0).toDouble(),
      isLocked: json['isLocked'] ?? json['wallet']?['isLocked'] ?? false,
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((e) => WalletTransaction.fromJson(e))
          .toList(),
    );
  }
}

class WalletTransaction {
  final String id;
  final String type; // 'credit' | 'debit'
  final double amount;
  final String description;
  final String? orderId;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.orderId,
    required this.createdAt,
  });

  bool get isCredit => type == 'credit';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? 'debit',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      orderId: json['orderId'],
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
