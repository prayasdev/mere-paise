import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_utils.dart';
import '../data/ledger_repository.dart';
import '../data/storage_service.dart';
import '../models/category_item.dart';
import '../models/month_summary.dart';
import '../models/tag_item.dart';
import '../models/transaction_entry.dart';
import '../models/user_settings.dart';

// Storage & Repository singletons
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  throw UnimplementedError('LedgerRepository must be initialized in main');
});

// Settings Provider
class SettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    return ref.watch(ledgerRepositoryProvider).settings;
  }

  void refresh() {
    state = ref.read(ledgerRepositoryProvider).settings;
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    state = newSettings;
    await ref.read(ledgerRepositoryProvider).updateSettings(newSettings);
  }

  Future<void> toggleTheme() async {
    final updated = state.copyWith(isVellumTheme: !state.isVellumTheme);
    await updateSettings(updated);
  }

  Future<void> setWeekStart(int day) async {
    await updateSettings(state.copyWith(weekStartsOn: day));
  }

  Future<void> setMonthStart(int day) async {
    await updateSettings(state.copyWith(monthStartDay: day));
  }

  Future<void> setMonthlyBudget(int? paise) async {
    await updateSettings(state.copyWith(
      monthlyBudgetPaise: paise,
      clearBudget: paise == null,
    ));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);

// Categories Provider
class CategoriesNotifier extends Notifier<List<CategoryItem>> {
  @override
  List<CategoryItem> build() {
    return ref.watch(ledgerRepositoryProvider).categories;
  }

  void refresh() {
    state = ref.read(ledgerRepositoryProvider).categories;
  }

  Future<CategoryItem> addCategory({
    required String name,
    required String kind,
    required String iconName,
    required String colorToken,
  }) async {
    final repo = ref.read(ledgerRepositoryProvider);
    final item = await repo.addCategory(
      name: name,
      kind: kind,
      iconName: iconName,
      colorToken: colorToken,
    );
    state = repo.categories;
    return item;
  }

  Future<void> updateCategory(CategoryItem category) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.updateCategory(category);
    state = repo.categories;
  }

  Future<void> archiveCategory(String categoryId, bool archive) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.archiveCategory(categoryId, archive);
    state = repo.categories;
  }

  Future<void> reorder(String kind, int oldIndex, int newIndex) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.reorderCategories(kind, oldIndex, newIndex);
    state = repo.categories;
  }

  Future<void> deleteCategoryWithReassignment({
    required String categoryIdToDelete,
    required String replacementCategoryId,
    required WidgetRef widgetRef,
  }) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.deleteCategoryWithReassignment(
      categoryIdToDelete: categoryIdToDelete,
      replacementCategoryId: replacementCategoryId,
    );
    state = repo.categories;
    widgetRef.read(transactionsProvider.notifier).refresh();
  }
}

final categoriesProvider = NotifierProvider<CategoriesNotifier, List<CategoryItem>>(CategoriesNotifier.new);

// Tags Provider
class TagsNotifier extends Notifier<List<TagItem>> {
  @override
  List<TagItem> build() {
    return ref.watch(ledgerRepositoryProvider).tags;
  }

  void refresh() {
    state = ref.read(ledgerRepositoryProvider).tags;
  }

  Future<TagItem> getOrCreateTag(String name) async {
    final repo = ref.read(ledgerRepositoryProvider);
    final item = await repo.getOrCreateTag(name);
    state = repo.tags;
    return item;
  }

  Future<void> renameTag(String tagId, String newName) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.renameTag(tagId, newName);
    state = repo.tags;
  }

  Future<void> mergeTags({required String sourceTagId, required String targetTagId, required WidgetRef widgetRef}) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.mergeTags(sourceTagId: sourceTagId, targetTagId: targetTagId);
    state = repo.tags;
    widgetRef.read(transactionsProvider.notifier).refresh();
  }

  Future<void> deleteTag(String tagId, {required WidgetRef widgetRef}) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.deleteTag(tagId);
    state = repo.tags;
    widgetRef.read(transactionsProvider.notifier).refresh();
  }
}

final tagsProvider = NotifierProvider<TagsNotifier, List<TagItem>>(TagsNotifier.new);

// Transactions Provider
class TransactionsNotifier extends Notifier<List<TransactionEntry>> {
  @override
  List<TransactionEntry> build() {
    return ref.watch(ledgerRepositoryProvider).activeTransactions;
  }

  void refresh() {
    state = ref.read(ledgerRepositoryProvider).activeTransactions;
  }

  Future<TransactionEntry> createEntry({
    required String type,
    required int amountPaise,
    required String categoryId,
    String? accountId,
    List<String> tagIds = const [],
    String note = '',
    DateTime? occurredAt,
  }) async {
    final repo = ref.read(ledgerRepositoryProvider);
    final entry = await repo.createTransaction(
      type: type,
      amountPaise: amountPaise,
      categoryId: categoryId,
      accountId: accountId,
      tagIds: tagIds,
      note: note,
      occurredAt: occurredAt,
    );
    refresh();
    return entry;
  }

