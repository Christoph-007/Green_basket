/// Order status rules — mirrors backend/src/utils/orderStatus.js.
///
///   pickup:        pending → confirmed → preparing → ready → completed
///   home-delivery: pending → confirmed → preparing → ready → out-for-delivery → delivered → completed
class OrderStatusRules {
  static const _merchantTransitions = <String, List<String>>{
    'pending': ['confirmed', 'cancelled'],
    'confirmed': ['preparing', 'ready', 'cancelled'], // 'preparing' is optional
    'preparing': ['ready', 'cancelled'],
    'ready': ['out-for-delivery', 'delivered', 'completed', 'cancelled'],
    'out-for-delivery': ['delivered'],
    'delivered': ['completed'],
  };

  /// Customers may cancel until the merchant starts preparing.
  static const customerCancellable = ['payment_pending', 'pending', 'confirmed'];

  /// Admins may cancel anything not yet handed over.
  static const adminCancellable = [
    'payment_pending',
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'out-for-delivery',
  ];

  static bool isPickup(String deliveryType) => deliveryType == 'pickup';

  static bool canMerchantTransition(String from, String to, String deliveryType) {
    final allowed = _merchantTransitions[from] ?? const [];
    if (!allowed.contains(to)) return false;
    final pickup = isPickup(deliveryType);
    if (pickup && (to == 'out-for-delivery' || to == 'delivered')) return false;
    if (!pickup && from == 'ready' && to == 'completed') return false;
    return true;
  }

  /// The single "next step" a merchant normally takes (null when finished).
  static String? merchantNextStatus(String status, String deliveryType) {
    final pickup = isPickup(deliveryType);
    switch (status) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'preparing';
      case 'preparing':
        return 'ready';
      case 'ready':
        return pickup ? 'completed' : 'out-for-delivery';
      case 'out-for-delivery':
        return 'delivered';
      case 'delivered':
        return 'completed';
      default:
        return null;
    }
  }

  static String? merchantActionLabel(String status, String deliveryType) {
    final pickup = isPickup(deliveryType);
    switch (status) {
      case 'pending':
        return 'Confirm Order';
      case 'confirmed':
        return 'Start Preparing';
      case 'preparing':
        return pickup ? 'Ready for Pick up' : 'Ready for Delivery';
      case 'ready':
        return pickup ? 'Mark Picked Up' : 'Out for Delivery';
      case 'out-for-delivery':
        return 'Mark Delivered';
      case 'delivered':
        return 'Mark Completed';
      default:
        return null;
    }
  }

  static bool merchantCanCancel(String status) =>
      (_merchantTransitions[status] ?? const []).contains('cancelled');

  /// Timeline shown to the customer.
  static List<String> timeline(String deliveryType) => isPickup(deliveryType)
      ? const ['pending', 'confirmed', 'preparing', 'ready', 'completed']
      : const ['pending', 'confirmed', 'preparing', 'out-for-delivery', 'delivered'];
}
