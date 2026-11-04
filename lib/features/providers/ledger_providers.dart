import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_utils.dart';
import '../auth/auth_service.dart';
import '../data/firestore_sync_service.dart';
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

// Auth & Firestore Sync providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final repo = ref.watch(ledgerRepositoryProvider);
  final syncService = FirestoreSyncService(repo);
  syncService.init();
  ref.onDispose(() => syncService.dispose());
  return syncService;
});

// Settings Provider
class SettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    return ref.watch(ledgerRepositoryProvider).settings;
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

// Sort options for Ledger
enum LedgerSortOption {
  newestFirst,
  oldestFirst,
  amountHighToLow,
  amountLowToHigh,
}

// Filter state for Ledger screen
class LedgerFilterState {
  final String searchQuery;
  final String? type;
  final String? categoryId;
  final String? tagId;
  final DateTimeRange? dateRange;
  final LedgerSortOption sortOption;

  const LedgerFilterState({
    this.searchQuery = '',
    this.type,
    this.categoryId,
    this.tagId,
    this.dateRange,
    this.sortOption = LedgerSortOption.newestFirst,
  });

  bool get hasActiveFilter =>
      searchQuery.isNotEmpty ||
      type != null ||
      categoryId != null ||
      tagId != null ||
      dateRange != null ||
      sortOption != LedgerSortOption.newestFirst;

  int get activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (type != null) count++;
    if (categoryId != null) count++;
    if (tagId != null) count++;
    if (dateRange != null) count++;
    if (sortOption != LedgerSortOption.newestFirst) count++;
    return count;
  }

  LedgerFilterState copyWith({
    String? searchQuery,
    String? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategory = false,
    String? tagId,
    bool clearTag = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    LedgerSortOption? sortOption,
  }) {
    return LedgerFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      tagId: clearTag ? null : (tagId ?? this.tagId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class LedgerFilterNotifier extends Notifier<LedgerFilterState> {
  @override
  LedgerFilterState build() => const LedgerFilterState();

  void setFilter(LedgerFilterState filter) => state = filter;
  void update(LedgerFilterState Function(LedgerFilterState) updater) => state = updater(state);
}

final ledgerFilterProvider = NotifierProvider<LedgerFilterNotifier, LedgerFilterState>(LedgerFilterNotifier.new);

// Filtered Transactions
final filteredTransactionsProvider = Provider<List<TransactionEntry>>((ref) {
  final list = ref.watch(transactionsProvider);
  final filter = ref.watch(ledgerFilterProvider);

  final filtered = list.where((t) {
    if (filter.type != null && t.type != filter.type) return false;
    if (filter.categoryId != null && t.categoryId != filter.categoryId) return false;
    if (filter.tagId != null && !t.tagIds.contains(filter.tagId)) return false;
    if (filter.dateRange != null) {
      final occurred = t.occurredAt;
      final start = filter.dateRange!.start;
      final end = filter.dateRange!.end.add(const Duration(days: 1));
      if (occurred.isBefore(start) || occurred.isAfter(end)) return false;
    }
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final matchesNote = t.note.toLowerCase().contains(q);
      final categories = ref.watch(categoriesProvider);
      final catName = categories.cast<CategoryItem?>().firstWhere(
        (c) => c?.id == t.categoryId,
        orElse: () => null,
      )?.name.toLowerCase() ?? '';
      final matchesCat = catName.contains(q);
      if (!matchesNote && !matchesCat) return false;
    }
    return true;
  }).toList();

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
