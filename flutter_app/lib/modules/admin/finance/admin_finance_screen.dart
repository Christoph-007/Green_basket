import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'admin_payouts_screen.dart';
import '../widgets/admin_drawer.dart';
import '../admin_controller.dart';
import 'admin_finance_orders_detail.dart';

class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
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
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
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
              if (controller.isLoading.value && (controller.financialReport.isEmpty)) {
                return const Center(child: CircularProgressIndicator());
              }

              final report = controller.financialReport;
              final summary = report['summary'] as Map<String, dynamic>? ?? {};
              
              final totalRevenue = (summary['totalGrossRevenue'] ?? 0).toString();
              final platformFee = (summary['totalCommissionEarned'] ?? 0).toString();
              final totalPayouts = (summary['payoutsPaid'] ?? 0).toString();
              // Total Commission earned is effectively the platform's profit before operating costs
              final netProfit = (summary['totalCommissionEarned'] ?? 0).toString();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Total Rev',
                          value: '₹$totalRevenue',
                          icon: Icons.trending_up,
                          color: const Color(0xFF1F5C35),
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
                          value: '₹$platformFee',
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
                          value: '₹$totalPayouts',
                          icon: Icons.payments_outlined,
                          color: Colors.orange,
                          onTap: () => Get.to(() => const AdminPayoutsScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Net Profit',
                          value: '₹$netProfit',
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

                  // Transaction History
                  const Text(
                    'Recent Payout History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPayoutHistory(controller),
                  const SizedBox(height: 48),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutHistory(AdminController controller) {
    final completedPayouts = controller.payouts.where((p) => p['status'] == 'Completed').take(5).toList();
    
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
            color: Color(0x201F5C35),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: completedPayouts.map((p) {
          final name = p['merchant']?['name'] ?? p['agent']?['name'] ?? 'Unknown';
          final amount = p['amount']?.toString() ?? '0';
          final date = p['updatedAt']?.toString().split('T')[0] ?? 'N/A';
          return Column(
            children: [
              _buildTransactionRow('Payout to $name', '-₹$amount', date, isCredit: false, onTap: () {
                Get.to(() => const AdminPayoutsScreen());
              }),
              if (p != completedPayouts.last)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFFE8E8E8), height: 1),
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
                color: Color(0x201F5C35),
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
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9C9B99), fontWeight: FontWeight.w500),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF9C9B99))),
                ],
              ),
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCredit ? const Color(0xFF1A4D2E) : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}