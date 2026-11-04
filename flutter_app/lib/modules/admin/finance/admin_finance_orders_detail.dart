import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:intl/intl.dart';
import '../admin_controller.dart';

class AdminFinanceOrdersDetailScreen extends StatefulWidget {
  final String title;
  final String type; // 'revenue', 'fee', 'refund'

  const AdminFinanceOrdersDetailScreen({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  State<AdminFinanceOrdersDetailScreen> createState() => _AdminFinanceOrdersDetailScreenState();
}

class _AdminFinanceOrdersDetailScreenState extends State<AdminFinanceOrdersDetailScreen> {
  final AdminController controller = Get.find<AdminController>();
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final results = await controller.getRevenueOrders();
    if (mounted) {
      setState(() {
        orders = results;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No completed orders found',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final businessName = order['merchant']?['businessName'] ?? 'Unknown Merchant';
                    final amount = (order['totalAmount'] ?? 0).toDouble();
                    final dateStr = order['deliveredAt'] ?? order['orderedAt'];
                    final date = dateStr != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dateStr))
                        : 'N/A';

                    double displayAmount = amount;
                    String amountPrefix = '₹';
                    Color amountColor = AppColors.primary;

                    if (widget.type == 'fee') {
                      // Show commission share (actual data would be better from backend breakdown)
                      // assuming default 5% based on controller code
                      displayAmount = (amount * 5) / 100;
                      amountColor = Colors.blue;
                    } else if (widget.type == 'refund') {
                      displayAmount = (order['refund']?['amount'] ?? amount).toDouble();
                      amountColor = Colors.red;
                      amountPrefix = '-₹';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                           GBSnack.plain('Order #${order['orderId']}', 'Total: ₹$amount | Status: Delivered');
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: amountColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.type == 'revenue'
                                ? Icons.trending_up
                                : (widget.type == 'fee' ? Icons.pie_chart_outline : Icons.replay),
                            color: amountColor,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Order: #${order['orderId'] ?? 'N/A'}',
                                style: AppTextStyles.labelSmall.copyWith(color: Colors.grey[600])),
                            Text(date, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                          ],
                        ),
                        trailing: Text(
                          '$amountPrefix${displayAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: amountColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
