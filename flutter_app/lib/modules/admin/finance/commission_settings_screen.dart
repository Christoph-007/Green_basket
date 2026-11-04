import 'package:flutter/material.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';

part 'commission_settings_screen_sections.dart';

class CommissionSettingsScreen extends StatefulWidget {
  const CommissionSettingsScreen({super.key});

  @override
  State<CommissionSettingsScreen> createState() =>
      _CommissionSettingsScreenState();
}

class _CommissionSettingsScreenState extends State<CommissionSettingsScreen> {
  final _repo = AdminRepository();

  bool _isLoading = true;
  bool _isSaving = false;

  // Settings from backend
  double _defaultRate = 5;
  double _premiumRate = 3;
  String _payoutSchedule = 'weekly';
  double _minimumPayout = 1000;
  double _maximumPayout = 50000;

  // byCategory: [{category: {_id, name, icon}, rate}]
  List<Map<String, dynamic>> _categoryRates = [];

  // All categories from /categories for the "add" picker
  List<Map<String, dynamic>> _allCategories = [];

  // Financial summary from reports
  Map<String, dynamic> _financialSummary = {};
  List<Map<String, dynamic>> _topMerchants = [];

  // Editing states
  bool _editingDefault = false;
  bool _editingPremium = false;
  final _defaultCtrl = TextEditingController();
  final _premiumCtrl = TextEditingController();
  final _minPayoutCtrl = TextEditingController();
  final _maxPayoutCtrl = TextEditingController();

  final Map<int, TextEditingController> _catCtrlMap = {};
  final Map<int, bool> _catEditingMap = {};

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _defaultCtrl.dispose();
    _premiumCtrl.dispose();
    _minPayoutCtrl.dispose();
    _maxPayoutCtrl.dispose();

