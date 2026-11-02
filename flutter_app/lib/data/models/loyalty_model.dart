class LoyaltyModel {
  final int points;
  final String tier;
  final int totalEarned;
  final int totalRedeemed;
  final List<LoyaltyHistory> history;

  LoyaltyModel({
    this.points = 0,
    this.tier = 'bronze',
    this.totalEarned = 0,
    this.totalRedeemed = 0,
    this.history = const [],
  });

  double get nextTierProgress {
    switch (tier) {
      case 'bronze':
        return points / 500;
      case 'silver':
        return (points - 500) / 500;
      case 'gold':
        return (points - 1000) / 1500;
      case 'platinum':
        return 1.0;
      default:
        return 0;
    }
  }

  String get nextTier {
    switch (tier) {
      case 'bronze':
        return 'silver';
      case 'silver':
        return 'gold';
      case 'gold':
        return 'platinum';
      default:
        return 'platinum';
    }
  }

  int get pointsToNextTier {
    switch (tier) {
      case 'bronze':
        return 500 - points;
      case 'silver':
        return 1000 - points;
      case 'gold':
        return 2500 - points;
      default:
        return 0;
    }
  }

  factory LoyaltyModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    return LoyaltyModel(
      // Backend returns "currentPoints", fallback to legacy "points" key
      points: json['currentPoints'] ??
          json['points'] ??
          json['loyalty']?['points'] ??
          0,
      // Backend returns "currentTier", fallback to legacy "tier" key
      tier: (json['currentTier'] ??
              json['tier'] ??
              json['loyalty']?['tier'] ??
              'bronze')
          .toString()
          .toLowerCase(),
      // Backend nests these inside "summary"
      totalEarned: summary['totalEarned'] ?? json['totalEarned'] ?? 0,
      totalRedeemed:
          summary['totalRedeemed'] ?? json['totalRedeemed'] ?? 0,
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => LoyaltyHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

}

class LoyaltyHistory {
  final String id;
  final String type; // 'earned' | 'redeemed'
  final int points;
  final String description;
  final DateTime createdAt;

  LoyaltyHistory({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  factory LoyaltyHistory.fromJson(Map<String, dynamic> json) {
    return LoyaltyHistory(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? 'earned',
      points: json['points'] ?? 0,
      description: json['description'] ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