  Future<void> updateEntry(TransactionEntry updated) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.updateTransaction(updated);
    refresh();
  }

  Future<TransactionEntry?> softDelete(String id) async {
    final repo = ref.read(ledgerRepositoryProvider);
    final deleted = await repo.softDeleteTransaction(id);
    refresh();
    return deleted;
  }

  Future<void> restore(String id) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.restoreTransaction(id);
    refresh();
  }

  Future<void> rebuildSummaries() async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.rebuildSummaries();
    refresh();
  }

  Future<int> importBackup(String content, String fileName) async {
    final repo = ref.read(ledgerRepositoryProvider);
    final count = await repo.importBackupFile(content, fileName);
    refresh();
    ref.read(categoriesProvider.notifier).refresh();
    ref.read(tagsProvider.notifier).refresh();
    ref.read(settingsProvider.notifier).refresh();
    return count;
  }

  Future<void> clearAll() async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.clearAllData();
    refresh();
  }
}

final transactionsProvider = NotifierProvider<TransactionsNotifier, List<TransactionEntry>>(TransactionsNotifier.new);

// Summaries map provider
final summariesProvider = Provider<Map<String, MonthSummary>>((ref) {
  ref.watch(transactionsProvider);
  return ref.watch(ledgerRepositoryProvider).summaries;
});

// Current Month Summary
final currentMonthSummaryProvider = Provider<MonthSummary>((ref) {
  final summaries = ref.watch(summariesProvider);
  final currentKey = LedgerDateUtils.monthKey(DateTime.now());
  return summaries[currentKey] ?? MonthSummary.empty(currentKey);
});

// Ledger Sorting Options
enum LedgerSortOption {
  newestFirst,
  oldestFirst,
  amountHighToLow,
  amountLowToHigh,
}

// Filter State Model
class LedgerFilterState {
  final String? type; // 'expense' or 'income'
  final String? categoryId;
  final String? tagId;
  final DateTimeRange? dateRange;
  final String searchQuery;
  final LedgerSortOption sortOption;

  const LedgerFilterState({
    this.type,
    this.categoryId,
    this.tagId,
    this.dateRange,
    this.searchQuery = '',
    this.sortOption = LedgerSortOption.newestFirst,
  });

  bool get hasActiveFilter =>
      type != null ||
      categoryId != null ||
      tagId != null ||
      dateRange != null ||
      sortOption != LedgerSortOption.newestFirst;

  int get activeFilterCount {
    int count = 0;
    if (type != null) count++;
    if (categoryId != null) count++;
    if (tagId != null) count++;
    if (dateRange != null) count++;
    if (sortOption != LedgerSortOption.newestFirst) count++;
    return count;
  }

  LedgerFilterState copyWith({
    String? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategory = false,
    String? tagId,
    bool clearTag = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? searchQuery,
    LedgerSortOption? sortOption,
  }) {
    return LedgerFilterState(
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      tagId: clearTag ? null : (tagId ?? this.tagId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class LedgerFilterNotifier extends Notifier<LedgerFilterState> {
  @override
  LedgerFilterState build() => const LedgerFilterState();

  void setFilter(LedgerFilterState newState) {
    state = newState;
  }

  void reset() {
    state = const LedgerFilterState();
  }
}

final ledgerFilterProvider = NotifierProvider<LedgerFilterNotifier, LedgerFilterState>(LedgerFilterNotifier.new);

// Filtered Transactions Computed Provider
final filteredTransactionsProvider = Provider<List<TransactionEntry>>((ref) {
  final allTxns = ref.watch(transactionsProvider);
  final filter = ref.watch(ledgerFilterProvider);

  final filtered = allTxns.where((t) {
    // 1. Type
    if (filter.type != null && t.type != filter.type) return false;

    // 2. Category
    if (filter.categoryId != null && t.categoryId != filter.categoryId) return false;

    // 3. Tag
    if (filter.tagId != null && !t.tagIds.contains(filter.tagId)) return false;

    // 4. Date Range
    if (filter.dateRange != null) {
      final start = DateTime(filter.dateRange!.start.year, filter.dateRange!.start.month, filter.dateRange!.start.day);
      final end = DateTime(filter.dateRange!.end.year, filter.dateRange!.end.month, filter.dateRange!.end.day, 23, 59, 59);
      if (t.occurredAt.isBefore(start) || t.occurredAt.isAfter(end)) return false;
    }

    // 5. Search Query
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final matchesNote = t.note.toLowerCase().contains(q);
      final cat = ref.read(categoriesProvider).cast<CategoryItem?>().firstWhere(
        (c) => c?.id == t.categoryId,
        orElse: () => null,
      );
      final matchesCategory = cat?.name.toLowerCase().contains(q) ?? false;
      if (!matchesNote && !matchesCategory) return false;
    }

    return true;
  }).toList();

  // Apply sorting
  switch (filter.sortOption) {
    case LedgerSortOption.newestFirst:
      filtered.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      break;
    case LedgerSortOption.oldestFirst:
      filtered.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      break;
    case LedgerSortOption.amountHighToLow:
      filtered.sort((a, b) => b.amountPaise.compareTo(a.amountPaise));
      break;
    case LedgerSortOption.amountLowToHigh:
      filtered.sort((a, b) => a.amountPaise.compareTo(b.amountPaise));
      break;
  }

  return filtered;
});
