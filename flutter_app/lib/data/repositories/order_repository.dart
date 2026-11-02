import '../providers/api_provider.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';

class OrderRepository {
  final _api = ApiProvider();

  // Cart
  Future<List<CartItemModel>> getCart() async {
    final response = await _api.get('/cart');
    final data = response.data as Map<String, dynamic>;
    final items = data['data']?['cart']?['items'] as List<dynamic>? ?? [];
    return items.map((e) => CartItemModel.fromJson(e)).toList();
  }

  /// Full cart, including the coupon the server currently applies.
  Future<CartModel> getCartModel() async {
    final response = await _api.get('/cart');
    final data = response.data as Map<String, dynamic>;
    final cart = data['data']?['cart'];
    return cart is Map<String, dynamic> ? CartModel.fromJson(cart) : CartModel.empty();
  }

  Future<void> addToCart({
    required String productId,
    required int quantity,
    String? preparationOption,
  }) async {
    await _api.post('/cart/add', data: {
      'productId': productId,
      'quantity': quantity,
      if (preparationOption != null) 'preparation': preparationOption,
    });
  }

  // The backend identifies a cart line by product AND preparation
  // (e.g. "chopped" and "whole" tomatoes are separate lines).
  Future<void> updateCartItem({
    required String productId,
    required int quantity,
    String? preparation,
  }) async {
    await _api.put('/cart/update/$productId', data: {
      'quantity': quantity,
      if (preparation != null) 'preparation': preparation,
    });
  }

  Future<void> removeFromCart(String productId, {String? preparation}) async {
    final query = preparation != null
        ? '?preparation=${Uri.encodeQueryComponent(preparation)}'
        : '';
    await _api.delete('/cart/remove/$productId$query');
  }

  Future<void> clearCart() async {
    await _api.delete('/cart/clear');
  }

  Future<Map<String, dynamic>> applyCoupon(String code) async {
    final response = await _api.post('/cart/coupon', data: {'code': code});
    return response.data as Map<String, dynamic>;
  }

  Future<void> removeCoupon() async {
    await _api.delete('/cart/coupon');
  }


  // Orders
  Future<List<OrderModel>> getOrders({
    String? status,
    int page = 1,
  }) async {
    final response = await _api.get('/orders/my-orders', params: {
      if (status != null) 'status': status,
      'page': page,
    });
    final data = response.data as Map<String, dynamic>;
    final responseData = data['data'] ?? {};
    
    List<dynamic> items = [];
    if (responseData is List) {
      items = responseData;
    } else if (responseData is Map && responseData.containsKey('orders')) {
      items = responseData['orders'] as List<dynamic>? ?? [];
    }
    
    return items.map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<OrderModel> getOrder(String id) async {
    final response = await _api.get('/orders/$id');
    final data = response.data as Map<String, dynamic>;
    return OrderModel.fromJson(data['data']);
  }

  /// POST /api/orders/quote — the exact totals the order will be charged
  /// (items incl. preparation, delivery for the address, coupon). No writes.
  /// Throws DioException (400) with { message, code } when the order isn't
  /// possible, e.g. OUT_OF_DELIVERY_AREA or ADDRESS_REQUIRED.
  Future<Map<String, dynamic>> quoteOrder({
    String? addressId,
    required String deliveryType,
    String? couponCode,
  }) async {
    final response = await _api.post('/orders/quote', data: {
      if (addressId != null) 'addressId': addressId,
      'deliveryType': deliveryType,
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
    });
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<Map<String, dynamic>> checkout({
    String? addressId,
    required String paymentMethod,
    required String deliveryType,
    String? couponCode,
  }) async {
    final response = await _api.post('/orders', data: {
      if (addressId != null) 'addressId': addressId,
      'paymentMethod': paymentMethod,
      'deliveryType': deliveryType,
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
    });
    return response.data as Map<String, dynamic>;
  }


  // Returns { success, message (incl. refund info), data: { order, refund } }
  Future<Map<String, dynamic>> cancelOrder(String orderId, String reason) async {
    final res = await _api.patch('/orders/$orderId/cancel', data: {'reason': reason});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getOrderTracking(String orderId) async {
    final response = await _api.get('/orders/$orderId/tracking');
    return response.data as Map<String, dynamic>;
  }

  Future<void> submitReview(String orderId, {required int rating, String? review}) async {
    await _api.post('/orders/$orderId/review', data: {
      'rating': rating,
      if (review != null && review.isNotEmpty) 'review': review,
    });
  }

  // Addresses
  Future<List<AddressModel>> getAddresses() async {
    final response = await _api.get('/users/addresses');
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];
    return items.map((e) => AddressModel.fromJson(e)).toList();
  }

  Future<AddressModel> addAddress(AddressModel address) async {
    final response =
        await _api.post('/users/addresses', data: address.toJson());
    final data = response.data as Map<String, dynamic>;
    return AddressModel.fromJson(data['data']);
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete('/users/addresses/$id');
  }

  // Disputes
  Future<List<Map<String, dynamic>>> getMyDisputes() async {
    final response = await _api.get('/disputes/my-disputes');
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] ?? {};
    final items = (inner is Map ? inner['disputes'] : inner) as List<dynamic>? ?? [];
    return List<Map<String, dynamic>>.from(items);
  }

  Future<Map<String, dynamic>> raiseDispute({
    required String orderId,
    required String reason,
    required String description,
    String? productId,
  }) async {
    final response = await _api.post('/disputes', data: {
      'orderId': orderId,
      'reason': reason,
      'description': description,
      if (productId != null) 'productId': productId,
    });
    return response.data as Map<String, dynamic>;
  }

  // Payment
  Future<Map<String, dynamic>> createPaymentOrder({
    required String orderId,
    required double amount,
    required String provider,
  }) async {
    final response = await _api.post('/payment/create-order', data: {
      'orderId': orderId,
      'amount': amount,
      'gateway': provider
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data) async {
    final response = await _api.post('/payment/verify', data: data);
    return response.data as Map<String, dynamic>;
  }
}
