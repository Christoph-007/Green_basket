import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';

class DeliveryZonesScreen extends StatefulWidget {
  const DeliveryZonesScreen({super.key});

  @override
  State<DeliveryZonesScreen> createState() =>
      _DeliveryZonesScreenState();
}

class _DeliveryZonesScreenState extends State<DeliveryZonesScreen> {
  final _repo = MerchantRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _zones = [];

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    try {
      final zones = await _repo.getDeliveryZones();
      setState(() {
        _zones = zones;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleZone(String id, bool active, int index) async {
    try {
      await _repo.toggleZone(id, active);
      setState(() => _zones[index]['active'] = active);
    } catch (_) {
      GBSnack.plain('Error', 'Could not update zone status');
    }
  }

  Future<void> _deleteZone(int index) async {
    final zone = _zones[index];
    final id = zone['_id'] ?? zone['id'] ?? '';
    final name = zone['name'] ?? 'Zone';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Delete Zone', style: AppTextStyles.titleLarge),
        content: Text(
            'Delete "$name"? Customers in this zone won\'t be able to order.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          GBButton(label: 'Delete', onPressed: () => Navigator.pop(ctx, true), backgroundColor: AppColors.error),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (id.isNotEmpty) {
          await _repo.deleteZone(id);
        }
        setState(() => _zones.removeAt(index));
        GBSnack.plain('Deleted', 'Zone removed', position: SnackPosition.BOTTOM);
      } catch (_) {
        GBSnack.plain('Error', 'Could not delete zone');
      }
    }
  }

  /// Delivery zones are measured from the store's map location, so it must
  /// be set (at the store) before zone pricing can apply to customers.
  Future<void> _setStoreLocation() async {
    final confirm = await Get.dialog<bool>(AlertDialog(
      title: const Text('Set store location'),
      content: const Text(
          'Use your current GPS position as the store location? Do this while you are at the store. Delivery zones are measured from this point.'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('Use current location')),
      ],
    ));
    if (confirm != true) return;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        GBSnack.plain('Location needed', 'Allow location access to set the store location');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      await _repo.setStoreLocation(latitude: pos.latitude, longitude: pos.longitude);
      GBSnack.plain('Store location saved', '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}', position: SnackPosition.BOTTOM);
    } catch (e) {
      GBSnack.plain('Error', 'Could not set the store location', position: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Delivery Zones', backIcon: Icons.arrow_back_ios_new, actions: [
          IconButton(
            tooltip: 'Set store location',
            icon: const Icon(Icons.my_location),
            onPressed: _setStoreLocation,
          ),
          IconButton(tooltip: 'Refresh', 
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchZones();
            },
          ),
        ], showDivider: false),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchZones,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map placeholder
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primarySofter,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: const Size(double.infinity, 220),
                            painter: _MapGridPainter(),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.surface.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: AppColors.shadow,
                                          blurRadius: 8)
                                    ],
                                  ),
                                  child: const Icon(Icons.location_on,
                                      color: AppColors.primary, size: 36),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.surface.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.full),
                                  ),
                                  child: Text(
                                    'Zone map visualization',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: AppSpacing.md,
                            right: AppSpacing.md,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${_zones.where((z) => z['active'] == true).length} active zones',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Zones',
                            style: AppTextStyles.titleLarge),
                        Text('${_zones.length} zones',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (_zones.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            'No delivery zones configured.\nTap + Add Zone to get started.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ...List.generate(
                          _zones.length,
                          (i) => _buildZoneCard(_zones[i], i)),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result =
              await Get.toNamed('/merchant/zones/edit');
          if (result == true) _fetchZones();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Zone', style: AppTextStyles.labelLarge),
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone, int index) {
    final id = zone['_id'] ?? zone['id'] ?? '';
    final name = zone['name'] ?? 'Unnamed Zone';
    final radius = (zone['radius'] ?? 0).toDouble();
    final charge = (zone['charge'] ?? zone['deliveryCharge'] ?? 0).toDouble();
    final minOrder =
        (zone['minOrder'] ?? zone['minimumOrder'] ?? 0).toDouble();
    final isActive = zone['active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryContainer
                        : AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.radio_button_checked,
                    color: isActive ? AppColors.primary : AppColors.textHint,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.titleMedium),
                      Text('${radius.toStringAsFixed(1)} km radius',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (v) => _toggleZone(id, v, index),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _zoneInfoItem(
                    Icons.delivery_dining_outlined,
                    'Delivery',
                    '₹${charge.toStringAsFixed(0)}',
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.border),
                Expanded(
                  child: _zoneInfoItem(
                    Icons.shopping_bag_outlined,
                    'Min Order',
                    '₹${minOrder.toStringAsFixed(0)}',
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.border),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(tooltip: 'Edit', 
                        onPressed: () async {
                          final result =
                              await Get.toNamed(
                                  '/merchant/zones/edit',
                                  arguments: zone);
                          if (result == true) _fetchZones();
                        },
                        icon: const Icon(Icons.edit_outlined,
                            size: 20,
                            color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(tooltip: 'Delete', 
                        onPressed: () => _deleteZone(index),
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: AppColors.error),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.labelSmall),
        Text(value,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
}
