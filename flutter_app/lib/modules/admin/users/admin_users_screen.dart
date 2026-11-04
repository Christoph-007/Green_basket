import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_gradient_header.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../admin_controller.dart';
import 'user_detail_screen.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/export_csv_button.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final controller = Get.find<AdminController>();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildAdminHeader(context),
          Expanded(
            child: Obx(() {
              final filteredUsers = controller.users.where((u) {
                final user = u as Map<String, dynamic>;
                final isBlocked = user['isBlocked'] ?? false;
                final status = isBlocked ? 'Blocked' : 'Active';
                bool matchesFilter = _selectedFilter == 'All' || status == _selectedFilter;
                bool matchesSearch = user['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                     user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                return matchesFilter && matchesSearch;
              }).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _buildSearchBar(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ExportCsvButton(
                      path: '/admin/users/export',
                      noun: 'users',
                      params: () => {
                        if (_searchQuery.trim().isNotEmpty) 'search': _searchQuery.trim(),
                        if (_selectedFilter != 'All')
                          'blocked': _selectedFilter == 'Blocked' ? 'true' : 'false',
                      },
                    ),
                  ),
                  Row(
                    children: [
                      _buildPill('All'),
                      const SizedBox(width: 8),
                      _buildPill('Active'),
                      const SizedBox(width: 8),
                      _buildPill('Blocked'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filteredUsers.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('No users found', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ...filteredUsers.map((user) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildUserCard(user as Map<String, dynamic>),
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
    return GBGradientHeader(
      title: 'All Users',
      trailingIcon: Icons.person,
      subtitle: Text('Admin › Users',
          style: AppTextStyles.bodyCompact.copyWith(color: Colors.white.withValues(alpha: 0.9))),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
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
    return Semantics(button: true, child: GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: AnimatedContainer(
        duration: AppMotion.normal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: isActive ? null : Border.all(color: AppColors.borderLight),
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
    ));
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? 'No email';
    final isBlocked = user['isBlocked'] ?? false;
    final color = isBlocked ? AppColors.errorSoft : AppColors.primarySoft;
    final statusColor = isBlocked ? AppColors.errorStrong : AppColors.brandAccent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.to(() => UserDetailScreen(user: user)),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.shadowTint, blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
                alignment: Alignment.center,
                child: Text(name.isNotEmpty ? name[0] : 'U',
                    style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: statusColor)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(email, style: AppTextStyles.bodyCompact.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => controller.toggleUserBlock(user['_id'] ?? user['id']),
                    child: Text(isBlocked ? 'Unblock User' : 'Block User'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}