import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/merchant_repository.dart';
import 'package:greenbasket_app/data/models/product_model.dart';

class ProductStockScreen extends StatefulWidget {
  final ProductModel product;
  const ProductStockScreen({super.key, required this.product});

  @override
  State<ProductStockScreen> createState() => _ProductStockScreenState();
}

class _ProductStockScreenState extends State<ProductStockScreen> {
  late int _currentStock;
  int _adjustAmount = 1;
  final _adjustController = TextEditingController(text: '1');
  final _repo = MerchantRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStock = widget.product.stock;
  }

  @override
  void dispose() {
    _adjustController.dispose();
    super.dispose();
  }

  void _increment() {
    setState(() {
      _adjustAmount++;
      _adjustController.text = _adjustAmount.toString();
    });
  }

  void _decrement() {
    if (_adjustAmount > 1) {
      setState(() {
        _adjustAmount--;
        _adjustController.text = _adjustAmount.toString();
      });
    }
  }

  Future<void> _updateStock(bool add) async {
    final newStock = add ? _currentStock + _adjustAmount : (_currentStock - _adjustAmount).clamp(0, 999999);
    
    setState(() => _isLoading = true);
    try {
      await _repo.updateStock(widget.product.id, newStock);
      setState(() {
        _currentStock = newStock;
      });
      Get.snackbar(
        'Stock Updated',
        'Stock set to $_currentStock ${widget.product.unit}',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update stock: $e', backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLow = _currentStock <= 5; // Simple low stock threshold

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Stock'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name
            Text(widget.product.name,
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.md),

            // Current stock card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Stock',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_currentStock',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          widget.product.unit,
                          style: AppTextStyles.titleLarge
                              .copyWith(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  if (isLow) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: AppSpacing.xs),
                          Text('Low Stock',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Adjust stock section
            Text('Adjust Stock', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _circleButton(
                        Icons.remove,
                        _decrement,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _adjustController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.headlineLarge,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onChanged: (v) {
                            _adjustAmount = int.tryParse(v) ?? 1;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      _circleButton(
                        Icons.add,
                        _increment,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  Text(widget.product.unit,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => _updateStock(false),
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 18),
                          label: const Text('Remove Stock'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(
                                color: AppColors.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _updateStock(true),
                          icon: const Icon(Icons.add_circle_outline,
                              size: 18),
                          label: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add Stock'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Done'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap,
      {required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
