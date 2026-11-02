class OfferModel {
  final String id;
  final String title;
  final String? description;
  final String discountType; // 'percentage' | 'flat'
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscount;
  final String? couponCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? productId;
  final String? categoryId;
  final String? image;
  final int? usageLimit;
  final int usedCount;

  OfferModel({
    required this.id,
    required this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscount,
    this.couponCode,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.productId,
    this.categoryId,
    this.image,
    this.usageLimit,
    this.usedCount = 0,
  });

  bool get isPercentage => discountType == 'percentage';
  bool get isExpired =>
      endDate != null && endDate!.isBefore(DateTime.now());

  String get discountLabel => isPercentage
      ? '${discountValue.toInt()}% OFF'
      : '₹${discountValue.toStringAsFixed(0)} OFF';

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minOrderAmount: json['minOrderAmount']?.toDouble(),
      maxDiscount: json['maxDiscount']?.toDouble(),
      couponCode: json['couponCode'],
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
      isActive: json['isActive'] ?? true,
      productId: json['product']?['_id'] ?? json['productId'],
      categoryId: json['category']?['_id'] ?? json['categoryId'],
      image: json['image'],
      usageLimit: json['usageLimit'],
      usedCount: json['usedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrderAmount': minOrderAmount,
        'maxDiscount': maxDiscount,
        'couponCode': couponCode,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': isActive,
        'productId': productId,
        'categoryId': categoryId,
      };
}
