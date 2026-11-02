import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'financial_controller.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FinancialController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FinancialController());
    _tabController = TabController(
        length: controller.periodLabels.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        controller.changePeriod(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              Get.snackbar('Downloading', 'Report is being generated...',
                  snackPosition: SnackPosition.BOTTOM);
            },
            tooltip: 'Download Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTextStyles.labelSmall,
          unselectedLabelStyle: AppTextStyles.labelSmall,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: false,
          tabs: controller.periodLabels
              .map((p) => Tab(text: p))
              .toList(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.5,
                children: [
                  _statCard(
                    'Gross Sales',
                    _formatAmount(controller.grossSales.value),
                    Icons.trending_up_rounded,
                    AppColors.primary,
                  ),
                  _statCard(
                    'Net Earnings',
                    _formatAmount(controller.netEarnings.value),
                    Icons.account_balance_wallet_outlined,
                    AppColors.success,
                  ),
                  _statCard(
                    'Platform Fee',
                    _formatAmount(controller.commission.value),
                    Icons.percent_rounded,
                    AppColors.secondary,
                  ),
                  _statCard(
                    'Pending Payout',
                    _formatAmount(controller.pendingPayout.value),
                    Icons.schedule_outlined,
                    AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Chart
              Text('Earnings Trend', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.md),
              if (controller.chartValues.isNotEmpty)
                _buildLineChart(controller.chartValues)
              else
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('No chart data available',
                        style: AppTextStyles.bodyMedium),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Transactions', style: AppTextStyles.titleLarge),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (controller.transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('No transactions found',
                        style: AppTextStyles.bodyMedium),
                  ),
                )
              else ...[
                _buildTransactionHeader(),
                ...controller.transactions.map(_buildTransactionRow),
              ],
              const SizedBox(height: AppSpacing.md),

              // Download button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Download Report'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      }),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Text(value,
              style: AppTextStyles.headlineMedium
                  .copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<double> values) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 120),
        painter: _LineChartPainter(values: values),
      ),
    );
  }

  Widget _buildTransactionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.md)),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('Order ID',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primaryDark))),
          Expanded(
              flex: 2,
              child: Text('Date',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primaryDark))),
          Expanded(
              child: Text('Amount',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primaryDark),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text('Fee',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primaryDark),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text('Net',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primaryDark),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> t) {
    final amount = (t['amount'] ?? t['grossAmount'] ?? 0).toDouble();
    final fee = (t['commission'] ?? t['fee'] ?? 0).toDouble();
    final net = (t['net'] ?? t['netAmount'] ?? (amount - fee)).toDouble();
    final orderId = t['orderId'] ?? t['orderNumber'] ?? t['_id'] ?? '-';
    final date = t['date'] ?? t['createdAt'] ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('#$orderId',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500))),
          Expanded(
              flex: 2,
              child: Text('$date',
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              child: Text('₹${amount.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text('-₹${fee.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text('₹${net.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  const _LineChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.3),
          AppColors.primary.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final n = values.length;
    final step = size.width / (n - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < n; i++) {
      final x = i * step;
      final y = size.height - (values[i] * size.height * 0.9);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((n - 1) * step, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < n; i++) {
      final x = i * step;
      final y = size.height - (values[i] * size.height * 0.9);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.values != values;
}
