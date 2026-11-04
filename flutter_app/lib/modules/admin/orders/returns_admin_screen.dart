import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_text_field.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';

part 'returns_admin_screen_sections1.dart';
part 'returns_admin_screen_sections2.dart';

class ReturnsAdminScreen extends StatefulWidget {
  const ReturnsAdminScreen({super.key});

  @override
  State<ReturnsAdminScreen> createState() => _ReturnsAdminScreenState();
}

class _ReturnsAdminScreenState extends State<ReturnsAdminScreen>
    with SingleTickerProviderStateMixin {
  final _repo = AdminRepository();
  late TabController _tabController;
  final _refundController = TextEditingController();
  bool _approving = true;
  bool _isLoading = true;

  List<Map<String, dynamic>> _returns = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchReturns();
  }

  Future<void> _fetchReturns() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getReturns();
      _returns = data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('fetchReturns error: $e');
      GBSnack.error('Error', 'Failed to load returns');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Returns & Refunds', bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Processing'),
            Tab(text: 'Completed'),
          ],
        ), leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        )),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReturns,
              child: Column(
                children: [
                  _buildStats(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [0, 1, 2].map((tab) {
                        final list = _returns.where((r) => _statusTab(r) == tab).toList();
                        return list.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.assignment_return_outlined, size: 48, color: AppColors.textHint),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'No returns in this category.',
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: list.length,
                                itemBuilder: (_, i) => _buildReturnCard(list[i]),
                              );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

}
