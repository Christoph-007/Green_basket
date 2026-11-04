import 'package:intl/intl.dart';

class AppHelpers {
  /// Indian rupee amount with lakh/crore grouping and two decimals:
  /// 1234567 -> ₹12,34,567.00
  static String formatCurrency(num amount, {int decimals = 2}) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: decimals,
    ).format(amount);
  }

  /// Formats a value that may be a number, a numeric string or null
  /// (typical of API maps). null shows ₹0.00; text that is not a number is
  /// shown unchanged after the rupee sign.
  static String formatCurrencyFlexible(Object? value) {
    if (value == null) return formatCurrency(0);
    if (value is num) return formatCurrency(value);
    final text = value.toString().trim();
    final parsed = num.tryParse(text);
    return parsed == null ? '₹$text' : formatCurrency(parsed);
  }

  /// Product price: no decimals for whole amounts (₹49), two decimals
  /// otherwise (₹49.50).
  static String formatPrice(num amount) {
    final whole = amount == amount.truncateToDouble();
    return formatCurrency(amount, decimals: whole ? 0 : 2);
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
