import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import 'package:intl/intl.dart';

part 'admin_offers_screen_sections1.dart';
part 'admin_offers_screen_sections2.dart';
part 'admin_offers_screen_sections3.dart';

class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});

  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen>
    with SingleTickerProviderStateMixin {
  final _repo = AdminRepository();
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _platformOffers = [];
  List<Map<String, dynamic>> _merchantOffers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() => _isLoading = true);
    try {
      final all = await _repo.getOffers();
      final allMaps = all.map((e) => e as Map<String, dynamic>).toList();
      // createdBy == 'admin' → platform-wide; 'merchant' → merchant offers
      _platformOffers =
          allMaps.where((o) => o['createdBy'] == 'admin').toList();
      _merchantOffers =
          allMaps.where((o) => o['createdBy'] != 'admin').toList();
    } catch (e) {
      GBSnack.error('Error', 'Failed to load offers');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ────────────────────────── helpers ──────────────────────────────────────

  // ────────────────────────── build ───────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Offers & Promotions', bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Platform (${_platformOffers.length})'),
            Tab(text: 'Merchant (${_merchantOffers.length})'),
          ],
        ), leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOfferSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Create Offer', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchOffers,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOffersList(_platformOffers),
                  _buildOffersList(_merchantOffers),
                ],
              ),
            ),
    );
  }

  // ────────────────────────── offer card ─────────────────────────────────

  Widget _metaChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      );

  // ────────────────────────── detail bottom sheet ─────────────────────────

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Expanded(
                child: Text(value,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  // ────────────────────────── offer options ───────────────────────────────

  // ────────────────────────── create offer sheet ──────────────────────────

}
