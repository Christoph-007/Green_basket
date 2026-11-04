import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/routes.dart';
import 'package:greenbasket_app/config/theme.dart';

class BulkOpsScreen extends StatefulWidget {
  const BulkOpsScreen({super.key});

  @override
  State<BulkOpsScreen> createState() => _BulkOpsScreenState();
}

class _BulkOpsScreenState extends State<BulkOpsScreen> {
  final Map<String, double?> _runningOps = {};

  // Only operations the backend actually supports. Platform-wide product
  // import / price changes / deactivation have no admin API, so they are not
  // offered here (merchants have their own bulk tools).
  final _operations = [
    {
      'id': 'mass_notification',
      'icon': Icons.notifications_outlined,
      'title': 'Send Mass Notification',
      'description': 'Send a notification to all customers or all merchants.',
      'color': AppColors.primary,
      'actionLabel': 'Open',
      'route': Routes.adminNotifications,
    },
    {
      'id': 'generate_reports',
      'icon': Icons.bar_chart,
      'title': 'Financial Reports',
      'description': 'View platform revenue, commission and payout reports.',
      'color': AppColors.primaryDark,
      'actionLabel': 'Open',
      'route': Routes.adminFinance,
    },
  ];

  void _runOperation(String id, String title) {
    final op = _operations.firstWhere((o) => o['id'] == id);
    Get.toNamed(op['route'] as String);
  }

  void _showOperationDialog(Map<String, dynamic> op) {
    final id = op['id'] as String;
    if (op['route'] != null) {
      _runOperation(id, op['title'] as String);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: Row(
          children: [
            Icon(op['icon'] as IconData, color: op['color'] as Color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(op['title'] as String, style: AppTextStyles.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(op['description'] as String, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            if (id == 'export_orders' || id == 'update_prices') ...[
              if (id == 'export_orders') ...[
                const Text('Date Range', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: GBButton(label: 'Start Date', onPressed: () {}, variant: GBButtonVariant.outline),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: GBButton(label: 'End Date', onPressed: () {}, variant: GBButtonVariant.outline),
                    ),
                  ],
                ),
              ],
              if (id == 'update_prices') ...[
                const Text('Price Change', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                const TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Percentage change',
                    suffixText: '%',
                    hintText: 'e.g. 5 for +5%, -5 for -5%',
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This operation cannot be undone. Please ensure you have a backup.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GBButton(label: op['actionLabel'] as String, onPressed: () {
              Navigator.pop(ctx);
              _runOperation(id, op['title'] as String);
            }, backgroundColor: op['color'] as Color),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bulk Operations'),
        leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.85,
          ),
          itemCount: _operations.length,
          itemBuilder: (_, i) => _buildOpCard(_operations[i]),
        ),
      ),
    );
  }

  Widget _buildOpCard(Map<String, dynamic> op) {
    final id = op['id'] as String;
    final color = op['color'] as Color;
    final isRunning = _runningOps.containsKey(id);
    final progress = _runningOps[id]; // null = indeterminate

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(op['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(op['title'] as String, style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                op['description'] as String,
                style: AppTextStyles.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (isRunning) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Running...', style: AppTextStyles.labelSmall.copyWith(color: color)),
                  if (progress != null)
                    Text('${(progress * 100).toInt()}%', style: AppTextStyles.labelSmall.copyWith(color: color)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress, // null = indeterminate
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: GBButton(label: op['actionLabel'] as String, onPressed: () => _showOperationDialog(op), backgroundColor: color),
              ),
          ],
        ),
      ),
    );
  }
}
