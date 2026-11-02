import 'package:flutter_test/flutter_test.dart';
import 'package:greenbasket_app/utils/order_status.dart';

void main() {
  group('OrderStatusRules', () {
    test('pickup flow ends with completed and never goes out for delivery', () {
      expect(OrderStatusRules.merchantNextStatus('ready', 'pickup'), 'completed');
      expect(OrderStatusRules.canMerchantTransition('ready', 'out-for-delivery', 'pickup'), isFalse);
      expect(OrderStatusRules.canMerchantTransition('ready', 'completed', 'pickup'), isTrue);
    });

    test('delivery flow must be delivered before completion', () {
      expect(OrderStatusRules.merchantNextStatus('ready', 'home-delivery'), 'out-for-delivery');
      expect(OrderStatusRules.merchantNextStatus('out-for-delivery', 'home-delivery'), 'delivered');
      expect(OrderStatusRules.canMerchantTransition('ready', 'completed', 'home-delivery'), isFalse);
    });

    test('finished and unpaid orders are locked for merchants', () {
      for (final s in ['payment_pending', 'cancelled', 'completed', 'refunded']) {
        expect(OrderStatusRules.merchantNextStatus(s, 'pickup'), isNull, reason: s);
        expect(OrderStatusRules.merchantCanCancel(s), isFalse, reason: s);
      }
      expect(OrderStatusRules.canMerchantTransition('pending', 'delivered', 'home-delivery'), isFalse);
    });

    test('customers can cancel only before preparation starts', () {
      expect(OrderStatusRules.customerCancellable, ['payment_pending', 'pending', 'confirmed']);
      expect(OrderStatusRules.customerCancellable.contains('preparing'), isFalse);
    });

    test('timeline follows the delivery type', () {
      expect(OrderStatusRules.timeline('pickup').last, 'completed');
      expect(OrderStatusRules.timeline('home-delivery'), contains('out-for-delivery'));
    });
  });
}
