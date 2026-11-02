class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final AddressModel deliveryAddress;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final String? notes;
  final String? customerName;
  final String? customerPhone;
  final String? merchantId;
  final String? merchantName;
  final String deliveryType;



  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.estimatedDelivery,
    this.notes,
    this.customerName,
    this.customerPhone,
    this.merchantId,
    this.merchantName,
    required this.deliveryType,
  });


  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Handle deliveryAddress being either a populated object or just a string ID
    AddressModel address;
    if (json['deliveryAddress'] is Map<String, dynamic>) {
      address = AddressModel.fromJson(json['deliveryAddress']);
    } else {
      address = AddressModel.fromJson({});
    }

    // Handle customer being either a populated object or just a string ID
    String? custName;
    String? custPhone;
    if (json['customer'] is Map<String, dynamic>) {
      custName = json['customer']['name'];
      custPhone = json['customer']['phone'];
    }

    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? json['orderId'] ?? '',
      status: json['status'] ?? 'pending',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      subtotal: (json['subtotal'] ?? json['itemsTotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? json['deliveryCharges'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? json['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: address,
      paymentMethod: json['paymentMethod'] ?? 'cod',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.tryParse(json['estimatedDelivery'])
          : null,
      notes: json['notes'] ?? json['deliveryInstructions'],
      customerName: custName,
      customerPhone: custPhone,
      merchantId: json['merchant'] is Map ? json['merchant']['_id'] : (json['merchant'] as String?),
      merchantName: json['merchant'] is Map ? json['merchant']['businessName'] : null,
      deliveryType: json['deliveryType'] ?? 'home-delivery',
    );
  }


  bool get isActive => [
        'pending',
        'confirmed',
        'preparing',
        'dispatched',
      ].contains(status);
}

class OrderItem {
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final String? preparationOption;
  final String merchantId;
  final String merchantName;

  OrderItem({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    this.preparationOption,
    required this.merchantId,
    required this.merchantName,
  });

  double get itemTotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Handle product being a populated object or a raw ObjectId string
    String productId = '';
    String productName = '';
    String? productImage;
    final product = json['product'];
    if (product is Map<String, dynamic>) {
      productId = product['_id'] ?? '';
      productName = product['name'] ?? '';
      final images = product['images'];
      if (images is List && images.isNotEmpty) {
        final first = images[0];
        productImage = first is String ? first : (first is Map ? first['url'] : null);
      }
    } else if (product is String) {
      productId = product;
    }
    productId = productId.isEmpty ? (json['productId'] ?? '') : productId;
    productName = productName.isEmpty ? (json['productName'] ?? json['name'] ?? '') : productName;
    productImage ??= json['productImage'];

    // Handle merchant being a populated object or a raw ObjectId string
    String merchantId = '';
    String merchantName = '';
    final merchant = json['merchant'];
    if (merchant is Map<String, dynamic>) {
      merchantId = merchant['_id'] ?? '';
      merchantName = merchant['businessName'] ?? merchant['name'] ?? '';
    } else if (merchant is String) {
      merchantId = merchant;
    }
    merchantId = merchantId.isEmpty ? (json['merchantId'] ?? '') : merchantId;
    merchantName = merchantName.isEmpty ? (json['merchantName'] ?? '') : merchantName;

    return OrderItem(
      productId: productId,
      productName: productName,
      productImage: productImage,
      price: (json['price'] ?? 0).toDouble(),
      // Quantities are whole units; older carts may hold fractional values
      quantity: ((json['quantity'] as num?) ?? 1).ceil(),
      preparationOption: json['preparation'] ?? json['preparationOption'],
      merchantId: merchantId,
      merchantName: merchantName,
    );
  }
}

class AddressModel {
  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  AddressModel({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  String get fullAddress {
    final List<String> parts = [];
    if (line1.isNotEmpty) parts.add(line1);
    if (line2 != null && line2!.isNotEmpty) parts.add(line2!);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    
    String addr = parts.join(', ');
    if (pincode.isNotEmpty) {
      if (addr.isNotEmpty) {
        addr += ' - $pincode';
      } else {
        addr = pincode;
      }
    }
    return addr.isEmpty ? 'No address provided' : addr;
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'] ?? json['id'] ?? '',
      label: json['label'] ?? 'Home',
      line1: json['line1'] ?? json['addressLine1'] ?? json['address'] ?? '',
      line2: json['line2'] ?? json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      isDefault: json['isDefault'] ?? false,
      latitude: json['location']?['coordinates'] is List &&
              (json['location']['coordinates'] as List).length > 1
          ? json['location']['coordinates'][1]?.toDouble()
          : null,
      longitude: json['location']?['coordinates'] is List &&
              (json['location']['coordinates'] as List).isNotEmpty
          ? json['location']['coordinates'][0]?.toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label.toLowerCase() == 'work' ? 'office' : label.toLowerCase(),
        'addressLine1': line1,
        'line1': line1,
        'addressLine2': line2,
        'line2': line2,
        'landmark': line2,
        'city': city,
        'state': state.isNotEmpty ? state : 'Kerala',
        'pincode': pincode,
        'isDefault': isDefault,
      };
}

class CartItemModel {
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  int quantity;
  final String merchantId;
  final String merchantName;
  final String? preparationOption;
  final String unit;

  CartItemModel({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.merchantId,
    required this.merchantName,
    this.preparationOption,
    required this.unit,
  });

  double get itemTotal => price * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>?;
    String? img;
    if (productJson?['images'] is List && (productJson?['images'] as List).isNotEmpty) {
      final first = productJson?['images'][0];
      img = first is String ? first : (first is Map ? first['url'] : null);
    }
    img ??= productJson?['primaryImage'];

    return CartItemModel(
      productId: productJson?['_id'] ?? json['productId'] ?? '',
      productName: productJson?['name'] ?? json['productName'] ?? '',
      productImage: img,
      price: (json['price'] ?? productJson?['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      merchantId: productJson?['merchant'] is Map 
          ? (productJson?['merchant']['_id'] ?? '') 
          : (productJson?['merchant'] ?? ''),
      merchantName: productJson?['merchant'] is Map 
          ? (productJson?['merchant']['businessName'] ?? productJson?['merchant']['name'] ?? '') 
          : '',
      preparationOption: json['preparation'] ?? json['preparationOption'],
      unit: productJson?['unit'] ?? 'kg',
    );
  }
}
