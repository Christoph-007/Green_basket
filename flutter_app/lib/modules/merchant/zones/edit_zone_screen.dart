import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';

class EditZoneScreen extends StatefulWidget {
  const EditZoneScreen({super.key});

  @override
  State<EditZoneScreen> createState() => _EditZoneScreenState();
}

class _EditZoneScreenState extends State<EditZoneScreen> {
  final _repo = MerchantRepository();
  late final bool _isEditing;
  late final String? _zoneId;
  late final TextEditingController _nameController;
  late final TextEditingController _chargeController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _estTimeController;
  double _radius = 5.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _isEditing = args != null;
    _zoneId = args?['_id'] as String? ?? args?['id'] as String?;

    _nameController =
        TextEditingController(text: args?['name'] as String? ?? '');

    final charge = args?['charge'] ?? args?['deliveryCharge'];
    _chargeController = TextEditingController(
        text: charge != null
            ? (charge as num).toStringAsFixed(0)
            : '');

    final minOrder = args?['minOrder'] ?? args?['minimumOrder'];
    _minOrderController = TextEditingController(
        text: minOrder != null
            ? (minOrder as num).toStringAsFixed(0)
            : '');

    final estTime = args?['estimatedTime'] ?? args?['deliveryTime'];
    _estTimeController = TextEditingController(
        text: estTime != null ? estTime.toString() : '45');

    _radius = (args?['radius'] as num?)?.toDouble() ?? 5.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _chargeController.dispose();
    _minOrderController.dispose();
    _estTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveZone() async {
    if (_nameController.text.trim().isEmpty) {
      GBSnack.plain('Validation', 'Please enter a zone name', position: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final payload = {
        'name': _nameController.text.trim(),
        'radius': _radius,
        'charge': double.tryParse(_chargeController.text.trim()) ?? 0,
        'deliveryCharge':
            double.tryParse(_chargeController.text.trim()) ?? 0,
        'minOrder': double.tryParse(_minOrderController.text.trim()) ?? 0,
        'estimatedTime':
            int.tryParse(_estTimeController.text.trim()) ?? 45,
        'active': true,
      };
      if (_isEditing && _zoneId != null) {
        await _repo.updateZone(_zoneId, payload);
      } else {
        await _repo.createZone(payload);
      }
      Get.back(result: true);
      GBSnack.success(_isEditing ? 'Zone Updated' : 'Zone Created', _isEditing
            ? 'Delivery zone saved successfully'
            : 'New delivery zone added', position: SnackPosition.BOTTOM);
    } catch (_) {
      GBSnack.plain('Error', 'Could not save zone. Please try again.', position: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: _isEditing ? 'Edit Zone' : 'Add Zone', leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        )),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone name
            _buildTextField(
              controller: _nameController,
              label: 'Zone Name',
              hint: 'e.g. Central Zone',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Radius slider
            Text('Delivery Radius', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 km', style: AppTextStyles.bodySmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${_radius.toStringAsFixed(1)} km',
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                      Text('20 km', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  Slider(
                    value: _radius,
                    min: 1.0,
                    max: 20.0,
                    divisions: 38,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  // Visual circle indicator
                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: CustomPaint(
                      size: const Size(200, 120),
                      painter: _ZoneRadiusPainter(
                          radius: _radius, maxRadius: 20),
                    ),
                  ),
                  Text(
                    'Coverage: ${(_radius * _radius * 3.14159).toStringAsFixed(1)} km²',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Pricing
            Text('Pricing', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _chargeController,
                    label: 'Delivery Charge (₹)',
                    hint: '40',
                    keyboardType: TextInputType.number,
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildTextField(
                    controller: _minOrderController,
                    label: 'Minimum Order (₹)',
                    hint: '200',
                    keyboardType: TextInputType.number,
                    prefixText: '₹ ',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _estTimeController,
              label: 'Estimated Delivery Time (minutes)',
              hint: '45',
              keyboardType: TextInputType.number,
              suffixText: 'min',
            ),
            const SizedBox(height: AppSpacing.md),

            // Free delivery threshold hint
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Tip: Set a competitive delivery charge for this radius to increase orders from this zone.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: GBButton(label: _isEditing ? 'Save Zone' : 'Create Zone', isLoading: _isSaving, onPressed: _saveZone),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? prefixText,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        suffixText: suffixText,
      ),
    );
  }
}

class _ZoneRadiusPainter extends CustomPainter {
  final double radius;
  final double maxRadius;

  const _ZoneRadiusPainter({required this.radius, required this.maxRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final normalizedRadius =
        (radius / maxRadius) * (size.height * 0.42);

    // Outer circle (coverage area)
    final bgPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, normalizedRadius, bgPaint);

    final borderPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, normalizedRadius, borderPaint);

    // Center dot
    final centerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, centerPaint);

    // Radius line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        center, center.translate(normalizedRadius, 0), linePaint);
  }

  @override
  bool shouldRepaint(_ZoneRadiusPainter old) => old.radius != radius;
}
