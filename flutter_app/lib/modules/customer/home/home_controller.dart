import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/recipe_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../data/services/location_service.dart';

class HomeController extends GetxController {
  final _productRepo = ProductRepository();
  final _recipeRepo = RecipeRepository();

  final isLoading = false.obs;
  final categories = <CategoryModel>[].obs;
  final featuredProducts = <ProductModel>[].obs;
  final flashSaleProducts = <ProductModel>[].obs;
  final bannerImages = <String>[].obs;
  final availableOffers = <Map<String, dynamic>>[].obs;
  final activeFlashSales = <Map<String, dynamic>>[].obs;
  final recipes = <RecipeModel>[].obs;

  // Nearby info
  final selectedRadiusKm = 10.0.obs; // User toggle for radius on Home
  final actualRadiusKm = 0.0.obs;
  final hasLocation = false.obs;
  final locationFromDevice = false.obs;
  final showAll = false.obs; 

  double? _lat;
  double? _lng;

  double? get latitude => _lat;
  double? get longitude => _lng;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  void updateRadius(double radius) {
    selectedRadiusKm.value = radius;
    fetchData();
  }
  
  void toggleShowAll() {
    showAll.value = !showAll.value;
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;

    // Capture location (live GPS > stored user location > none)
    final locResult = await LocationService.getLocation();
    if (locResult != null) {
      _lat = locResult.lat;
      _lng = locResult.lng;
      hasLocation.value = true;
      locationFromDevice.value = locResult.isFromDevice;
    }

    try {
      // Fetch home data and recipes separately to handle individual failures
      Map<String, dynamic>? homeData;
      List<RecipeModel>? recipeList;

      try {
        homeData = await _productRepo.getHomeData(
          lat: _lat,
          lng: _lng,
          radius: selectedRadiusKm.value,
        );
      } catch (e) {
        debugPrint('Error fetching home data: $e');
      }

      try {
        recipeList = await _recipeRepo.getRecipes(limit: 10);
      } catch (e) {
        debugPrint('Error fetching recipes: $e');
      }

      if (homeData != null) {
        categories.assignAll(homeData['categories'] as List<CategoryModel>);
        featuredProducts.assignAll(homeData['featuredProducts'] as List<ProductModel>);
        
        // Flash sales and offers
        activeFlashSales.assignAll(List<Map<String, dynamic>>.from(homeData['flashSales'] as List));
        availableOffers.assignAll(List<Map<String, dynamic>>.from(homeData['banners'] as List));

        // Update radius info from server response
        if (homeData.containsKey('actual_radius_km')) {
          actualRadiusKm.value = (homeData['actual_radius_km'] as num).toDouble();
        } else {
          actualRadiusKm.value = selectedRadiusKm.value;
        }
      }

      if (recipeList != null) {
        recipes.assignAll(recipeList);
      }
    } catch (e) {
      debugPrint('Overall home data fetch error: $e');
    }
    
    isLoading.value = false;
  }
}

