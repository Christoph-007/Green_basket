import '../providers/api_provider.dart';
import '../models/product_model.dart';

class ProductRepository {
  final _api = ApiProvider();

  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? search,
    bool? isOrganic,
    bool? isFeatured,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get('/products', params: {
      if (categoryId != null) 'category': categoryId,
      if (search != null) 'search': search,
      if (isOrganic != null) 'isOrganic': isOrganic,
      if (isFeatured != null) 'isFeatured': isFeatured,
      if (sortBy != null) 'sort': sortBy,
      'page': page,
      'limit': limit,
    });
    final data = response.data as Map<String, dynamic>;
    // Backend returns { data: { products: [...], pagination: {...} } }
    final inner = data['data'];
    List<dynamic> items;
    if (inner is Map<String, dynamic>) {
      items = inner['products'] as List<dynamic>? ?? [];
    } else if (inner is List) {
      items = inner;
    } else {
      items = [];
    }
    return items.map((e) => ProductModel.fromJson(e)).toList();
  }

  /// Fetch products from nearby merchants only.
  /// Returns a map with 'products', 'actual_radius_km', and 'total_found'.
  Future<Map<String, dynamic>> getNearbyProducts({
    required double lat,
    required double lng,
    double radius = 5,
    String? categoryId,
    String? search,
    String sort = 'score',
    int page = 1,
    int limit = 20,
    bool allProducts = false,
  }) async {
    final response = await _api.get('/products/nearby', params: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      if (categoryId != null) 'category': categoryId,
      if (search != null) 'search': search,
      'sort': sort,
      'page': page,
      'limit': limit,
      if (allProducts) 'all': 'true',
    });
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? {};
    final items = inner['products'] as List<dynamic>? ?? [];
    return {
      'products': items.map((e) => ProductModel.fromJson(e)).toList(),
      'actual_radius_km': (inner['actual_radius_km'] ?? radius).toDouble(),
      'search_radius_km': (inner['search_radius_km'] ?? radius).toDouble(),
      'total_found': inner['total_found'] ?? 0,
    };
  }

  Future<ProductModel> getProduct(String id) async {
    final response = await _api.get('/products/$id');
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'];
    if (inner is Map<String, dynamic> && inner.containsKey('product')) {
      return ProductModel.fromJson(inner['product']);
    }
    return ProductModel.fromJson(inner);
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _api.get('/categories');
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];
    return items.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> search(String query) async {
    final response = await _api.get('/search/products', params: {'q': query});
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'];
    List<dynamic> items;
    if (inner is Map<String, dynamic>) {
      items = inner['products'] as List<dynamic>? ?? [];
    } else if (inner is List) {
      items = inner;
    } else {
      items = [];
    }
    return items.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<void> addToWishlist(String productId) async {
    await _api.post('/wishlist/add', data: {'productId': productId});
  }

  Future<void> removeFromWishlist(String productId) async {
    await _api.delete('/wishlist/remove/$productId');
  }

  Future<List<ProductModel>> getWishlist() async {
    final response = await _api.get('/wishlist');
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];
    return items.map((e) => ProductModel.fromJson(e['product'])).toList();
  }

  Future<List<Map<String, dynamic>>> getAvailableOffers({String? merchantId}) async {
    final response = await _api.get('/offers/available', params: {
      if (merchantId != null) 'merchantId': merchantId,
    });
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? {};
    return List<Map<String, dynamic>>.from(inner['offers'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getFlashSales() async {
    final response = await _api.get('/offers/flash-sales');
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? {};
    return List<Map<String, dynamic>>.from(inner['flashSales'] ?? []);
  }

  Future<List<ProductModel>> getSimilarProducts(String productId, String categoryId) async {
    final response = await _api.get('/products', params: {
      'category': categoryId,
      'limit': 10,
    });
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'];
    List<dynamic> items;
    if (inner is Map<String, dynamic>) {
      items = inner['products'] as List<dynamic>? ?? [];
    } else if (inner is List) {
      items = inner;
    } else {
      items = [];
    }
    
    // Filter out current product
    final allProducts = items.map((e) => ProductModel.fromJson(e)).toList();
    return allProducts.where((p) => p.id != productId).toList();
  }

  Future<Map<String, dynamic>> getHomeData({
    double? lat,
    double? lng,
    double radius = 10,
  }) async {
    final response = await _api.get('/home/customer-init', params: {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'radius': radius,
    });
    
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? {};
    
    final cats = (inner['categories'] as List<dynamic>? ?? [])
        .map((e) => CategoryModel.fromJson(e)).toList();
    
    final featured = (inner['featuredProducts'] as List<dynamic>? ?? [])
        .map((e) => ProductModel.fromJson(e)).toList();
        
    return {
      'categories': cats,
      'featuredProducts': featured,
      'flashSales': inner['flashSales'] as List<dynamic>? ?? [],
      'banners': inner['banners'] as List<dynamic>? ?? [],
    };
  }
}
