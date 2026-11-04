import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'admin_product_detail_screen.dart';
import '../admin_controller.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchController = TextEditingController();
  final RxSet<String> _selectedIds = <String>{}.obs;
  final RxBool _selectionMode = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _selectedCategory = 'All'.obs;
  final RxString _selectedStatus = 'All'.obs;
  final controller = Get.find<AdminController>();

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.textSecondary;
      case 'out-of-stock':
      case 'suspended':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Sort & Filter', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            const Text('Category', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Obx(() {
              final cats = ['All', ...controller.categories.map((c) => c['name'].toString())];
              return Wrap(
                spacing: AppSpacing.sm,
                children: cats.map((c) => FilterChip(
                  label: Text(c),
                  selected: _selectedCategory.value == c,
                  onSelected: (selected) => _selectedCategory.value = c,
                )).toList(),
              );
            }),
            const SizedBox(height: AppSpacing.md),
            const Text('Status', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Obx(() => Wrap(
              spacing: AppSpacing.sm,
              children: ['All', 'Active', 'Inactive', 'Out-of-stock', 'Suspended']
                  .map((s) => FilterChip(
                    label: Text(s),
                    selected: _selectedStatus.value == s,
                    onSelected: (selected) => _selectedStatus.value = s,
                  ))
                  .toList(),
            )),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _selectedCategory.value = 'All';
                      _selectedStatus.value = 'All';
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GBButton(label: 'Apply Filters', onPressed: () => Navigator.pop(ctx)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _showBulkActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => Text('${_selectedIds.length} product(s) selected', style: AppTextStyles.titleMedium)),
            const SizedBox(height: AppSpacing.md),
            _bulkAction(Icons.check_circle_outline, 'Activate Selected', AppColors.success),
            _bulkAction(Icons.pause_circle_outline, 'Suspend Selected', AppColors.warning),
            _bulkAction(Icons.delete_outline, 'Delete Selected', AppColors.error),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _bulkAction(IconData icon, String label, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: color)),
      onTap: () {
        Navigator.pop(context);
        _selectedIds.clear();
        _selectionMode.value = false;
        Get.snackbar('Done', '$label applied.', backgroundColor: color, colorText: Colors.white);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => _selectionMode.value
            ? Text('${_selectedIds.length} Selected')
            : const Text('Products Management')),
        leading: IconButton(
          icon: Obx(() => Icon(_selectionMode.value ? Icons.close : Icons.arrow_back_ios_new, size: 18)),
          onPressed: () {
            if (_selectionMode.value) {
              _selectionMode.value = false;
              _selectedIds.clear();
            } else {
              Get.back();
            }
          },
        ),
        actions: [
          Obx(() => _selectionMode.value
            ? TextButton(
                onPressed: _selectedIds.isNotEmpty ? _showBulkActionsSheet : null,
                child: const Text('Actions'),
              )
            : IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterSheet,
              )),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => _searchQuery.value = v,
                    decoration: const InputDecoration(
                      hintText: 'Search products or merchants...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Obx(() => IconButton(
                  icon: Icon(
                    _selectionMode.value ? Icons.check_box : Icons.check_box_outline_blank,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    _selectionMode.value = !_selectionMode.value;
                    _selectedIds.clear();
                  },
                  tooltip: 'Select multiple',
                )),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final List<Map<String, dynamic>> products = controller.products.cast<Map<String, dynamic>>();
              final filteredProducts = products.where((product) {
                final String name = (product['name'] as String? ?? '').toLowerCase();
                final String mName = (product['merchant']?['businessName']?.toString() ?? '').toLowerCase();
                final String status = (product['status']?.toString() ?? 'active').toLowerCase();
                final String cat = (product['category']?['name']?.toString() ?? '').toLowerCase();
                
                final String query = _searchQuery.value.toLowerCase();
                final String selectedCat = _selectedCategory.value.toLowerCase();
                final String selectedStatus = _selectedStatus.value.toLowerCase();

                final matchesSearch = name.contains(query) || mName.contains(query);
                final matchesCategory = selectedCat == 'all' || cat == selectedCat;
                final matchesStatus = selectedStatus == 'all' || status == selectedStatus;

                return matchesSearch && matchesCategory && matchesStatus;
              }).toList();

              if (filteredProducts.isEmpty) {
                return const Center(child: Text('No products found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: filteredProducts.length,
                itemBuilder: (_, i) => _buildProductCard(filteredProducts[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final id = product['_id'] ?? product['id'];
    final isSelected = _selectedIds.contains(id);
    final status = product['status']?.toString() ?? 'active';
    final isActive = product['isActive'] ?? true;
    final displayStatus = !isActive ? 'Suspended' : (status[0].toUpperCase() + status.substring(1));
    final stock = product['stock'] ?? 0;
    final merchantName = product['merchant']?['businessName']?.toString() ?? product['merchant']?['name']?.toString() ?? 'Unknown Merchant';
    final price = product['price']?.toString() ?? '0';
    final totalSales = product['totalSales'] ?? 0;
    final rating = (product['averageRating'] ?? 0.0) as num;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          if (_selectionMode.value) {
            if (isSelected) {
              _selectedIds.remove(id);
            } else {
              _selectedIds.add(id);
            }
          } else {
            Get.to(() => AdminProductDetailScreen(product: product));
          }
        },
        onLongPress: () {
          _selectionMode.value = true;
          _selectedIds.add(id);
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Obx(() => _selectionMode.value
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        if (isSelected) {
                          _selectedIds.remove(id);
                        } else {
                          _selectedIds.add(id);
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                  )
                : const SizedBox.shrink()),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  image: product['primaryImage'] != null && product['primaryImage'].toString().startsWith('http')
                    ? DecorationImage(
                        image: NetworkImage(product['primaryImage'].toString()),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: product['primaryImage'] == null || !product['primaryImage'].toString().startsWith('http')
                  ? const Icon(Icons.eco_outlined, color: AppColors.primary, size: 28)
                  : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] as String? ?? 'Unnamed Product', style: AppTextStyles.labelLarge),
                    Text(merchantName, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(AppHelpers.formatCurrencyFlexible(price), style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.star, size: 12, color: Colors.orange),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: AppTextStyles.labelSmall),
                        const SizedBox(width: AppSpacing.sm),
                        Text('$totalSales sold', style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stock == 0 ? 'Out of stock' : 'Stock: $stock',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: stock == 0 ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(displayStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  displayStatus,
                  style: AppTextStyles.labelSmall.copyWith(color: _statusColor(displayStatus)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
