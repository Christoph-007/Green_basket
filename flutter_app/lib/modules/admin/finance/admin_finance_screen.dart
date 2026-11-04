import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_card.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_gradient_header.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/widgets/common/gb_stat_card.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'admin_payouts_screen.dart';
import '../widgets/admin_drawer.dart';
import '../admin_controller.dart';
import 'admin_finance_orders_detail.dart';
import 'admin_statement_section.dart';
import 'package:greenbasket_app/widgets/common/gb_line_chart.dart';
import 'package:intl/intl.dart';

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
          GBGradientHeader(
            title: 'Financial Reports',
            trailingIcon: Icons.account_balance_wallet,
            subtitle: Text('Admin › Finance',
                style: AppTextStyles.bodyCompact.copyWith(color: Colors.white.withValues(alpha: 0.9))),
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
                        child: GBStatCard(
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
                        child: GBStatCard(
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
                        child: GBStatCard(
                          title: 'Payouts',
                          value: _money(totalPayouts),
                          icon: Icons.payments_outlined,
                          color: Colors.orange,
                          onTap: () => Get.to(() => const AdminPayoutsScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GBStatCard(
                          title: 'Net Profit',
                          value: _money(netProfit),
                          icon: Icons.account_balance_outlined,
                          color: Colors.purple,
                          onTap: () {
                            GBSnack.plain('Profit Analysis', 'Net profit is total commission earned from delivered orders.');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildTrendSection(controller),
                  const SizedBox(height: 24),
                  AdminStatementSection(controller: controller),
                  const SizedBox(height: 24),
                  // Transaction History
                  Text(
                    'Recent Payout History',
                    style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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

  /// Revenue over time, with the previous period for comparison.
  Widget _buildTrendSection(AdminController controller) {
    return Obx(() {
      final data = controller.revenueTrend;
      final error = controller.trendError.value;
      final current = (data['current'] as List?) ?? const [];
      if (current.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: GBCard.decoration(),
          child: Text(
              error.isEmpty
                  ? 'Revenue trend: no revenue in this period yet.'
                  : "Couldn't load the revenue trend. Make sure the server is updated and restarted.",
              style: AppTextStyles.bodySmall),
        );
      }

      double amount(dynamic row) => ((row as Map)['revenue'] as num?)?.toDouble() ?? 0;
      final values = current.map(amount).toList();
      // Compare like with like: the previous period over the same stretch.
      final previousRows = (data['previous'] as List?) ?? const [];
      final comparison = previousRows.take(current.length).map(amount).toList();

      final period = (data['period'] ?? 'month').toString();
      final byMonth = data['groupBy'] == 'month';
      String label(dynamic row) {
        final raw = ((row as Map)['date'] ?? '').toString();
        final date = DateTime.tryParse(byMonth ? '$raw-01' : raw);
        if (date == null) return raw;
        return DateFormat(byMonth ? 'MMM' : 'd MMM').format(date);
      }

      final totals = (data['totals'] as Map?) ?? const {};
      final total = (totals['currentRevenue'] as num?) ?? 0;
      final change = totals['changePct'] as num?;
      final periodWord = const {'month': 'this month', 'quarter': 'this quarter', 'year': 'this year'}[period] ?? 'this month';
      final previousWord = const {'month': 'last month', 'quarter': 'last quarter', 'year': 'last year'}[period] ?? 'the previous period';

      final summary = change == null
          ? 'Revenue $periodWord: ${AppHelpers.formatCurrency(total)}.'
          : 'Revenue $periodWord: ${AppHelpers.formatCurrency(total)}, '
              '${change >= 0 ? 'up' : 'down'} ${change.abs()}% on $previousWord.';

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: GBCard.decoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Revenue $periodWord',
                      style: AppTextStyles.titleLarge),
                ),
                if (change != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: change >= 0 ? AppColors.primaryContainer : AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: change >= 0 ? AppColors.primary : AppColors.errorStrong,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${change.abs()}%',
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: change >= 0 ? AppColors.primary : AppColors.errorStrong),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(AppHelpers.formatCurrency(total),
                style: AppTextStyles.headlineLarge),
            const SizedBox(height: 12),
            GBLineChart(
              values: values,
              comparison: comparison,
              startLabel: label(current.first),
              endLabel: label(current.last),
              semanticLabel: summary,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 12, height: 3, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Now', style: AppTextStyles.bodySmall),
                const SizedBox(width: 16),
                Container(width: 12, height: 3, color: AppColors.neutralGrey),
                const SizedBox(width: 6),
                Text(previousWord[0].toUpperCase() + previousWord.substring(1),
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ),
      );
    });
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
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: selected == e.key ? AppColors.primary : AppColors.textSecondary),
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
            Icon(Icons.error_outline, size: 48, color: AppColors.errorText),
            const SizedBox(height: 12),
            const Text('Could not load financial data',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(controller.financialError.value,
                textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            GBButton(label: 'Retry', onPressed: () => controller.fetchFinancialReport()),
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
            Icon(Icons.history_toggle_off, size: 48, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text('No payout history available.', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GBCard.decoration(),
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
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.borderLight, height: 1),
                ),
            ],
          );
        }).toList(),
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
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyCompact.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(date, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amount,
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold, color: isCredit ? AppColors.brandForest : AppColors.errorStrong),
              ),
            ],
          ),
        ),
      ),
    );
  }
}