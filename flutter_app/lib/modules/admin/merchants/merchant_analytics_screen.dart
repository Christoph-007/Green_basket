import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:greenbasket_app/utils/helpers.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import '../admin_controller.dart';


class MerchantAnalyticsScreen extends StatefulWidget {
  const MerchantAnalyticsScreen({super.key});

  @override
  State<MerchantAnalyticsScreen> createState() => _MerchantAnalyticsScreenState();
}

class _MerchantAnalyticsScreenState extends State<MerchantAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = AdminRepository();
  final controller = Get.find<AdminController>();
  late TabController _tabController;
  int _selectedPeriod = 1;
  bool _isLoading = true;

  Map<String, dynamic> _merchant = {};
  Map<String, String> _stats = {};
  List<double> _chartData = [];
  List<String> _chartLabels = [];
  List<Map<String, String>> _topProducts = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isBlocked = false;
  String _merchantId = '';


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _selectedPeriod = 0;
    _tabController.addListener(() {

      if (_tabController.indexIsChanging) return;
      if (_selectedPeriod != _tabController.index) {
        setState(() {
          _selectedPeriod = _tabController.index;
          _isLoading = true;
        });
        _fetchAnalytics(_merchantId);
      }
    });

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _merchant = {
      'name': args['businessName']?.toString() ?? args['name']?.toString() ?? 'Merchant',
      'joinDate': args['createdAt']?.toString().split('T')[0] ?? 'N/A',
      'rating': args['rating']?.toString() ?? '0.0',
    };
    _merchantId = args['_id']?.toString() ?? args['id']?.toString() ?? '';
    _isBlocked = args['isBlocked'] ?? false;
    _fetchAnalytics(_merchantId);

  }

  double _averageRating = 0.0;

  Future<void> _fetchAnalytics(String? merchantId) async {
    try {
      final periods = ['week', 'month', 'year'];
      final res = await _repo.getMerchantAnalytics(merchantId ?? '',
          period: periods[_selectedPeriod]);
      final data = res['data'] as Map<String, dynamic>? ?? res;

      _averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;

      _stats = {
        'revenue': AppHelpers.formatCurrencyFlexible(data['totalRevenue'] ?? data['revenue']),
        'orders': '${data['totalOrders'] ?? data['orders'] ?? 0}',
        'products': '${data['totalProducts'] ?? data['products'] ?? 0}',
        'avgRating': _averageRating.toStringAsFixed(1),
      };

      final salesData = data['salesData'] as List<dynamic>? ?? [];
      _chartData =
          salesData.map((e) => ((e['amount'] ?? e) as num).toDouble()).toList();
      if (_chartData.isNotEmpty) {
        final maxVal = _chartData.reduce((a, b) => a > b ? a : b);
        if (maxVal > 0) _chartData = _chartData.map((v) => v / maxVal).toList();
      }
      _chartLabels =
          salesData.map((e) => e['label']?.toString() ?? '').toList();
      if (_chartLabels.isEmpty) {
        _chartLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      }
      if (_chartData.isEmpty) {
        _chartData = List.filled(_chartLabels.length, 0.0);
      }

      final topP = data['topProducts'] as List<dynamic>? ?? [];
      _topProducts = topP
          .map((p) => {
                'name': p['name']?.toString() ?? '',
                'sales': '${p['soldCount'] ?? p['sales'] ?? 0} sold',
                'revenue': AppHelpers.formatCurrencyFlexible(p['revenue']),
              })
          .toList();

      // Real reviews from backend
      final rev = data['recentReviews'] as List<dynamic>? ?? [];
      _reviews = rev
          .map((r) {
            final customer = r['customer'];
            final authorName = customer is Map
                ? (customer['name']?.toString() ?? 'Customer')
                : 'Customer';
            return {
              'author': authorName,
              'rating': (r['rating'] as num?)?.toInt() ?? 0,
              'comment': r['comment']?.toString() ?? '',
            };
          })
          .toList();
    } catch (_) {
      _stats = {
        'revenue': AppHelpers.formatCurrency(0),
        'orders': '0',
        'products': '0',
        'avgRating': '0.0'
      };
      _chartData = List.filled(7, 0.0);
      _chartLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Merchant Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _showBlockConfirmDialog,
                child: Text(_isBlocked ? 'Unblock Merchant' : 'Block Merchant'),
              ),
            ],
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMerchantHeader(),
            const SizedBox(height: AppSpacing.md),
            _buildStatsGrid(),
            const SizedBox(height: AppSpacing.md),
            _buildPeriodSelector(),
            const SizedBox(height: AppSpacing.md),
            _buildRevenueChart(),
            const SizedBox(height: AppSpacing.md),
            _buildTopProducts(),
            const SizedBox(height: AppSpacing.md),
            _buildReviewsSummary(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.store, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_merchant['name']!, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 2),
                  Text('Joined ${_merchant['joinDate']}', style: AppTextStyles.bodySmall),
                  if (_isBlocked)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text('BLOCKED',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                    ),

                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.secondary, size: 16),
                    const SizedBox(width: 2),
                    Text(_merchant['rating']!, style: AppTextStyles.titleMedium),
                  ],
                ),
                Text('Rating', style: AppTextStyles.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final items = [
      {'label': 'Total Revenue', 'value': _stats['revenue']!, 'icon': Icons.currency_rupee, 'color': AppColors.primary},
      {'label': 'Orders', 'value': _stats['orders']!, 'icon': Icons.shopping_bag_outlined, 'color': AppColors.info},
      {'label': 'Products', 'value': _stats['products']!, 'icon': Icons.inventory_2_outlined, 'color': AppColors.secondary},
      {'label': 'Avg Rating', 'value': _stats['avgRating']!, 'icon': Icons.star_outline, 'color': AppColors.warning},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final color = item['color'] as Color;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(item['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['value'] as String, style: AppTextStyles.titleMedium),
                      Text(item['label'] as String, style: AppTextStyles.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: AppTextStyles.labelLarge,
        tabs: const [
          Tab(text: 'Week'),
          Tab(text: 'Month'),
          Tab(text: 'Year'),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Revenue', style: AppTextStyles.titleLarge),
                Text(
                  ['This Week', 'This Month', 'This Year'][_selectedPeriod],
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_chartData.length, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 100 * _chartData[i],
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.primaryLight, AppColors.primary],
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_chartLabels[i], style: AppTextStyles.labelSmall),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Products', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            ..._topProducts.asMap().entries.map((e) {
              final i = e.key;
              final product = e.value;
              return Column(
                children: [
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product['name']!, style: AppTextStyles.bodyMedium),
                              Text(product['sales']!, style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                        Text(product['revenue']!, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Customer Reviews', style: AppTextStyles.titleLarge),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.secondary, size: 16),
                    const SizedBox(width: 2),
                    Text(_averageRating.toStringAsFixed(1),
                        style: AppTextStyles.titleMedium),
                    Text(' / 5.0', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: Text(
                    'No reviews yet for this merchant.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint),
                  ),
                ),
              )
            else
              ..._reviews.asMap().entries.map((e) {
                final i = e.key;
                final review = e.value;
                final rating = review['rating'] as int;
                return Column(
                  children: [
                    if (i > 0) const Divider(),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primaryContainer,
                                child: Icon(Icons.person_outline,
                                    size: 16, color: AppColors.primary),
                              ),
                              const SizedBox(width: 8),
                              Text(review['author'] as String,
                                  style: AppTextStyles.labelLarge),
                              const Spacer(),
                              Row(
                                children: List.generate(
                                  5,
                                  (s) => Icon(
                                    s < rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: AppColors.secondary,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((review['comment'] as String).isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(review['comment'] as String,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isBlocked ? 'Unblock Merchant?' : 'Block Merchant?'),
        content: Text(_isBlocked
            ? 'Are you sure you want to unblock this merchant? They will immediately regain access to their dashboard and store.'
            : 'Are you sure you want to block this merchant? They will lose access to their dashboard and their store will be hidden.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isBlocked ? AppColors.success : AppColors.error,
            ),
            onPressed: () async {
              try {
                await controller.toggleMerchantBlock(_merchantId);
                setState(() => _isBlocked = !_isBlocked);
                if (ctx.mounted) Navigator.pop(ctx);
                Get.snackbar('Success', _isBlocked ? 'Merchant Blocked' : 'Merchant Unblocked',
                    backgroundColor: _isBlocked ? AppColors.error : AppColors.success,
                    colorText: Colors.white);
              } catch (e) {
                GBSnack.plain('Error', 'Failed to update merchant status');
              }
            },
            child: Text(_isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
  }
}

