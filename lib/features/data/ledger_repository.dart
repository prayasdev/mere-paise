import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../core/utils/date_utils.dart';
import '../models/category_item.dart';
import '../models/month_summary.dart';
import '../models/tag_item.dart';
import '../models/transaction_entry.dart';
import '../models/user_settings.dart';
import 'storage_service.dart';

class LedgerRepository {
  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  List<TransactionEntry> _transactions = [];
  List<CategoryItem> _categories = [];
  List<TagItem> _tags = [];
  Map<String, MonthSummary> _summaries = {};
  UserSettings _settings = const UserSettings();

  LedgerRepository(this._storage);

  List<TransactionEntry> get transactions => List.unmodifiable(_transactions);
  List<TransactionEntry> get activeTransactions =>
      List.unmodifiable(_transactions.where((t) => !t.isDeleted).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)));

  List<CategoryItem> get categories => List.unmodifiable(_categories);
  List<CategoryItem> get activeCategories =>
      List.unmodifiable(_categories.where((c) => !c.archived).toList()
        ..sort((a, b) => a.order.compareTo(b.order)));

  List<TagItem> get tags => List.unmodifiable(_tags);
  Map<String, MonthSummary> get summaries => Map.unmodifiable(_summaries);
  UserSettings get settings => _settings;

  Future<void> init() async {
    await _storage.init();

    // 1. Load Categories or seed defaults
    final catData = await _storage.loadCategories();
    if (catData.isEmpty) {
      _categories = [
        ...CategoryItem.defaultExpenseCategories(),
        ...CategoryItem.defaultIncomeCategories(),
      ];
      await _storage.saveCategories(_categories.map((c) => c.toJson()).toList());
    } else {
      _categories = catData.map(CategoryItem.fromJson).toList();
    }

    // 2. Load Tags
    final tagData = await _storage.loadTags();
    _tags = tagData.map(TagItem.fromJson).toList();

    // 3. Load Transactions
    final txnData = await _storage.loadTransactions();
    _transactions = txnData.map(TransactionEntry.fromJson).toList();

    // 4. Load Summaries
    final sumData = await _storage.loadSummaries();
    _summaries = sumData.map(
      (k, v) => MapEntry(k, MonthSummary.fromJson(Map<String, dynamic>.from(v as Map))),
    );

    // 5. Load Settings
    final setMap = await _storage.loadSettings();
    if (setMap != null) {
      _settings = UserSettings.fromJson(setMap);
    }

    // Ensure summaries are up to date
    if (_summaries.isEmpty && _transactions.isNotEmpty) {
      await rebuildSummaries();
    }
  }

  // --- Transactions Management ---

  /// Checks for duplicate entry within the same minute with identical amount and category
  bool isDuplicateEntry({
    required int amountPaise,
    required String categoryId,
    required DateTime occurredAt,
  }) {
    final minuteThreshold = Duration(minutes: 1);
    return _transactions.any((t) =>
        !t.isDeleted &&
        t.amountPaise == amountPaise &&
        t.categoryId == categoryId &&
        (t.occurredAt.difference(occurredAt).abs() <= minuteThreshold));
  }

  Future<TransactionEntry> createTransaction({
    required String type,
    required int amountPaise,
    required String categoryId,
    String? accountId,
    List<String> tagIds = const [],
    String note = '',
    DateTime? occurredAt,
  }) async {
    final effectiveOccurredAt = occurredAt ?? DateTime.now();
    final entry = TransactionEntry.create(
      id: _uuid.v4(),
      type: type,
      amountPaise: amountPaise,
      categoryId: categoryId,
      accountId: accountId,
      tagIds: tagIds,
      note: note,
      occurredAt: effectiveOccurredAt,
    );

    _transactions.insert(0, entry);
    await _applyTransactionToSummary(entry, isAddition: true);
    await _storage.saveTransactions(_transactions.map((t) => t.toJson()).toList());
    await _storage.setLastUsedCategory(type, categoryId);

    return entry;
  }

  Future<void> updateTransaction(TransactionEntry updated) async {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index == -1) return;

    final old = _transactions[index];
    // Reverse old values from summary
    if (!old.isDeleted) {
      await _applyTransactionToSummary(old, isAddition: false);
    }

    final newOccurredAt = updated.occurredAt;
    final processed = updated.copyWith(
      dayKey: LedgerDateUtils.dayKey(newOccurredAt),
      weekKey: LedgerDateUtils.weekKey(newOccurredAt),
      monthKey: LedgerDateUtils.monthKey(newOccurredAt),
      yearKey: LedgerDateUtils.yearKey(newOccurredAt),
      updatedAt: DateTime.now(),
    );

    _transactions[index] = processed;

    if (!processed.isDeleted) {
      await _applyTransactionToSummary(processed, isAddition: true);
    }

    await _storage.saveTransactions(_transactions.map((t) => t.toJson()).toList());
  }

  /// Soft deletes an entry with 6-second undo window
  Future<TransactionEntry?> softDeleteTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return null;

    final old = _transactions[index];
    if (old.isDeleted) return old;

    final deleted = old.copyWith(deletedAt: DateTime.now());
    _transactions[index] = deleted;

    await _applyTransactionToSummary(old, isAddition: false);
    await _storage.saveTransactions(_transactions.map((t) => t.toJson()).toList());
    return deleted;
  }

  /// Restores a soft-deleted entry (Undo action)
  Future<void> restoreTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final item = _transactions[index];
    if (!item.isDeleted) return;

    final restored = item.copyWith(clearDeletedAt: true);
    _transactions[index] = restored;

    await _applyTransactionToSummary(restored, isAddition: true);
    await _storage.saveTransactions(_transactions.map((t) => t.toJson()).toList());
  }

  /// Inserts a transaction from cloud sync or updates it if already present.
  Future<void> upsertTransaction(TransactionEntry entry) async {
    final index = _transactions.indexWhere((t) => t.id == entry.id);
    if (index == -1) {
      _transactions.add(entry);
      if (!entry.isDeleted) {
        await _applyTransactionToSummary(entry, isAddition: true);
      }
    } else {
      final old = _transactions[index];
      if (!old.isDeleted) {
        await _applyTransactionToSummary(old, isAddition: false);
      }
      _transactions[index] = entry;
      if (!entry.isDeleted) {
        await _applyTransactionToSummary(entry, isAddition: true);
      }
    }
    _transactions.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    await _storage.saveTransactions(_transactions.map((t) => t.toJson()).toList());
  }

  Future<void> permanentDeleteTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final old = _transactions[index];
    if (!old.isDeleted) {
      await _applyTransactionToSummary(old, isAddition: false);
    }
    _transactions.removeAt(index);
    await _storage.saveTransactions(_transactions.map((t) => t.toJson()).toList());
  }

  // --- Category Management ---

  Future<CategoryItem> addCategory({
    required String name,
    required String kind,
    required String iconName,
    required String colorToken,
  }) async {
    final newCat = CategoryItem(
      id: _uuid.v4(),
      name: name.trim(),
      kind: kind,
      iconName: iconName,
      colorToken: colorToken,
      order: _categories.where((c) => c.kind == kind).length,
      createdAt: DateTime.now(),
    );
    _categories.add(newCat);
    await _storage.saveCategories(_categories.map((c) => c.toJson()).toList());
    return newCat;
  }

  Future<void> updateCategory(CategoryItem category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      await _storage.saveCategories(_categories.map((c) => c.toJson()).toList());
    }
  }

  /// Inserts a category from cloud sync or updates it if already present.
  Future<void> upsertCategory(CategoryItem category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index == -1) {
      _categories.add(category);
    } else {
      _categories[index] = category;
    }
    await _storage.saveCategories(_categories.map((c) => c.toJson()).toList());
  }

  Future<void> archiveCategory(String categoryId, bool archive) async {
    final index = _categories.indexWhere((c) => c.id == categoryId);
    if (index != -1) {
      _categories[index] = _categories[index].copyWith(archived: archive);
      await _storage.saveCategories(_categories.map((c) => c.toJson()).toList());
    }
  }

  Future<void> reorderCategories(String kind, int oldIndex, int newIndex) async {
    final list = _categories.where((c) => c.kind == kind && !c.archived).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    for (int i = 0; i < list.length; i++) {
      final catId = list[i].id;
      final idxInMain = _categories.indexWhere((c) => c.id == catId);
      if (idxInMain != -1) {
        _categories[idxInMain] = _categories[idxInMain].copyWith(order: i);
      }
    }
    await _storage.saveCategories(_categories.map((c) => c.toJson()).toList());
  }

  /// Deletes a category and safely reassigns existing transactions to replacementCategoryId
  Future<void> deleteCategoryWithReassignment({
    required String categoryIdToDelete,
    required String replacementCategoryId,
  }) async {
    // 1. Reassign in transactions
    bool txnsChanged = false;
    for (int i = 0; i < _transactions.length; i++) {
      if (_transactions[i].categoryId == categoryIdToDelete) {
        _transactions[i] = _transactions[i].copyWith(categoryId: replacementCategoryId);
        txnsChanged = true;
      }
    }
    if (txnsChanged) {
      await _storage.saveTransactions(_transactions.map((t) => t.toJson()).toList());
      await rebuildSummaries();
    }

    // 2. Remove category
    _categories.removeWhere((c) => c.id == categoryIdToDelete);
    await _storage.saveCategories(_categories.map((c) => c.toJson()).toList());
  }

  // --- Tag Management ---

  Future<TagItem> getOrCreateTag(String tagName) async {
    final cleanName = tagName.trim().replaceAll('#', '').toLowerCase();
    final existing = _tags.cast<TagItem?>().firstWhere(
      (t) => t?.name.toLowerCase() == cleanName,
      orElse: () => null,
    );
    if (existing != null) return existing;

    final newTag = TagItem(
      id: _uuid.v4(),
      name: cleanName,
      createdAt: DateTime.now(),
    );
    _tags.add(newTag);
    await _storage.saveTags(_tags.map((t) => t.toJson()).toList());
    return newTag;
  }

  Future<void> renameTag(String tagId, String newName) async {
    final clean = newName.trim().replaceAll('#', '').toLowerCase();
    final index = _tags.indexWhere((t) => t.id == tagId);
    if (index != -1) {
      _tags[index] = _tags[index].copyWith(name: clean);
      await _storage.saveTags(_tags.map((t) => t.toJson()).toList());
    }
  }

  /// Inserts a tag from cloud sync or updates it if already present.
  Future<void> upsertTag(TagItem tag) async {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index == -1) {
      _tags.add(tag);
    } else {
      _tags[index] = tag;
    }
    await _storage.saveTags(_tags.map((t) => t.toJson()).toList());
  }

  Future<void> mergeTags({required String sourceTagId, required String targetTagId}) async {
    if (sourceTagId == targetTagId) return;

    for (int i = 0; i < _transactions.length; i++) {
      final t = _transactions[i];
      if (t.tagIds.contains(sourceTagId)) {
        final newTagIds = List<String>.from(t.tagIds)..remove(sourceTagId);
        if (!newTagIds.contains(targetTagId)) {
          newTagIds.add(targetTagId);
        }
        _transactions[i] = t.copyWith(tagIds: newTagIds);
      }
    }
    _tags.removeWhere((t) => t.id == sourceTagId);

    await _storage.saveTransactions(_transactions.map((t) => t.toJson()).toList());
    await _storage.saveTags(_tags.map((t) => t.toJson()).toList());
  }

  Future<void> deleteTag(String tagId) async {
    for (int i = 0; i < _transactions.length; i++) {
      final t = _transactions[i];
      if (t.tagIds.contains(tagId)) {
        final newTagIds = List<String>.from(t.tagIds)..remove(tagId);
        _transactions[i] = t.copyWith(tagIds: newTagIds);
      }
    }
    _tags.removeWhere((t) => t.id == tagId);

    await _storage.saveTransactions(_transactions.map((t) => t.toJson()).toList());
    await _storage.saveTags(_tags.map((t) => t.toJson()).toList());
  }

  // --- Summary Calculations ---

  Future<void> _applyTransactionToSummary(TransactionEntry entry, {required bool isAddition}) async {
    final monthKey = entry.monthKey;
    final currentSummary = _summaries[monthKey] ?? MonthSummary.empty(monthKey);

    final sign = isAddition ? 1 : -1;
    final deltaOut = entry.isExpense ? entry.amountPaise * sign : 0;
    final deltaIn = entry.isIncome ? entry.amountPaise * sign : 0;

    final byCat = Map<String, int>.from(currentSummary.byCategory);
    final catVal = (byCat[entry.categoryId] ?? 0) + (entry.amountPaise * sign);
    if (catVal > 0) {
      byCat[entry.categoryId] = catVal;
    } else {
      byCat.remove(entry.categoryId);
    }

    final dayStr = entry.occurredAt.day.toString().padLeft(2, '0');
    final byDay = Map<String, int>.from(currentSummary.byDay);
    final dayVal = (byDay[dayStr] ?? 0) + (entry.amountPaise * sign);
    if (dayVal > 0) {
      byDay[dayStr] = dayVal;
    } else {
      byDay.remove(dayStr);
    }

    final updatedSummary = MonthSummary(
      monthKey: monthKey,
      outPaise: (currentSummary.outPaise + deltaOut).clamp(0, 999999999999),
      inPaise: (currentSummary.inPaise + deltaIn).clamp(0, 999999999999),
      byCategory: byCat,
      byDay: byDay,
      updatedAt: DateTime.now(),
    );

    _summaries[monthKey] = updatedSummary;
    await _storage.saveSummaries(_summaries.map((k, v) => MapEntry(k, v.toJson())));
  }

  Future<void> rebuildSummaries() async {
    _summaries.clear();
    for (final t in _transactions) {
      if (!t.isDeleted) {
        final monthKey = t.monthKey;
        final cur = _summaries[monthKey] ?? MonthSummary.empty(monthKey);

        final byCat = Map<String, int>.from(cur.byCategory);
        byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amountPaise;

        final dayStr = t.occurredAt.day.toString().padLeft(2, '0');
        final byDay = Map<String, int>.from(cur.byDay);
        byDay[dayStr] = (byDay[dayStr] ?? 0) + t.amountPaise;

        _summaries[monthKey] = MonthSummary(
          monthKey: monthKey,
          outPaise: cur.outPaise + (t.isExpense ? t.amountPaise : 0),
          inPaise: cur.inPaise + (t.isIncome ? t.amountPaise : 0),
          byCategory: byCat,
          byDay: byDay,
          updatedAt: DateTime.now(),
        );
      }
    }
    await _storage.saveSummaries(_summaries.map((k, v) => MapEntry(k, v.toJson())));
  }

  // --- Settings ---

  Future<void> updateSettings(UserSettings settings) async {
    _settings = settings;
    await _storage.saveSettings(settings.toJson());
  }

  String? getLastUsedCategory(String type) => _storage.getLastUsedCategory(type);

  // --- CSV & Backup Export ---

  Future<String> exportCsvFile({List<TransactionEntry>? subset}) async {
    final list = subset ?? activeTransactions;
    final rows = <List<dynamic>>[];

    // Professional Column Headers
    rows.add([
      'Date',
      'Time',
      'Type',
      'Category',
      'Amount (₹)',
      'Signed Amount',
      'Amount (Paise)',
      'Note',
      'Tags',
      'Transaction ID',
    ]);

    final categoryMap = {for (var c in _categories) c.id: c.name};
    final tagMap = {for (var t in _tags) t.id: t.name};

    for (final t in list) {
      final catName = categoryMap[t.categoryId] ?? 'General';
      final tagNames = t.tagIds.map((id) => tagMap[id] != null ? '#${tagMap[id]}' : id).join(' ');
      final rupees = (t.amountPaise / 100.0).toStringAsFixed(2);
      final signedAmount = t.isExpense ? '-$rupees' : '+$rupees';
      final typeLabel = t.isExpense ? 'Spent' : 'Received';

      final dateStr = LedgerDateUtils.dayKey(t.occurredAt);
      final timeStr = LedgerDateUtils.formatTime(t.occurredAt);

      rows.add([
        dateStr,
        timeStr,
        typeLabel,
        catName,
        rupees,
        signedAmount,
        t.amountPaise,
        t.note,
        tagNames,
        t.id,
      ]);
    }

    final csvString = _convertToCsv(rows);
    final storagePath = await _storage.getAppStoragePath();
    final now = DateTime.now();
    final dateSuffix = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final filePath = '$storagePath/mere_paise_ledger_$dateSuffix.csv';
    final file = File(filePath);
    await file.writeAsString(csvString);
    return filePath;
  }

  /// Exports a complete offline JSON backup of all ledger data.
  Future<String> exportJsonBackup() async {
    final data = {
      'app': 'Mere Paise',
      'version': '1.0.1',
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': _settings.toJson(),
      'categories': _categories.map((c) => c.toJson()).toList(),
      'tags': _tags.map((t) => t.toJson()).toList(),
      'transactions': _transactions.map((t) => t.toJson()).toList(),
    };

    final raw = const JsonEncoder.withIndent('  ').convert(data);
    final storagePath = await _storage.getAppStoragePath();
    final now = DateTime.now();
    final dateSuffix = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final filePath = '$storagePath/mere_paise_backup_$dateSuffix.json';
    final file = File(filePath);
    await file.writeAsString(raw);
    return filePath;
  }

  /// Restores all data from a JSON backup string. Returns count of restored transactions.
  Future<int> restoreJsonBackup(String jsonContent) async {
    final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;
    if (decoded.containsKey('categories')) {
      final catList = (decoded['categories'] as List).map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      _categories = catList;
      await _storage.saveCategories(_categories.map((c) => c.toJson()).toList());
    }
    if (decoded.containsKey('tags')) {
      final tagList = (decoded['tags'] as List).map((e) => TagItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      _tags = tagList;
      await _storage.saveTags(_tags.map((t) => t.toJson()).toList());
    }
    if (decoded.containsKey('transactions')) {
      final txnList = (decoded['transactions'] as List).map((e) => TransactionEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      _transactions = txnList;
      await _storage.saveTransactions(_transactions.map((t) => t.toJson()).toList());
    }
    if (decoded.containsKey('settings')) {
      _settings = UserSettings.fromJson(Map<String, dynamic>.from(decoded['settings'] as Map));
      await _storage.saveSettings(_settings.toJson());
    }
    await rebuildSummaries();
    return _transactions.where((t) => !t.isDeleted).length;
  }

  String _convertToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        final str = cell.toString();
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
    }).join('\r\n');
  }

  Future<void> clearAllData() async {
    _transactions.clear();
    _summaries.clear();
    _tags.clear();
    _categories = [
      ...CategoryItem.defaultExpenseCategories(),
      ...CategoryItem.defaultIncomeCategories(),
    ];
    await _storage.clearAll();
    await _storage.saveCategories(_categories.map((c) => c.toJson()).toList());
  }
}
