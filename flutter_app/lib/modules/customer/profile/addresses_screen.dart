import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/config/routes.dart';
import 'package:greenbasket_app/data/repositories/user_repository.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';

class AddressController extends GetxController {
  final _userRepo = UserRepository();
  final addresses = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    isLoading.value = true;
    try {
      addresses.value = await _userRepo.getAddresses();
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _userRepo.deleteAddress(id);
      addresses.removeWhere((a) => (a['_id'] ?? a['id']) == id);
      Get.snackbar('Success', 'Address deleted successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete address', snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> setAsDefault(String id) async {
    // Current backend might not have a dedicated "setDefault" endpoint, 
    // but we can update the address with isDefault: true.
    try {
      await _userRepo.updateAddress(id, {'isDefault': true});
      fetchAddresses(); // Refresh list to see updated default
    } catch (_) {}
  }
}

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AddressController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text('My Addresses', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => Get.toNamed('${Routes.addresses}/add')?.then((_) => ctrl.fetchAddresses()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return const GBLoader();
        
        final addresses = ctrl.addresses;
        
        if (addresses.isEmpty) {
          return const _EmptyAddresses();
        }
        
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: addresses.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) => _AddressCard(address: addresses[i], controller: ctrl),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('${Routes.addresses}/add')?.then((_) => ctrl.fetchAddresses()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add New Address', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> address;
  final AddressController controller;
  
  const _AddressCard({required this.address, required this.controller});

  @override
  Widget build(BuildContext context) {
    final id = (address['_id'] ?? address['id']).toString();
    final label = address['label'] ?? 'Address';
    final addressLine = address['addressLine1'] ?? address['address'] ?? '';
    final city = address['city'] ?? '';
    final pincode = address['pincode'] ?? '';
    final isDefault = address['isDefault'] ?? false;

    Color labelColor = AppColors.textSecondary;
    Color labelBg = AppColors.surfaceVariant;
    IconData labelIcon = Icons.location_on_rounded;
    
    if (label.toLowerCase() == 'home') {
      labelColor = AppColors.primary;
      labelBg = AppColors.primaryContainer;
      labelIcon = Icons.home_rounded;
    } else if (label.toLowerCase() == 'work') {
      labelColor = AppColors.info;
      labelBg = const Color(0xFFE3F2FD);
      labelIcon = Icons.work_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.border,
          width: isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: labelBg, borderRadius: BorderRadius.circular(AppRadius.full)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(labelIcon, size: 12, color: labelColor),
                    const SizedBox(width: 4),
                    Text(label, style: AppTextStyles.labelSmall.copyWith(color: labelColor)),
                  ],
                ),
              ),
              if (isDefault) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Text('Default', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                ),
              ],
              const Spacer(),
              _IconBtn(
                icon: Icons.edit_outlined,
                color: AppColors.textSecondary,
                onTap: () {
                  Get.toNamed('${Routes.addresses}/edit', arguments: address)?.then((_) => controller.fetchAddresses());
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              _IconBtn(
                icon: Icons.delete_outline_rounded,
                color: AppColors.error,
                onTap: () => _confirmDelete(context, id),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(addressLine, style: AppTextStyles.bodyMedium),
          Text('$city – $pincode', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          if (!isDefault)
            GestureDetector(
              onTap: () => controller.setAsDefault(id),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.radio_button_off_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Set as default', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Delete Address', style: AppTextStyles.titleLarge),
        content: const Text('Are you sure you want to delete this address?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteAddress(id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.location_off_rounded, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('No addresses saved', style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add your delivery addresses for faster checkout',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
