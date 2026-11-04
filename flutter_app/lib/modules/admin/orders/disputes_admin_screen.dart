import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';
import 'package:greenbasket_app/widgets/common/gb_text_field.dart';
import 'package:greenbasket_app/widgets/common/gb_filter_chip.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import 'package:intl/intl.dart';

part 'disputes_admin_screen_sections1.dart';
part 'disputes_admin_screen_sections2.dart';

class DisputesAdminScreen extends StatefulWidget {
  const DisputesAdminScreen({super.key});

  @override
  State<DisputesAdminScreen> createState() => _DisputesAdminScreenState();
}

class _DisputesAdminScreenState extends State<DisputesAdminScreen>
    with SingleTickerProviderStateMixin {
  final _repo = AdminRepository();
  late TabController _tabController;
  String _selectedFilter = 'All';
  bool _isLoading = true;

  // Actual backend categories
  final _filters = [
    'All',
    'damaged_item',
    'wrong_item',
    'missing_item',
    'late_delivery',
    'refund_issue',
  ];

  List<Map<String, dynamic>> _disputes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDisputes();
  }

  Future<void> _fetchDisputes() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getDisputes();
      _disputes = data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      GBSnack.error('Error', 'Failed to load disputes');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- helpers ---------------------------------------------------------------

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- tab mapping -----------------------------------------------------------

  // --- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Disputes', bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'Under Review'),
            Tab(text: 'Resolved'),
          ],
        ), leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        )),
      body: _isLoading
          ? const GBListSkeleton()
          : RefreshIndicator(
              onRefresh: _fetchDisputes,
              child: Column(
                children: [
                  _buildSummaryStats(),
                  _buildFilterChips(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [0, 1, 2].map((tab) {
                        final disputes = _filteredDisputes(tab);
                        return disputes.isEmpty
                            ? const Center(
                                child: Text('No disputes in this category.'))
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.all(AppSpacing.md),
                                itemCount: disputes.length,
                                itemBuilder: (_, i) =>
                                    _buildDisputeCard(disputes[i]),
                              );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- summary stats ---------------------------------------------------------

  Widget _statDivider() =>
      Container(width: 1, height: 36, color: AppColors.border);

  // --- filter chips ----------------------------------------------------------

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final filter = _filters[i];
          final isSelected = _selectedFilter == filter;
          final chipLabel =
              filter == 'All' ? 'All' : _categoryLabel(filter);
          return GBFilterChip(
            label: chipLabel,
            selected: isSelected,
            onTap: () => setState(() => _selectedFilter = filter),
          );
        },
      ),
    );
  }

  // --- dispute card ----------------------------------------------------------

  // --- detail bottom sheet ---------------------------------------------------

  Widget _chip(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(label,
            style: AppTextStyles.labelSmall.copyWith(color: color)),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(t, style: AppTextStyles.titleMedium),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(text, style: AppTextStyles.bodySmall)),
          ],
        ),
      );

  // --- resolve dialog --------------------------------------------------------

}
