import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:greenbasket_app/data/repositories/merchant_repository.dart';
import 'package:greenbasket_app/data/models/product_model.dart';
import 'dart:async';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'merchant_product_controller.dart';
import 'add_product_screen.dart';
import 'bulk_upload_screen.dart';
import 'edit_product_screen.dart';
import 'product_stock_screen.dart';
import '../widgets/merchant_drawer.dart';

class MerchantProductsScreen extends StatelessWidget {
  const MerchantProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MerchantProductController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Inventory Management'),
          elevation: 0,
          backgroundColor: Colors.white,
          leading: Builder(
            builder: (context) {
              return IconButton(tooltip: 'Open menu', 
                icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
          actions: [
            IconButton(tooltip: 'Search', 
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              onPressed: () {},
            ),
            IconButton(tooltip: 'Upload', 
              icon: const Icon(Icons.upload_file, color: AppColors.primary),
              onPressed: () => Get.to(() => const BulkUploadScreen()),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Obx(() => Tab(
                  text:
                      'All Products (${controller.products.length})')),
              Obx(() => Tab(
                  text:
                      'In Stock (${controller.products.where((p) => p.stock > 0).length})')),
              Obx(() => Tab(
                  text:
                      'Out of Stock (${controller.products.where((p) => p.stock == 0).length})')),
            ],
          ),
        ),
        drawer: const MerchantDrawer(),
        body: const TabBarView(
          children: [
            _ProductGrid(),
            _ProductGrid(onlyInStock: true),
            _ProductGrid(onlyOutOfStock: true),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Get.to(() => const AddProductScreen());
            if (result == true) controller.fetchProducts();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final bool onlyInStock;
  final bool onlyOutOfStock;

  const _ProductGrid({
    this.onlyInStock = false,
    this.onlyOutOfStock = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MerchantProductController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      var items = controller.products;
      if (onlyInStock) {
        items = items.where((p) => controller.stockOf(p) > 0).toList().obs;
      } else if (onlyOutOfStock) {
        items = items.where((p) => controller.stockOf(p) == 0).toList().obs;
      }

      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.md),
              const Text('No products found',
                  style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                onlyOutOfStock
                    ? 'All products are in stock!'
                    : onlyInStock
                        ? 'No in-stock products'
                        : 'Add your first product',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchProducts(),
        child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,

          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemBuilder: (context, index) {
          final product = items[index];
          return Obx(() {
          final stock = controller.stockOf(product);
          final inStock = stock > 0;
          final lowStock = inStock && stock <= 5;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () async {
                  final result = await Get.to(() => EditProductScreen(product: product));
                  if (result == true) controller.fetchProducts();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.lg)),
                            ),
                            child: Center(
                              child: product.primaryImage.isNotEmpty
                                  ? Image.network(product.primaryImage,
                                      fit: BoxFit.cover)
                                  : Icon(Icons.local_florist,
                                      size: 50,
                                      color: AppColors.primary.withValues(alpha: 0.5)),
                            ),
                          ),
                          if (!inStock)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppRadius.lg)),
                              ),
                            ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: !inStock
                                    ? AppColors.error
                                    : lowStock
                                        ? AppColors.warning
                                        : AppColors.success,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                boxShadow: const [
                                  BoxShadow(blurRadius: 4, color: Colors.black12)
                                ],
                              ),
                              child: Text(
                                !inStock
                                    ? 'Out of Stock'
                                    : lowStock
                                        ? 'Low stock'
                                        : 'In Stock',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: lowStock
                                        ? AppColors.textPrimary
                                        : Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(AppHelpers.formatPrice(product.price),
                                    style: AppTextStyles.titleMedium
                                        .copyWith(color: AppColors.primary)),
                                Text(' / ${product.unit}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _StockStepper(product: product, controller: controller),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          });
        },
      ),
      );
    });
  }
}

/// Change a product's stock from the list: minus, the number, plus. Taps are
/// shown at once and sent as one request after a short pause. Tapping the
/// number opens the full stock screen.
class _StockStepper extends StatefulWidget {
  final ProductModel product;
  final MerchantProductController controller;

  const _StockStepper({required this.product, required this.controller});

  @override
  State<_StockStepper> createState() => _StockStepperState();
}

class _StockStepperState extends State<_StockStepper> {
  final _repo = MerchantRepository();
  Timer? _timer;
  late int _saved; // the last stock the server confirmed

  @override
  void initState() {
    super.initState();
    _saved = widget.controller.stockOf(widget.product);
  }

  @override
  void dispose() {
    // Leaving the screen with a change waiting: send it now.
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
      _send();
    }
    super.dispose();
  }

  void _change(int delta) {
    final current = widget.controller.stockOf(widget.product);
    final next = (current + delta).clamp(0, 999999);
    if (next == current) return;
    widget.controller.setStockLocally(widget.product.id, next);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), _send);
  }

  Future<void> _send() async {
    // Copy what is needed first: this can finish after the card is gone.
    final controller = widget.controller;
    final id = widget.product.id;
    final value = controller.stockOf(widget.product);
    if (value == _saved) return;
    try {
      await _repo.updateStock(id, value);
      _saved = value;
    } catch (e) {
      controller.setStockLocally(id, _saved);
      GBSnack.fromError(e, title: 'Stock not updated');
    }
  }

  Widget _button(IconData icon, String tooltip, VoidCallback? onPressed) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stock = widget.controller.stockOf(widget.product);
      return Row(
        children: [
          _button(Icons.remove, 'Decrease stock', stock > 0 ? () => _change(-1) : null),
          Expanded(
            child: InkWell(
              onTap: () async {
                final result = await Get.to(
                    () => ProductStockScreen(product: widget.product));
                if (result == true) widget.controller.fetchProducts();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '$stock ${widget.product.unit}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          _button(Icons.add, 'Increase stock', () => _change(1)),
        ],
      );
    });
  }
}
