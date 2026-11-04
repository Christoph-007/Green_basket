part of 'admin_offers_screen.dart';

extension _AdminOffersScreenStateSections3 on _AdminOffersScreenState {
  Future<void> _submitCreateOffer({
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required String type,
    required TextEditingController discountPctCtrl,
    required TextEditingController discountAmtCtrl,
    required TextEditingController minOrderCtrl,
    required String applicableOn,
    required TextEditingController couponCtrl,
    required TextEditingController usagePerUserCtrl,
    required DateTime startDate,
    required DateTime endDate,
    required bool isFlashSale,
    required bool isPublic,
  }) async {
    // Validation
    if (titleCtrl.text.trim().isEmpty) {
      GBSnack.error('Error', 'Title is required');
      return;
    }
    if (type == 'percentage' &&
        discountPctCtrl.text.trim().isEmpty) {
      GBSnack.error('Error', 'Discount percentage is required');
      return;
    }
    if ((type == 'flat' || type == 'bundle') &&
        discountAmtCtrl.text.trim().isEmpty) {
      GBSnack.error('Error', 'Discount amount is required');
      return;
    }
    if (endDate.isBefore(startDate)) {
      GBSnack.error('Error', 'End date must be after start date');
      return;
    }

    final body = <String, dynamic>{
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'type': type,
      'applicableOn': applicableOn,
      'minOrderValue':
          double.tryParse(minOrderCtrl.text.trim()) ?? 0,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isFlashSale': isFlashSale,
      'usagePerUser':
          int.tryParse(usagePerUserCtrl.text.trim()) ?? 1,
      'isPublic': isPublic,
    };

    if (type == 'percentage') {
      body['discountPercentage'] =
          double.tryParse(discountPctCtrl.text.trim()) ?? 0;
    }
    if (type == 'flat' || type == 'bundle') {
      body['discountAmount'] =
          double.tryParse(discountAmtCtrl.text.trim()) ?? 0;
    }
    if (couponCtrl.text.trim().isNotEmpty) {
      body['couponCode'] = couponCtrl.text.trim().toUpperCase();
    }

    try {
      await _repo.createOffer(body);
      Navigator.pop(context);
      GBSnack.success('Success', 'Offer created successfully');
      _fetchOffers();
    } catch (e) {
      final msg = e.toString().contains('coupon')
          ? 'Coupon code already exists'
          : 'Failed to create offer';
      GBSnack.error('Error', msg);
    }
  }
}
