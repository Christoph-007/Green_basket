import 'order_model.dart';

class CartModel {
  final String id;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? couponCode;
  final double couponDiscount;

  CartModel({
    required this.id,
    required this.items,
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.discount = 0,
    this.total = 0,
    this.couponCode,
    this.couponDiscount = 0,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => CartItemModel.fromJson(e))
        .toList();
    final subtotal = items.fold<double>(0, (s, i) => s + i.itemTotal);
    return CartModel(
      id: json['_id'] ?? json['id'] ?? '',
      items: items,
      subtotal: (json['subtotal'] ?? subtotal).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      discount: ((json['discount'] ?? 0) as num).toDouble(),
      total: (json['total'] ?? subtotal).toDouble(),
      // Backend cart: appliedCoupon { code, discount }, discount
      couponCode: json['couponCode'] ?? (json['appliedCoupon'] is Map ? json['appliedCoupon']['code'] : null),
      couponDiscount: ((json['couponDiscount'] ?? json['discount'] ?? 0) as num).toDouble(),
    );
  }

  factory CartModel.empty() => CartModel(id: '', items: []);
}
