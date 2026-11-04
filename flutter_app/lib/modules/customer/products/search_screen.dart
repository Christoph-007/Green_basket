import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../../widgets/cards/product_card.dart';
import '../../../widgets/common/gb_loader.dart';
import '../../../widgets/common/empty_state.dart';
import '../cart/cart_controller.dart';

class SearchController2 extends GetxController {
  final _repo = ProductRepository();
  final _storage = StorageService();

  final results = <ProductModel>[].obs;
  final isLoading = false.obs;
  final query = ''.obs;
  final error = ''.obs;

  /// Words that complete what the user is typing.
  final suggestions = <String>[].obs;

  /// What other people are buying now (shown while the field is empty).
  final trending = <String>[].obs;

  /// The user's last searches, newest first.
  final recent = <String>[].obs;

  /// Filters applied on the results already loaded.
  final sortBy = 'relevance'.obs; // relevance | price_asc | price_desc
  final organicOnly = false.obs;

  Timer? _debounce;
  int _ticket = 0;

  @override
  void onInit() {
    super.onInit();
    recent.value = _storage.recentSearches;
    _loadTrending();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  /// Results after the filters and the sort order.
  List<ProductModel> get visibleResults {
    var list = results.toList();
    if (organicOnly.value) {
      list = list.where((p) => p.isOrganic).toList();
    }
    if (sortBy.value == 'price_asc') {
      list.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
    } else if (sortBy.value == 'price_desc') {
      list.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
    }
    return list;
  }

  void toggleSort(String value) {
    sortBy.value = sortBy.value == value ? 'relevance' : value;
  }

  /// Called on every keystroke. Waits for a short pause so a fast typist
  /// sends one request, not one per letter.
  void onTextChanged(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      clearQuery();
      return;
    }
    query.value = trimmed;
    error.value = '';
    isLoading.value = true;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      search(trimmed);
      _loadSuggestions(trimmed);
    });
  }

  /// The keyboard Search button or a tapped suggestion: search now and
  /// remember the words.
  void submit(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _storage.addRecentSearch(trimmed);
    recent.value = _storage.recentSearches;
    query.value = trimmed;
    search(trimmed);
    _loadSuggestions(trimmed);
  }

  Future<void> search(String q) async {
    final text = q.trim();
    if (text.isEmpty) {
      clearQuery();
      return;
    }
    query.value = text;
    error.value = '';
    isLoading.value = true;
    final ticket = ++_ticket;
    try {
      final found = await _repo.search(text);
      if (ticket != _ticket) return; // a newer search has started
      results.value = found;
    } catch (_) {
      if (ticket != _ticket) return;
      results.clear();
      error.value =
          'We could not load results. Check your connection and try again.';
    }
    if (ticket == _ticket) isLoading.value = false;
  }

  Future<void> _loadSuggestions(String text) async {
    if (text.length < 2) {
      suggestions.clear();
      return;
    }
    try {
      final found = await _repo.getSearchSuggestions(text);
      if (query.value == text) suggestions.value = found;
    } catch (_) {
      // Suggestions are a nicety; the search itself still works.
    }
  }

  Future<void> _loadTrending() async {
    try {
      trending.value = await _repo.getTrendingSearches();
    } catch (_) {
      // Trending is optional.
    }
  }

  void clearRecent() {
    _storage.clearRecentSearches();
    recent.clear();
  }

  void clearQuery() {
    _debounce?.cancel();
    _ticket++; // ignore any request still on its way
    results.clear();
    suggestions.clear();
    query.value = '';
    error.value = '';
    isLoading.value = false;
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = Get.put(SearchController2());
  final _cartCtrl = Get.find<CartController>();
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  /// Puts a suggested or remembered word in the field and searches for it.
  void _useTerm(String term) {
    _textCtrl.text = term;
    _textCtrl.selection = TextSelection.collapsed(offset: term.length);
    _ctrl.submit(term);
    FocusScope.of(context).unfocus();
  }

  void _clearAll() {
    _textCtrl.clear();
    _ctrl.clearQuery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _textCtrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search products, categories...',
            hintStyle: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textHint),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
            suffixIcon: IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: _clearAll,
            ),
          ),
          onChanged: _ctrl.onTextChanged,
          onSubmitted: _ctrl.submit,
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Obx(() {
        if (_ctrl.query.value.isEmpty) return _buildIdle();
        return Column(
          children: [
            _buildSuggestions(),
            _buildFilters(),
            Expanded(child: _buildResults()),
          ],
        );
      }),
    );
  }

  /// Shown while the field is empty: recent searches and trending words.
  Widget _buildIdle() {
    final recent = _ctrl.recent;
    final trending = _ctrl.trending;
    if (recent.isEmpty && trending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'Search for fresh produce',
              style: AppTextStyles.headlineMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent searches', style: AppTextStyles.titleLarge),
              TextButton(
                onPressed: _ctrl.clearRecent,
                child: const Text('Clear'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in recent)
                ActionChip(
                  avatar: const Icon(Icons.history,
                      size: 16, color: AppColors.textSecondary),
                  label: Text(term, style: AppTextStyles.bodySmall),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () => _useTerm(term),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (trending.isNotEmpty) ...[
          const Text('Popular right now', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in trending)
                ActionChip(
                  avatar: const Icon(Icons.trending_up,
                      size: 16, color: AppColors.primary),
                  label: Text(term, style: AppTextStyles.bodySmall),
                  backgroundColor: AppColors.primaryContainer,
                  side: BorderSide.none,
                  onPressed: () => _useTerm(term),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestions() {
    final list = _ctrl.suggestions;
    if (list.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(list[i], style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          onPressed: () => _useTerm(list[i]),
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.primaryContainer,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      labelStyle: AppTextStyles.labelSmall.copyWith(
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildFilters() {
    final sort = _ctrl.sortBy.value;
    final organic = _ctrl.organicOnly.value;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _filterChip('Price: low to high', sort == 'price_asc',
              () => _ctrl.toggleSort('price_asc')),
          const SizedBox(width: 8),
          _filterChip('Price: high to low', sort == 'price_desc',
              () => _ctrl.toggleSort('price_desc')),
          const SizedBox(width: 8),
          _filterChip('Organic', organic,
              () => _ctrl.organicOnly.value = !_ctrl.organicOnly.value),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_ctrl.isLoading.value) return const GBLoader();
    if (_ctrl.error.value.isNotEmpty) {
      return ErrorState(
        message: _ctrl.error.value,
        onRetry: () => _ctrl.search(_ctrl.query.value),
      );
    }
    final list = _ctrl.visibleResults;
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: 'No results for "${_ctrl.query.value}"',
        message: _ctrl.results.isEmpty
            ? 'Try a simpler word or browse a category'
            : 'Try removing a filter',
        actionLabel: 'Clear Search',
        onAction: _clearAll,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final product = list[i];
        return ProductCard(
          product: product,
          onAddToCart: (prepId) => _cartCtrl.addItem(
              productId: product.id,
              quantity: 1,
              preparationOption: prepId),
        );
      },
    );
  }
}
