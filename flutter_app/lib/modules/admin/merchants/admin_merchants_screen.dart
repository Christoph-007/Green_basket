import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'merchant_analytics_screen.dart';
import '../widgets/admin_drawer.dart';
import '../admin_controller.dart';

class AdminMerchantsScreen extends StatefulWidget {
  const AdminMerchantsScreen({super.key});

  @override
  State<AdminMerchantsScreen> createState() => _AdminMerchantsScreenState();
}

class _AdminMerchantsScreenState extends State<AdminMerchantsScreen> {
  final controller = Get.find<AdminController>();
  String _selectedFilter = 'All';
  String _searchQuery = '';

String _getMerchantStatus(Map<String, dynamic> merchant) {
    final vStatus = merchant['verificationStatus'];
    if (vStatus == 'approved') return 'Active';
    if (vStatus == 'rejected') return 'Rejected';
    if (vStatus == 'pending' || vStatus == 'under-review') return 'Pending';
    
    if (merchant['status'] != null) {
      final s = merchant['status'].toString().toLowerCase();
      if (s == 'active' || s == 'approved') return 'Active';
      if (s == 'rejected') return 'Rejected';
    }
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F1),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildAdminHeader(context),
          Expanded(
            child: Obx(() {
              final filteredMerchants = controller.merchants.where((m) {
                final merchant = m as Map<String, dynamic>;
                String status = _getMerchantStatus(merchant);
                bool matchesFilter = _selectedFilter == 'All' || status == _selectedFilter;
                bool matchesSearch = merchant['businessName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                     merchant['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                return matchesFilter && matchesSearch;
              }).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPill('All'),
                        const SizedBox(width: 8),
                        _buildPill('Active'),
                        const SizedBox(width: 8),
                        _buildPill('Pending'),
                        const SizedBox(width: 8),
                        _buildPill('Rejected'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredMerchants.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('No merchants found', style: TextStyle(color: AppColors.textHint)),
                      ),
                    )
                  else
                    ...filteredMerchants.map((merchant) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildMerchantCard(merchant as Map<String, dynamic>),
                    )),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A4D2E), Color(0xFF2D7A4A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
                  Builder(builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    );
                  }),
                  const SizedBox(width: 8),
                  const Text('All Merchants',
                      style: TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                ],
              ),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.storefront, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Admin › Merchants',
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF9C9B99), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search merchants...',
                hintStyle: TextStyle(color: Color(0xFF9C9B99), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String title) {
    bool isActive = _selectedFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: isActive ? null : Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantCard(Map<String, dynamic> merchant) {
    final businessName = merchant['businessName'] ?? 'Unknown';
    final email = merchant['email'] ?? 'No email';
    final status = _getMerchantStatus(merchant);
    
    Color color;
    Color statusColor;
    
    switch (status) {
      case 'Active':
        color = const Color(0xFFE8F2EC);
        statusColor = const Color(0xFF1F5C35);
        break;
      case 'Pending':
        color = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFFD97706);
        break;
      default:
        color = const Color(0xFFFEE2E2);
        statusColor = const Color(0xFFDC2626);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
            Get.to(() => const MerchantAnalyticsScreen(), arguments: merchant);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x201F5C35), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Text(businessName.isNotEmpty ? businessName[0] : 'M',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(businessName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                child: Text(status,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
              if (merchant['isStoreOpen'] == false) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('CLOSED',
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}