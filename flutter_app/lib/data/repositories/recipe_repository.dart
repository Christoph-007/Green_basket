import '../providers/api_provider.dart';
import '../models/recipe_model.dart';

class RecipeRepository {
  final _api = ApiProvider();

  // GET /api/recipes
  Future<List<RecipeModel>> getRecipes({
    int page = 1,
    int limit = 20,
    String? search,
    // 'breakfast' | 'lunch' | 'dinner' | 'snack' | 'dessert' (any case); null or 'All' means every meal
    String? mealType,
    double? lat,
    double? lng,
    double? radius,
  }) async {
    final res = await _api.get('/recipes', params: {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
      if (mealType != null && mealType.toLowerCase() != 'all')
        'mealType': mealType.toLowerCase(),
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radius != null) 'radius': radius,
    });
    final data = res.data['data'];
    final list = (data is Map) ? (data['recipes'] ?? []) : (data ?? []);
    return (list as List).map((e) => RecipeModel.fromJson(e)).toList();
  }

  // GET /api/recipes/search
  Future<List<RecipeModel>> searchRecipes(String query) async {
    final res = await _api.get('/recipes/search', params: {'q': query});
    final data = res.data['data'];
    final list = (data is Map) ? (data['recipes'] ?? []) : (data ?? []);
    return (list as List).map((e) => RecipeModel.fromJson(e)).toList();
  }

  // GET /api/recipes/:id
  Future<RecipeModel> getRecipeById(String id) async {
    final res = await _api.get('/recipes/$id');
    final data = res.data['data'] ?? res.data;
    final recipeJson = data['recipe'] ?? data;
    return RecipeModel.fromJson(recipeJson);
  }

  // POST /api/recipes/:id/calculate-ingredients
  Future<Map<String, dynamic>> calculateIngredients(
    String id, {
    int servings = 2,
    double? lat,
    double? lng,
    double? radius,
  }) async {
    final res = await _api.post(
      '/recipes/$id/calculate-ingredients',
      data: {
        'servings': servings,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (radius != null) 'radius': radius,
      },
    );
    return res.data;
  }

  // POST /api/cart/recipe-to-cart
  Future<Map<String, dynamic>> addRecipeToCart(
    String recipeId, {
    int servings = 2,
    double? lat,
    double? lng,
    double? radius,
  }) async {
    final res = await _api.post('/cart/recipe-to-cart', data: {
      'recipeId': recipeId,
      'servings': servings,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radius != null) 'radius': radius,
    });
    return res.data;
  }

  // GET /api/recipes/by-product/:productId
  Future<List<RecipeModel>> getRecipesByProductId(String productId) async {
    final res = await _api.get('/recipes/by-product/$productId');
    final data = res.data['data'] ?? res.data;
    final list = data['recipes'] ?? [];
    return (list as List).map((e) => RecipeModel.fromJson(e)).toList();
  }
}
