import 'package:dio/dio.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/return_repository.dart';
import '../../../utils/helpers.dart';

/// Bottom sheet where a customer picks which items of a delivered order to
/// return and says why. Closes with `true` once the server accepted the request.
class ReturnRequestSheet extends StatefulWidget {
  final OrderModel order;
  const ReturnRequestSheet({super.key, required this.order});

  @override
  State<ReturnRequestSheet> createState() => _ReturnRequestSheetState();
}

class _ReturnRequestSheetState extends State<ReturnRequestSheet> {
  final _repo = ReturnRepository();
  final _reasonCtrl = TextEditingController();
  late final List<int> _quantities; // quantity to return per order line (0 = keep it)
  bool _submitting = false;
  String? _error;

  static const List<String> _quickReasons = [
    'Damaged',
    'Not fresh',
    'Wrong item',
    'Missing item',
  ];

  @override
  void initState() {
    super.initState();
    _quantities = List<int>.filled(widget.order.items.length, 0);
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  int get _selectedCount => _quantities.fold(0, (sum, q) => sum + q);

  double get _refundEstimate {
    double total = 0;
    for (var i = 0; i < widget.order.items.length; i++) {
      total += widget.order.items[i].price * _quantities[i];
    }
    return total;
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (_selectedCount == 0) {
      setState(() => _error = 'Select at least one item to return.');
      return;
    }
    if (reason.isEmpty) {
      setState(() => _error = 'Please tell us why you are returning the items.');
      return;
    }

    // One entry per product, even if the order lists it on more than one line.
    final byProduct = <String, int>{};
    for (var i = 0; i < widget.order.items.length; i++) {
      if (_quantities[i] > 0) {
        final id = widget.order.items[i].productId;
        byProduct[id] = (byProduct[id] ?? 0) + _quantities[i];
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repo.requestReturn(
        orderId: widget.order.id,
        reason: reason,
        items: byProduct.entries
            .map((e) => {'productId': e.key, 'quantity': e.value})
            .toList(),
      );
      Get.back(result: true);
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = body is Map ? (body['error'] ?? body['message']) : null;
      if (mounted) {
        setState(() => _error =
            message?.toString() ?? 'Could not reach the server. Please try again.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _itemRow(int index) {
    final item = widget.order.items[index];
    final quantity = _quantities[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.titleMedium),
                Text(
                  '${AppHelpers.formatCurrency(item.price)} • ordered ${item.quantity}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(tooltip: 'Decrease', 
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.primary,
            onPressed: quantity > 0
                ? () => setState(() => _quantities[index] = quantity - 1)
                : null,
          ),
          SizedBox(
            width: 24,
            child: Text('$quantity',
                textAlign: TextAlign.center, style: AppTextStyles.titleMedium),
          ),
          IconButton(tooltip: 'Increase', 
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
            onPressed: quantity < item.quantity
                ? () => setState(() => _quantities[index] = quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Return items', style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Order ${widget.order.orderNumber} • refunds go to your wallet once approved',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < widget.order.items.length; i++) _itemRow(i),
              const Divider(height: 24),
              const Text('Why are you returning them?',
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final reason in _quickReasons)
                    ActionChip(
                      label: Text(reason),
                      onPressed: () => setState(() => _reasonCtrl.text = reason),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonCtrl,
                maxLines: 2,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Tell us what went wrong',
                ),
              ),
              if (_selectedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Estimated refund: ${AppHelpers.formatCurrency(_refundEstimate)}',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error)),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: GBButton(label: 'Submit return request', isLoading: _submitting, onPressed: _submit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
