import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';
import 'package:greenbasket_app/widgets/common/gb_card.dart';
import 'package:greenbasket_app/widgets/common/gb_gradient_header.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_network_image.dart';
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
        appBar: GBBrandAppBar(title: 'Inventory Management', showMenu: true, actions: [
            IconButton(tooltip: 'Search', 
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
            IconButton(tooltip: 'Upload', 
              icon: const Icon(Icons.upload_file),
              onPressed: () => Get.to(() => const BulkUploadScreen()),
            ),
          ], bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
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
          )),
        drawer: const MerchantDrawer(),
        bottomNavigationBar: _BulkBar(controller: controller),
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
        return const GBLoader();
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
              Text('No products found',
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
          final selected = controller.selectedIds.contains(product.id);

          return Container(
            decoration: GBCard.decoration().copyWith(border: selected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onLongPress: () => controller.toggleSelected(product.id),
                onTap: () async {
                  if (controller.isSelecting) {
                    controller.toggleSelected(product.id);
                    return;
                  }
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
                                  ? GBNetworkImage(
                                      url: product.primaryImage,
                                      width: double.infinity,
                                      height: double.infinity,
                                      memCacheWidth: 400)
                                  : Icon(Icons.local_florist,
                                      size: 50,
                                      color: AppColors.primaryText.withValues(alpha: 0.5)),
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
                          if (selected)
                            const Positioned(
                              top: 8,
                              left: 8,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.check, size: 16, color: Colors.white),
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
                                boxShadow: [
                                  BoxShadow(blurRadius: 4, color: AppColors.shadow)
                                ],
                              ),
                              child: Text(
                                !inStock
                                    ? 'Out of Stock'
                                    : lowStock
                                        ? 'Low stock'
                                        : 'In Stock',
                                style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, color: lowStock
                                        ? AppColors.textPrimary
                                        : Colors.white),
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
                                        .copyWith(color: AppColors.primaryText)),
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
          side: BorderSide(color: AppColors.border),
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

/// Appears while products are ticked (long-press a card to start): set the
/// same stock, or move the prices by a percentage, for all of them at once.
class _BulkBar extends StatelessWidget {
  final MerchantProductController controller;

  const _BulkBar({required this.controller});

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    try {
      final result = await action();
      final done = (result['successCount'] as num?)?.toInt() ?? 0;
      final failed = (result['errorCount'] as num?)?.toInt() ?? 0;
      if (failed == 0) {
        GBSnack.success('Updated', '$done products updated.');
      } else {
        GBSnack.info('Partly updated', '$done updated, $failed could not be changed.');
      }
    } catch (e) {
      GBSnack.fromError(e, title: "Couldn't update products");
    }
  }

  Future<void> _askStock() async {
    final text = TextEditingController();
    final value = await Get.dialog<int>(
      AlertDialog(
        title: Text('Set stock for ${controller.selectedIds.length} products'),
        content: TextField(
          controller: text,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stock (whole number)'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final n = int.tryParse(text.text.trim());
              if (n == null || n < 0) {
                GBSnack.error('Check the number', 'Enter a whole number, zero or more.');
                return;
              }
              Get.back(result: n);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (value != null) await _run(() => controller.bulkSetStock(value));
  }

  Future<void> _askPrice() async {
    final text = TextEditingController();
    final value = await Get.dialog<double>(
      AlertDialog(
        title: Text('Change price of ${controller.selectedIds.length} products'),
        content: TextField(
          controller: text,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          decoration: const InputDecoration(
            labelText: 'Percent change',
            helperText: 'For example 10 to raise by 10%, -5 to lower by 5%',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final n = double.tryParse(text.text.trim());
              if (n == null || n <= -100 || n > 500) {
                GBSnack.error('Check the number', 'Enter a percentage between -99 and 500.');
                return;
              }
              Get.back(result: n);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (value != null) await _run(() => controller.bulkChangePrice(value));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.selectedIds.length;
      if (count == 0) return const SizedBox.shrink();
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          decoration: GBCard.decoration(),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Clear selection',
                icon: const Icon(Icons.close),
                onPressed: controller.clearSelection,
              ),
              Expanded(child: Text('$count selected', style: AppTextStyles.titleMedium)),
              TextButton.icon(
                onPressed: _askStock,
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: const Text('Set stock'),
              ),
              TextButton.icon(
                onPressed: _askPrice,
                icon: const Icon(Icons.sell_outlined, size: 18),
                label: const Text('Price'),
              ),
            ],
          ),
        ),
      );
    });
  }
}
