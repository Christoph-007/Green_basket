import '../nav_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../widgets/cards/product_card.dart';
import '../../../widgets/common/gb_app_bar.dart';
import '../../../widgets/common/gb_loader.dart';
import '../../../widgets/common/empty_state.dart';
import '../cart/cart_controller.dart';
import '../profile/wishlist_controller.dart';


class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<WishlistController>();


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GBAppBar(title: 'Wishlist'),
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBLoader();
        
        // Fetch products for the IDs in wishlist
        // Note: WishlistController only knows IDs. We need ProductRepository to get details.
        // Actually, the backend getWishlist returns full products.
        // Let's update WishlistController to store ProductModels.
        return _WishlistGrid();
      }),
    );
  }
}

class _WishlistGrid extends StatefulWidget {
  @override
  State<_WishlistGrid> createState() => _WishlistGridState();
}

class _WishlistGridState extends State<_WishlistGrid> {
  final _repo = ProductRepository();
  final _items = <ProductModel>[].obs;
  final _isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      _items.value = await _repo.getWishlist();
    } catch (_) {}
    _isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final wishlistCtrl = Get.find<WishlistController>();
    final cartCtrl = Get.find<CartController>();
    
    return Obx(() {
      if (_isLoading.value) return const GBLoader();
      
      // Filter items based on global wishlistIds (so removals are reflected)
      final activeItems = _items.where((p) => wishlistCtrl.isWishlisted(p.id)).toList();
      
      if (activeItems.isEmpty) {
        return EmptyState(
          icon: Icons.favorite_border,
          title: 'Your wishlist is empty',
          message: 'Save items you love to your wishlist',
          actionLabel: 'Browse Products',
          onAction: () => NavController.to.openCategories(),
        );
      }
      
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: activeItems.length,
        itemBuilder: (context, i) {
          final p = activeItems[i];
          return ProductCard(
            product: p,
            isInWishlist: true,
            onWishlistToggle: () => wishlistCtrl.toggleWishlist(p.id),
            onAddToCart: (prepId) => cartCtrl.addItem(
                productId: p.id, quantity: 1, preparationOption: prepId),
          );
        },
      );
    });
  }
}

