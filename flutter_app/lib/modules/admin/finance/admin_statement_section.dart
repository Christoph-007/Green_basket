import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_filter_chip.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import '../admin_controller.dart';

/// Month-by-month and year-by-year financial statement.
class AdminStatementSection extends StatelessWidget {
  final AdminController controller;
  const AdminStatementSection({super.key, required this.controller});

  static String _money(dynamic v) =>
      AppHelpers.formatCurrency(((v as num?) ?? 0).toDouble());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final st = controller.statement;
      final basis = controller.statementBasis.value;
      final error = controller.statementError.value;
      final loading = controller.isStatementLoading.value;

      final months = ((st['months'] as List?) ?? const [])
          .whereType<Map>()
          .where((m) => m['isFuture'] != true)
          .toList();
      final years = ((st['years'] as List?) ?? const []).whereType<Map>().toList();
      final totals = (st['totals'] as Map?) ?? const {};
      final selected = st['year'];
      final label = (st['label'] ?? '').toString();
      final rate = st['commissionRate'];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Financial Statement',
                    style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              if (loading)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 10),
          // Calendar year / Indian financial year
          Wrap(
            spacing: 8,
            children: [
              _chip('Calendar year', basis == 'calendar', () => controller.fetchStatement(basis: 'calendar')),
              _chip('Financial year (Apr–Mar)', basis == 'fy', () => controller.fetchStatement(basis: 'fy')),
            ],
          ),
          const SizedBox(height: 8),
          if (years.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: years
                    .map((y) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _chip((y['label'] ?? '').toString(), y['year'] == selected,
                              () => controller.fetchStatement(year: y['year'] as int)),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          if (error.isNotEmpty && st.isEmpty)
            _box(Column(children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(height: 6),
              Text(error, textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
              TextButton(onPressed: () => controller.fetchStatement(), child: const Text('Retry')),
            ]))
          else if (st.isNotEmpty) ...[
            // ── Totals for the selected year ──
            _box(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total for $label',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                _kv('Gross revenue', _money(totals['grossRevenue'])),
                _kv('Refunds', '-${_money(totals['refunds'])}'),
                _kv('Net revenue', _money(totals['netRevenue']), bold: true),
                _kv('Platform commission${rate != null ? ' ($rate%)' : ''}', _money(totals['commission'])),
                _kv('Payable to merchants', _money(totals['merchantPayable']), bold: true),
                _kv('Payouts paid', _money(totals['payoutsPaid'])),
                _kv('Payouts pending', _money(totals['payoutsPending'])),
                _kv('Orders', '${totals['orders'] ?? 0}'),
              ],
            )),
            const SizedBox(height: 16),
            Text('Month by month',
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ...months.map((m) => _monthTile(context, m)),
            if (years.length > 1) ...[
              const SizedBox(height: 16),
              Text('Year by year',
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _box(Column(
                children: years.map((y) {
                  return InkWell(
                    onTap: () => controller.fetchStatement(year: y['year'] as int),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text((y['label'] ?? '').toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${y['orders'] ?? 0} orders · Fee ${_money(y['commission'])}',
                                    style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          Text(_money(y['netRevenue']),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )),
            ],
          ] else if (!loading)
            _box(Text('No data yet', style: AppTextStyles.bodySmall)),
        ],
      );
    });
  }

  Widget _monthTile(BuildContext context, Map m) {
    final empty = (m['orders'] ?? 0) == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadowTintLight, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          enabled: !empty,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text((m['name'] ?? '').toString(),
              style: TextStyle(fontWeight: FontWeight.w600, color: empty ? Colors.grey : AppColors.textPrimary)),
          subtitle: Text(empty ? 'No sales' : '${m['orders']} orders · Gross ${_money(m['grossRevenue'])}',
              style: AppTextStyles.bodySmall),
          trailing: Text(empty ? '—' : _money(m['netRevenue']),
              style: TextStyle(fontWeight: FontWeight.bold, color: empty ? Colors.grey : AppColors.primary)),
          children: [
            _kv('Gross revenue', _money(m['grossRevenue'])),
            _kv('Refunds', '-${_money(m['refunds'])}'),
            _kv('Net revenue', _money(m['netRevenue']), bold: true),
            _kv('Platform commission', _money(m['commission'])),
            _kv('Payable to merchants', _money(m['merchantPayable']), bold: true),
            _kv('Payouts paid', _money(m['payoutsPaid'])),
            _kv('Payouts pending', _money(m['payoutsPending'])),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) =>
      GBFilterChip(label: text, selected: selected, onTap: onTap);

  Widget _box(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.shadowTint, blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: child,
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(k, style: AppTextStyles.bodySmall)),
          const SizedBox(width: 12),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
