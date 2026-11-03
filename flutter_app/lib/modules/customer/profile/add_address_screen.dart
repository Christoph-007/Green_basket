import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/models/order_model.dart';
import 'package:greenbasket_app/data/repositories/order_repository.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = OrderRepository();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  String _selectedLabel = 'Home';
  bool _isSaving = false;
  bool _isLocating = false;

  // Filled by "Use current location"; only kept while the address text still matches.
  double? _latitude;
  double? _longitude;
  String _detectedText = '';

  String get _currentText =>
      '${_addressCtrl.text.trim()}|${_cityCtrl.text.trim()}|${_pincodeCtrl.text.trim()}';

  final List<String> _labels = ['Home', 'Work', 'Other'];

  @override
  void dispose() {
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _showLocationError(String message) {
    Get.snackbar('Location unavailable', message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white);
  }

  /// Reads the phone's real GPS position and turns it into an address.
  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showLocationError('Turn on location services and try again.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationError(
            'Location permission is needed. You can allow it in your phone settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      var places = <Placemark>[];
      try {
        places =
            await placemarkFromCoordinates(position.latitude, position.longitude);
      } catch (_) {
        // The position is known but the street lookup failed; the user can type the address.
      }
      if (!mounted) return;

      setState(() {
        if (places.isNotEmpty) {
          final place = places.first;
          final street = [place.street, place.subLocality]
              .where((part) => part != null && part.trim().isNotEmpty)
              .join(', ');
          if (street.isNotEmpty) _addressCtrl.text = street;
          if ((place.locality ?? '').isNotEmpty) _cityCtrl.text = place.locality!;
          if ((place.postalCode ?? '').isNotEmpty) {
            _pincodeCtrl.text = place.postalCode!;
          }
        }
        _latitude = position.latitude;
        _longitude = position.longitude;
        _detectedText = _currentText;
      });
      Get.snackbar(
          'Location Detected',
          places.isEmpty
              ? 'We found where you are but not the street address. Please type it in.'
              : 'Check the details and edit them if needed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white);
    } catch (_) {
      _showLocationError(
          'Could not get your location. Please enter the address yourself.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final address = AddressModel(
        id: '',
        label: _selectedLabel.toLowerCase() == 'work' ? 'office' : _selectedLabel.toLowerCase(),
        line1: _addressCtrl.text.trim(),
        line2: _landmarkCtrl.text.trim().isNotEmpty ? _landmarkCtrl.text.trim() : null,
        city: _cityCtrl.text.trim(),
        state: 'Kerala',
        pincode: _pincodeCtrl.text.trim(),
        isDefault: true,
        // Only send the GPS point if the user did not retype the address afterwards.
        latitude: _currentText == _detectedText ? _latitude : null,
        longitude: _currentText == _detectedText ? _longitude : null,
      );
      await _repo.addAddress(address);
      if (mounted) setState(() => _isSaving = false);
      Get.back(result: true);
      Get.snackbar('Address Saved', 'New address has been added',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white);
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      Get.snackbar('Error', 'Failed to save address. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Add New Address',
            style: AppTextStyles.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map placeholder
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAE6),
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(double.infinity, 200),
                            painter: _GridPainter(),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: AppColors.primary, size: 48),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Tap to set location on map',
                                style: AppTextStyles.bodySmall
                                    .copyWith(
                                        color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Use current location
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isLocating ? null : _useCurrentLocation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                              color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm + 2),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        icon: _isLocating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded,
                                size: 18),
                        label: Text(_isLocating
                            ? 'Detecting location...'
                            : 'Use Current Location'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Address label
                    const Text('Address Label',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: _labels.map((label) {
                        final isSelected = _selectedLabel == label;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedLabel = label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  label == 'Home'
                                      ? Icons.home_rounded
                                      : label == 'Work'
                                          ? Icons.work_rounded
                                          : Icons.location_on_rounded,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: AppTextStyles.labelLarge
                                      .copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Full address
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Full Address',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.location_on_outlined,
                              size: 20),
                        ),
                        hintText:
                            'House/Flat no., Building name, Street',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Address is required'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Landmark
                    TextFormField(
                      controller: _landmarkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Landmark (Optional)',
                        prefixIcon: Icon(Icons.flag_outlined, size: 20),
                        hintText: 'Near school, mall, etc.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // City & Pincode row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon:
                                  Icon(Icons.location_city_outlined,
                                      size: 20),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Pincode',
                              prefixIcon:
                                  Icon(Icons.pin_drop_outlined,
                                      size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              if (v.length != 6) return '6 digits';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // Save button
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 28),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, -2)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Save Address'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
