import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _orderRepo = OrderRepository();

  // Data
  final _orders = <OrderModel>[].obs;
  final _isLoadingOrders = false.obs;
  final _disputes = <Map<String, dynamic>>[].obs;
  final _isLoadingDisputes = false.obs;

  // Dialog state
  String _dialogIssueType = 'Wrong Item';
  OrderModel? _selectedOrder;
  OrderItem? _selectedProduct;
  final _dialogDescCtrl = TextEditingController();

  final List<String> _issueTypes = [
    'Wrong Item',
    'Missing Item',
    'Quality Issue',
    'Damaged Package',
    'Overcharged',
    'Return Item',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchOrders().then((_) {
      // If navigated from Order Details with a specific order/product
      final args = Get.arguments;
      if (args is Map) {
        if (args.containsKey('order')) {
          _selectedOrder = args['order'] as OrderModel;
          if (args.containsKey('product')) {
            _selectedProduct = args['product'] as OrderItem;
            _dialogIssueType = 'Return Item';
          }
          // Small delay to ensure build is ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showRaiseDisputeDialog();
          });
        }
      }
    });
    _fetchDisputes();
  }

  Future<void> _fetchOrders() async {
    _isLoadingOrders.value = true;
    try {
      final orders = await _orderRepo.getOrders();
      _orders.value = orders;
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      _isLoadingOrders.value = false;
    }
  }

  Future<void> _fetchDisputes() async {
    _isLoadingDisputes.value = true;
    try {
      final disputes = await _orderRepo.getMyDisputes();
      _disputes.value = disputes;
    } catch (e) {
      debugPrint('Error fetching disputes: $e');
    } finally {
      _isLoadingDisputes.value = false;
    }
  }

  Future<void> _submitDispute() async {
    if (_selectedOrder == null) {
      Get.snackbar('Error', 'Please select an order', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_dialogDescCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a description', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      final orderId = _selectedOrder!.id;
      final reason = _dialogIssueType;
      final description = _dialogDescCtrl.text.trim();
      final productId = _selectedProduct?.productId;

      await _orderRepo.raiseDispute(
        orderId: orderId,
        reason: reason,
        description: description,
        productId: productId,
      );

      Get.back(); // close dialog
      _fetchDisputes(); // refresh list
      
      Get.snackbar(
        reason == 'Return Item' ? 'Return Requested' : 'Dispute Raised',
        'Our team will review your request regarding ${_selectedProduct?.productName ?? "Order ${_selectedOrder!.orderNumber}"}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to raise dispute: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _dialogDescCtrl.dispose();
    super.dispose();
  }

  void _showRaiseDisputeDialog() {
    // Keep values if they were pre-filled in initState
    _selectedOrder ??= null; 
    _selectedProduct ??= null;
    _dialogIssueType = _selectedProduct != null ? 'Return Item' : _issueTypes.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          title: const Text('Raise a Dispute / Return',
              style: AppTextStyles.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Dropdown
                const Text('Select Order', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Obx(() {
                  if (_isLoadingOrders.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_orders.isEmpty) {
                    return const Text('No orders found to dispute.', style: TextStyle(color: AppColors.textSecondary));
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<OrderModel>(
                        value: _selectedOrder,
                        isExpanded: true,
                        hint: const Text('Select an Order'),
                        items: _orders.map((order) {
                          return DropdownMenuItem<OrderModel>(
                            value: order,
                            child: Text(
                              '${order.orderNumber} - ${order.status.toUpperCase()}',
                              style: AppTextStyles.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDlgState(() {
                            _selectedOrder = val;
                            _selectedProduct = null; // Reset product on order change
                          });
                        },
                      ),
                    ),
                  );
                }),

                if (_selectedOrder != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Select Product (Optional)', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<OrderItem>(
                        value: _selectedProduct,
                        isExpanded: true,
                        hint: const Text('Whole Order'),
                        items: [
                          const DropdownMenuItem<OrderItem>(
                            value: null,
                            child: Text('Whole Order'),
                          ),
                          ..._selectedOrder!.items.map((item) {
                            return DropdownMenuItem<OrderItem>(
                              value: item,
                              child: Text(
                                item.productName,
                                style: AppTextStyles.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setDlgState(() => _selectedProduct = val);
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.sm),
                const Text('Issue Type', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _dialogIssueType,
                      isExpanded: true,
                      onChanged: (v) =>
                          setDlgState(() => _dialogIssueType = v!),
                      items: _issueTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: AppTextStyles.bodyMedium),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _dialogDescCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    hintText: 'Describe the issue or reason for return...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _submitDispute,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(_dialogIssueType == 'Return Item' ? 'Request Return' : 'Submit Dispute'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeStatuses = ['open', 'investigating', 'escalated'];
      final activeDisputes = _disputes
          .where((d) => activeStatuses.contains(d['status'].toString()))
          .toList();
      final resolvedDisputes = _disputes
          .where((d) => !activeStatuses.contains(d['status'].toString()))
          .toList();

      if (_isLoadingDisputes.value && _disputes.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
          title: const Text('My Disputes & Returns',
              style: AppTextStyles.titleLarge),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.add_rounded, color: AppColors.primary),
              onPressed: _showRaiseDisputeDialog,
              tooltip: 'Raise a Dispute',
            ),
          ],
          bottom: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: AppTextStyles.labelLarge,
            tabs: [
              Tab(text: 'Active (${activeDisputes.length})'),
              Tab(text: 'Resolved (${resolvedDisputes.length})'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildList(activeDisputes),
            _buildList(resolvedDisputes),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showRaiseDisputeDialog,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.report_problem_rounded),
          label: const Text(
            'Raise Dispute',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w600),
          ),
        ),
      );
    });
  }

  Widget _buildList(List<Map<String, dynamic>> disputes) {
    if (disputes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 64),
            const SizedBox(height: AppSpacing.md),
            const Text('No disputes here',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('All disputes have been resolved',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: disputes.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _buildDisputeCard(disputes[i]),
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> dispute) {
    final status = dispute['status']?.toString() ?? 'open';
    final disputeId = dispute['disputeId']?.toString() ?? 'N/A';
    final category = dispute['category']?.toString() ?? 'Other';
    final description = dispute['description']?.toString() ?? '';
    final createdAt = dispute['createdAt']?.toString() ?? '';
    
    Color statusColor;
    switch (status) {
      case 'resolved':
      case 'closed':
        statusColor = AppColors.success;
        break;
      case 'investigating':
      case 'open':
        statusColor = AppColors.primary;
        break;
      case 'escalated':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#$disputeId', style: AppTextStyles.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.labelSmall
                      .copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(category,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(description, style: AppTextStyles.bodySmall),
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Created: ${createdAt.split('T')[0]}',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}