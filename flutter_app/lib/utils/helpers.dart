import 'package:intl/intl.dart';

class AppHelpers {
  static String formatCurrency(double amount) {
    return '₹${NumberFormat('#,##0.00').format(amount)}';
  }


  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String getOrderStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'dispatched':
      case 'out-for-delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'payment_pending':
        return 'Awaiting Payment';
      case 'refunded':
        return 'Refunded';

      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static String getLoyaltyTierLabel(String tier) {
    switch (tier) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      default:
        return tier;
    }
  }

  static String getPaymentMethodLabel(String method) {
    switch (method) {
      case 'razorpay':
        return 'Credit/Debit Card (Razorpay)';
      case 'cod':
        return 'Cash on Delivery';
      case 'wallet':
        return 'GreenBasket Wallet';
      case 'phonepe':
        return 'PhonePe';
      default:
        return method;
    }
  }
}
