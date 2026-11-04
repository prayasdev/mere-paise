import '../../core/utils/date_utils.dart';

class TransactionEntry {
  final String id;
  final String type; // 'expense' | 'income' | 'transfer'
  final int amountPaise;
  final String categoryId;
  final String? accountId;
  final List<String> tagIds;
  final String note;
  final DateTime occurredAt;
  final String dayKey;
  final String weekKey;
  final String monthKey;
  final String yearKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isSynced;

  const TransactionEntry({
    required this.id,
    required this.type,
    required this.amountPaise,
    required this.categoryId,
    this.accountId,
    this.tagIds = const [],
    this.note = '',
    required this.occurredAt,
    required this.dayKey,
    required this.weekKey,
    required this.monthKey,
    required this.yearKey,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isSynced = true,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isTransfer => type == 'transfer';
  bool get isDeleted => deletedAt != null;

  factory TransactionEntry.create({
    required String id,
    required String type,
    required int amountPaise,
    required String categoryId,
    String? accountId,
    List<String> tagIds = const [],
    String note = '',
    DateTime? occurredAt,
  }) {
    final now = DateTime.now();
    final effectiveOccurredAt = occurredAt ?? now;
    return TransactionEntry(
      id: id,
      type: type,
      amountPaise: amountPaise,
      categoryId: categoryId,
      accountId: accountId,
      tagIds: tagIds,
      note: note,
      occurredAt: effectiveOccurredAt,
      dayKey: LedgerDateUtils.dayKey(effectiveOccurredAt),
      weekKey: LedgerDateUtils.weekKey(effectiveOccurredAt),
      monthKey: LedgerDateUtils.monthKey(effectiveOccurredAt),
      yearKey: LedgerDateUtils.yearKey(effectiveOccurredAt),
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      isSynced: true,
    );
  }

  TransactionEntry copyWith({
    String? id,
    String? type,
    int? amountPaise,
    String? categoryId,
    String? accountId,
    List<String>? tagIds,
    String? note,
    DateTime? occurredAt,
    String? dayKey,
    String? weekKey,
    String? monthKey,
    String? yearKey,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? isSynced,
  }) {
    return TransactionEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      amountPaise: amountPaise ?? this.amountPaise,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      tagIds: tagIds ?? this.tagIds,
      note: note ?? this.note,
      occurredAt: occurredAt ?? this.occurredAt,
      dayKey: dayKey ?? this.dayKey,
      weekKey: weekKey ?? this.weekKey,
      monthKey: monthKey ?? this.monthKey,
      yearKey: yearKey ?? this.yearKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amountPaise': amountPaise,
      'categoryId': categoryId,
      'accountId': accountId,
      'tagIds': tagIds,
      'note': note,
      'occurredAt': occurredAt.toIso8601String(),
      'dayKey': dayKey,
      'weekKey': weekKey,
      'monthKey': monthKey,
      'yearKey': yearKey,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory TransactionEntry.fromJson(Map<String, dynamic> json) {
    return TransactionEntry(
      id: json['id'] as String,
      type: json['type'] as String,
      amountPaise: json['amountPaise'] as int,
      categoryId: json['categoryId'] as String,
      accountId: json['accountId'] as String?,
      tagIds: (json['tagIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      note: json['note'] as String? ?? '',
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      dayKey: json['dayKey'] as String,
      weekKey: json['weekKey'] as String,
      monthKey: json['monthKey'] as String,
      yearKey: json['yearKey'] as String,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }
}