    for (final c in _catCtrlMap.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _repo.getCommissionSettings(),
        _repo.getFinancialReports(
            period: 'month', year: now.year, month: now.month),
        _repo.getAllCategories(),
      ]);

      final settings = results[0] as Map<String, dynamic>;
      final reports = results[1] as Map<String, dynamic>;
      final categories = results[2] as List<dynamic>;

      // Parse settings
      final commission =
          settings['commission'] as Map<String, dynamic>? ?? {};
      _defaultRate = ((commission['defaultRate'] ?? 5) as num).toDouble();
      _premiumRate =
          ((commission['premiumMerchantRate'] ?? 3) as num).toDouble();
      _payoutSchedule =
          (settings['payoutSchedule'] ?? 'weekly').toString();
      _minimumPayout =
          ((settings['minimumPayoutAmount'] ?? 1000) as num).toDouble();
      _maximumPayout =
          ((settings['maximumPayoutAmount'] ?? 50000) as num).toDouble();

      _defaultCtrl.text = _defaultRate.toStringAsFixed(1);
      _premiumCtrl.text = _premiumRate.toStringAsFixed(1);
      _minPayoutCtrl.text = _minimumPayout.toStringAsFixed(0);
      _maxPayoutCtrl.text = _maximumPayout.toStringAsFixed(0);

      // Parse byCategory
      final byCategory = commission['byCategory'] as List? ?? [];
      _categoryRates = byCategory.map((e) {
        final item = e as Map<String, dynamic>;
        return {
          'category': item['category'] ?? {},
          'rate': ((item['rate'] ?? 0) as num).toDouble(),
        };
      }).toList();

      // Rebuild controllers
      _catCtrlMap.clear();
      _catEditingMap.clear();
      for (int i = 0; i < _categoryRates.length; i++) {
        _catCtrlMap[i] = TextEditingController(
            text: (_categoryRates[i]['rate'] as double).toStringAsFixed(1));
        _catEditingMap[i] = false;
      }

      // Parse reports
      _financialSummary =
          reports['summary'] as Map<String, dynamic>? ?? {};
      final topRaw = reports['topMerchants'] as List? ?? [];
      _topMerchants =
          topRaw.map((e) => e as Map<String, dynamic>).toList();

      // All categories
      _allCategories =
          categories.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      GBSnack.error('Error', 'Failed to load commission settings');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      // Collect updated category rates
      for (int i = 0; i < _categoryRates.length; i++) {
        final parsed =
            double.tryParse(_catCtrlMap[i]?.text ?? '') ?? _categoryRates[i]['rate'];
        _categoryRates[i]['rate'] = parsed;
        _catEditingMap[i] = false;
      }
      _editingDefault = false;
      _editingPremium = false;

      final defaultRate =
          double.tryParse(_defaultCtrl.text) ?? _defaultRate;
      final premiumRate =
          double.tryParse(_premiumCtrl.text) ?? _premiumRate;
      final minPayout =
          double.tryParse(_minPayoutCtrl.text) ?? _minimumPayout;
      final maxPayout =
          double.tryParse(_maxPayoutCtrl.text) ?? _maximumPayout;

      // Build byCategory payload: [{category: ObjectId, rate: num}]
      final byCategory = _categoryRates.map((cr) {
        final cat = cr['category'] as Map<String, dynamic>? ?? {};
        return {
          'category': cat['_id'] ?? cat['id'] ?? '',
          'rate': cr['rate'],
        };
      }).toList();

      await _repo.updateCommissionSettings({
        'defaultRate': defaultRate,
        'premiumMerchantRate': premiumRate,
        'minimumPayoutAmount': minPayout,
        'maximumPayoutAmount': maxPayout,

        'payoutSchedule': _payoutSchedule,
        'byCategory': byCategory,
      });

      _defaultRate = defaultRate;
      _premiumRate = premiumRate;
      _minimumPayout = minPayout;
      _maximumPayout = maxPayout;

      GBSnack.success('Saved', 'Commission settings updated.');
      setState(() {});
    } catch (e) {
      GBSnack.error('Error', 'Failed to save commission settings');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Commission Settings'),
        leading: IconButton(tooltip: 'Back', 
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRevenueSummary(),
                    const SizedBox(height: AppSpacing.md),
                    _buildDefaultRateSection(),
                    const SizedBox(height: AppSpacing.md),
                    _buildPremiumRateSection(),
                    const SizedBox(height: AppSpacing.md),
                    _buildPayoutSettings(),
                    const SizedBox(height: AppSpacing.md),
                    _buildCategoryRates(),
                    const SizedBox(height: AppSpacing.md),
                    _buildTopMerchants(),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: GBButton(label: 'Save All Changes', isLoading: _isSaving, onPressed: _saveSettings),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Revenue summary ───────────────────────────────────────────────────

  // ── Default rate ──────────────────────────────────────────────────────

  Widget _buildDefaultRateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_outlined,
                    color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text('Global Default Rate',
                    style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This rate applies to all categories unless overridden below.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _editingDefault
                      ? TextField(
                          controller: _defaultCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            suffixText: '%',
                            labelText: 'Default Rate',
                          ),
                          autofocus: true,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_defaultCtrl.text}%',
                              style: AppTextStyles.headlineLarge
                                  .copyWith(color: AppColors.primary),
                            ),
                            Text('Commission on all transactions',
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                ),
                IconButton(tooltip: 'Confirm', 
                  icon: Icon(
                      _editingDefault
                          ? Icons.check
                          : Icons.edit_outlined,
                      color: AppColors.primary),
                  onPressed: () =>
                      setState(() => _editingDefault = !_editingDefault),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Premium rate ──────────────────────────────────────────────────────

  Widget _buildPremiumRateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium,
                    color: AppColors.amberDark),
                const SizedBox(width: AppSpacing.sm),
                const Text('Premium Merchant Rate',
                    style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reduced commission rate for premium/verified merchants.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _editingPremium
                      ? TextField(
                          controller: _premiumCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            suffixText: '%',
                            labelText: 'Premium Rate',
                          ),
                          autofocus: true,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_premiumCtrl.text}%',
                              style: AppTextStyles.headlineLarge
                                  .copyWith(
                                      color: AppColors.amberDark),
                            ),
                            Text('For premium merchants',
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                ),
                IconButton(tooltip: 'Confirm', 
                  icon: Icon(
                      _editingPremium
                          ? Icons.check
                          : Icons.edit_outlined,
                      color: AppColors.amberDark),
                  onPressed: () =>
                      setState(() => _editingPremium = !_editingPremium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Payout settings ───────────────────────────────────────────────────

  Widget _buildPayoutSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.info),
                const SizedBox(width: AppSpacing.sm),
                const Text('Payout Settings',
                    style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Payout schedule
            Row(
              children: [
                Expanded(
                  child: Text('Payout Schedule',
                      style: AppTextStyles.bodyMedium),
                ),
                DropdownButton<String>(
                  value: _payoutSchedule,
                  underline: const SizedBox(),
                  items: ['daily', 'weekly', 'biweekly', 'monthly']
                      .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_scheduleLabel(s),
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.primary))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _payoutSchedule = v);
                  },
                ),
              ],
            ),
            const Divider(),
            // Minimum payout
            Row(
              children: [
                Expanded(
                  child: Text('Minimum Payout Amount',
                      style: AppTextStyles.bodyMedium),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _minPayoutCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: false),
                    decoration: const InputDecoration(
                      prefixText: '₹',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const Divider(),
            // Maximum payout
            Row(
              children: [
                Expanded(
                  child: Text('Maximum Payout Amount',
                      style: AppTextStyles.bodyMedium),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _maxPayoutCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: false),
                    decoration: const InputDecoration(
                      prefixText: '₹',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  // ── Category rates ────────────────────────────────────────────────────

  Widget _buildCategoryRates() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category_outlined,
                    color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                    child: Text('Category-wise Rates',
                        style: AppTextStyles.titleLarge)),
                TextButton.icon(
                  onPressed: _showAddCategorySheet,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_categoryRates.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.category_outlined,
                          size: 40, color: AppColors.textHint),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No category overrides yet.\nAll categories use the default rate (${_defaultCtrl.text}%).',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._categoryRates.asMap().entries.map((e) {
                final i = e.key;
                final cr = e.value;
                final cat =
                    cr['category'] as Map<String, dynamic>? ?? {};
                final catName =
                    (cat['name'] ?? 'Unknown').toString();
                final isEditing = _catEditingMap[i] ?? false;

                return Column(
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Text(_categoryIcon(cat),
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(catName,
                                style: AppTextStyles.bodyMedium),
                          ),
                          if (isEditing)
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _catCtrlMap[i],
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  suffixText: '%',
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                ),
                                autofocus: true,
                              ),
                            )
                          else
                            Text(
                              '${(cr['rate'] as double).toStringAsFixed(1)}%',
                              style: AppTextStyles.titleMedium
                                  .copyWith(color: AppColors.primary),
                            ),
                          IconButton(tooltip: 'Confirm', 
                            icon: Icon(
                              isEditing
                                  ? Icons.check
                                  : Icons.edit_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                if (isEditing) {
                                  cr['rate'] = double.tryParse(
                                          _catCtrlMap[i]?.text ??
                                              '') ??
                                      cr['rate'];
                                }
                                _catEditingMap[i] = !isEditing;
                              });
                            },
                          ),
                          IconButton(tooltip: 'Delete', 
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 18),
                            onPressed: () {
                              setState(() {
                                _categoryRates.removeAt(i);
                                _catCtrlMap.remove(i);
                                _catEditingMap.remove(i);
                                // Re-index
                                _rebuildCatControllers();
                              });
                            },
                          ),
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

  void _showAddCategorySheet() {
    // Filter out already-added categories
    final existingIds = _categoryRates.map((cr) {
      final cat = cr['category'] as Map<String, dynamic>? ?? {};
      return (cat['_id'] ?? cat['id'] ?? '').toString();
    }).toSet();

    final available = _allCategories
        .where((c) =>
            !existingIds.contains((c['_id'] ?? c['id'] ?? '').toString()))
        .toList();

    if (available.isEmpty) {
      GBSnack.info('Info', 'All categories already have overrides.');
      return;
    }

    final rateCtrl = TextEditingController(text: _defaultCtrl.text);
    String? selectedCatId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Add Category Rate Override',
                    style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Category'),
                  items: available.map((c) {
                    final id =
                        (c['_id'] ?? c['id'] ?? '').toString();
                    final name =
                        (c['name'] ?? 'Unknown').toString();
                    return DropdownMenuItem(
                        value: id,
                        child: Text(
                            '${_categoryIcon(c)} $name'));
                  }).toList(),
                  onChanged: (v) =>
                      setSheetState(() => selectedCatId = v),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: rateCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Commission Rate',
                    suffixText: '%',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: GBButton(label: 'Add Override', onPressed: selectedCatId == null
                        ? null
                        : () {
                            final cat = available.firstWhere(
                                (c) =>
                                    (c['_id'] ?? c['id'] ?? '')
                                        .toString() ==
                                    selectedCatId);
                            final rate = double.tryParse(
                                    rateCtrl.text) ??
                                _defaultRate;
                            setState(() {
                              _categoryRates.add({
                                'category': cat,
                                'rate': rate,
                              });
                              final idx =
                                  _categoryRates.length - 1;
                              _catCtrlMap[idx] =
                                  TextEditingController(
                                      text: rate
                                          .toStringAsFixed(1));
                              _catEditingMap[idx] = false;
                            });
                            Navigator.pop(ctx);
                          }),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top merchants ─────────────────────────────────────────────────────

}
