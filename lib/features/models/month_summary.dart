class MonthSummary {
  final String monthKey;
  final int outPaise;
  final int inPaise;
  final Map<String, int> byCategory;
  final Map<String, int> byDay; // e.g. "04": paise
  final DateTime updatedAt;

  const MonthSummary({
    required this.monthKey,
    required this.outPaise,
    required this.inPaise,
    this.byCategory = const {},
    this.byDay = const {},
    required this.updatedAt,
  });

  int get netPaise => inPaise - outPaise;

  Map<String, dynamic> toJson() {
    return {
      'monthKey': monthKey,
      'outPaise': outPaise,
      'inPaise': inPaise,
      'byCategory': byCategory,
      'byDay': byDay,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MonthSummary.fromJson(Map<String, dynamic> json) {
    final rawByCat = json['byCategory'] as Map<String, dynamic>? ?? {};
    final rawByDay = json['byDay'] as Map<String, dynamic>? ?? {};

    return MonthSummary(
      monthKey: json['monthKey'] as String,
      outPaise: json['outPaise'] as int? ?? 0,
      inPaise: json['inPaise'] as int? ?? 0,
      byCategory: rawByCat.map((k, v) => MapEntry(k, (v as num).toInt())),
      byDay: rawByDay.map((k, v) => MapEntry(k, (v as num).toInt())),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  factory MonthSummary.empty(String monthKey) {
    return MonthSummary(
      monthKey: monthKey,
      outPaise: 0,
      inPaise: 0,
      byCategory: {},
      byDay: {},
      updatedAt: DateTime.now(),
    );
  }
}

