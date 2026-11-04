import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'admin_payouts_screen.dart';
import '../widgets/admin_drawer.dart';
import '../admin_controller.dart';
import 'admin_finance_orders_detail.dart';
import 'admin_statement_section.dart';

class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

  static String _money(String raw) => AppHelpers.formatCurrencyFlexible(raw);

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.brandDeep, AppColors.brandDeepLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Financial Reports',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Overview of total revenue, fees, and payouts',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Obx(() {
              if (controller.isFinanceLoading.value && controller.financialReport.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.financialError.value.isNotEmpty && controller.financialReport.isEmpty) {
                return _buildError(controller);
              }

              final report = controller.financialReport;
              final summary = report['summary'] as Map<String, dynamic>? ?? {};
              
              final totalRevenue = (summary['totalGrossRevenue'] ?? 0).toString();
              final platformFee = (summary['totalCommissionEarned'] ?? 0).toString();
              final totalPayouts = (summary['payoutsPaid'] ?? 0).toString();
              // Total Commission earned is effectively the platform's profit before operating costs
              final netProfit = (summary['totalCommissionEarned'] ?? 0).toString();

              return RefreshIndicator(
                onRefresh: () => Future.wait([
                  controller.fetchFinancialReport(),
                  controller.fetchStatement(),
                ]),
                child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _buildPeriodChips(controller),
                  const SizedBox(height: 16),
                  // KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Total Revenue',
                          value: _money(totalRevenue),
                          icon: Icons.trending_up,
                          color: AppColors.brandAccent,
                          onTap: () {
                             Get.to(() => const AdminFinanceOrdersDetailScreen(
                                title: 'Total Revenue Orders',
                                type: 'revenue',
                             ));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Platform Fee',
                          value: _money(platformFee),
                          icon: Icons.pie_chart_outline,
                          color: Colors.blue,
                          onTap: () {
                             Get.to(() => const AdminFinanceOrdersDetailScreen(
                                title: 'Platform Commission Detail',
                                type: 'fee',
                             ));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Payouts',
                          value: _money(totalPayouts),
                          icon: Icons.payments_outlined,
                          color: Colors.orange,
                          onTap: () => Get.to(() => const AdminPayoutsScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Net Profit',
                          value: _money(netProfit),
                          icon: Icons.account_balance_outlined,
                          color: Colors.purple,
                          onTap: () {
                            Get.snackbar('Profit Analysis', 'Net profit is total commission earned from delivered orders.');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  AdminStatementSection(controller: controller),
                  const SizedBox(height: 24),
                  // Transaction History
                  const Text(
                    'Recent Payout History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPayoutHistory(controller),
                  const SizedBox(height: 48),
                ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChips(AdminController controller) {
    const periods = {
      'all': 'All time',
      'month': 'This month',
      'quarter': 'This quarter',
      'year': 'This year',
    };
    final selected = controller.financialPeriod.value;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected == e.key,
              selectedColor: AppColors.primary.withOpacity(0.15),
              labelStyle: TextStyle(
                color: selected == e.key ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              onSelected: (_) => controller.fetchFinancialReport(period: e.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError(AdminController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('Could not load financial data',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(controller.financialError.value,
                textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.fetchFinancialReport(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutHistory(AdminController controller) {
    final completedPayouts = controller.recentPayouts.take(5).toList();
    
    if (completedPayouts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('No payout history available.', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowTint,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: completedPayouts.map((p) {
          final name = p['merchant']?['businessName'] ?? p['merchant']?['name'] ?? p['agent']?['name'] ?? 'Unknown';
          final amount = (p['netAmount'] ?? p['amount'] ?? 0).toString();
          final date = p['updatedAt']?.toString().split('T')[0] ?? 'N/A';
          return Column(
            children: [
              _buildTransactionRow('Payout to $name', '-${_money(amount)}', date, isCredit: false, onTap: () {
                Get.to(() => const AdminPayoutsScreen());
              }),
              if (p != completedPayouts.last)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.borderLight, height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowTint,
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(String title, String amount, String date, {required bool isCredit, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCredit ? AppColors.brandForest : AppColors.errorStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}