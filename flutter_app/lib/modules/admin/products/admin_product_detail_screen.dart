import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import '../admin_controller.dart';

class AdminProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const AdminProductDetailScreen({super.key, this.product});

  @override
  State<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  final controller = Get.find<AdminController>();
  final _repo = AdminRepository();
  late Map<String, dynamic> _product;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product ?? Get.arguments?['product'] ?? {};
  }

  void _toggleStatus() async {
    final rawStatus = _product['status']?.toString() ?? 'active';
    final currentStatus = rawStatus.isNotEmpty ? (rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase()) : 'Active';
    final newStatus = currentStatus == 'Active' ? 'Inactive' : 'Active';

    setState(() => _isLoading = true);
    try {
      await _repo.updateProduct(_product['_id'] ?? _product['id'], {'status': newStatus.toLowerCase()});
      setState(() => _product['status'] = newStatus.toLowerCase());
      GBSnack.success('Success', 'Product status updated to $newStatus');
    } catch (e) {
      GBSnack.plain('Error', 'Failed to update status');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Delete Product?', style: AppTextStyles.titleLarge),
        content: Text('Are you sure you want to delete "${_product['name']}"? This cannot be undone.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GBButton(label: 'Delete', onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _repo.deleteProduct(_product['_id'] ?? _product['id']);
                await controller.fetchAll();
                Get.back();
                GBSnack.success('Deleted', 'Product removed successfully');
              } catch (e) {
                GBSnack.plain('Error', 'Failed to delete product');
              }
            }, backgroundColor: AppColors.error),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_product.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Product not found')));
    }

    final name = _product['name'] ?? 'Product Detail';
    final price = _product['price']?.toString() ?? '0';
    final stock = _product['stock']?.toString() ?? '0';
    final merchant = _product['merchant']?['businessName']?.toString() ?? _product['merchant']?['name']?.toString() ?? 'Unknown';
    final description = _product['description'] ?? 'No description available.';
    final category = _product['category']?['name']?.toString() ?? 'Uncategorized';
    final rawStatus = _product['status']?.toString() ?? 'active';
    final status = rawStatus.isNotEmpty ? (rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase()) : 'Active';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: IconButton(tooltip: 'Back', 
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primaryContainer,
                child: const Icon(Icons.eco_outlined, size: 80, color: AppColors.primary),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name, style: AppTextStyles.headlineLarge),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (status == 'Active' ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          status,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: status == 'Active' ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('by $merchant', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                  const Divider(height: 32),
                  
                  _buildDetailRow('Price', AppHelpers.formatCurrencyFlexible(price), Icons.payments_outlined),
                  _buildDetailRow('Stock', '$stock units', Icons.inventory_2_outlined),
                  _buildDetailRow('Category', category, Icons.category_outlined),
                  
                  const Divider(height: 32),
                  const Text('Description', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  Text(description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  
                  const SizedBox(height: 40),
                  const Text('Admin Controls', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: GBButton(label: status == 'Active' ? 'Deactivate' : 'Activate', onPressed: _isLoading ? null : _toggleStatus, leadingIcon: status == 'Active' ? Icons.pause_circle_outline : Icons.play_circle_outline, variant: GBButtonVariant.outline, foregroundColor: status == 'Active' ? AppColors.error : AppColors.success),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GBButton(label: 'Delete Product', onPressed: _confirmDelete, leadingIcon: Icons.delete_outline, variant: GBButtonVariant.outline, foregroundColor: AppColors.error),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          Text(value, style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }
}
