class CategoryItem {
  final String id;
  final String name;
  final String kind; // 'expense' | 'income'
  final String iconName;
  final String colorToken;
  final int order;
  final bool archived;
  final DateTime createdAt;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconName,
    required this.colorToken,
    required this.order,
    this.archived = false,
    required this.createdAt,
  });

  bool get isExpense => kind == 'expense';
  bool get isIncome => kind == 'income';

  CategoryItem copyWith({
    String? id,
    String? name,
    String? kind,
    String? iconName,
    String? colorToken,
    int? order,
    bool? archived,
    DateTime? createdAt,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      iconName: iconName ?? this.iconName,
      colorToken: colorToken ?? this.colorToken,
      order: order ?? this.order,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kind': kind,
      'iconName': iconName,
      'colorToken': colorToken,
      'order': order,
      'archived': archived,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      iconName: json['iconName'] as String,
      colorToken: json['colorToken'] as String,
      order: json['order'] as int? ?? 0,
      archived: json['archived'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Default Expense Categories (Streamlined essentials)
  static List<CategoryItem> defaultExpenseCategories() {
    final now = DateTime.now();
    return [
      CategoryItem(id: 'cat_exp_food', name: 'Food & Dining', kind: 'expense', iconName: 'restaurant', colorToken: 'clay', order: 0, createdAt: now),
      CategoryItem(id: 'cat_exp_grocery', name: 'Groceries & Daily', kind: 'expense', iconName: 'shopping_cart', colorToken: 'moss', order: 1, createdAt: now),
      CategoryItem(id: 'cat_exp_travel', name: 'Travel & Fuel', kind: 'expense', iconName: 'directions_bus', colorToken: 'rust', order: 2, createdAt: now),
      CategoryItem(id: 'cat_exp_shopping', name: 'Shopping', kind: 'expense', iconName: 'shopping_bag', colorToken: 'amber', order: 3, createdAt: now),
      CategoryItem(id: 'cat_exp_bills', name: 'Bills & Rent', kind: 'expense', iconName: 'receipt', colorToken: 'plum', order: 4, createdAt: now),
      CategoryItem(id: 'cat_exp_other', name: 'Other', kind: 'expense', iconName: 'more_horiz', colorToken: 'sand', order: 5, createdAt: now),
    ];
  }

  /// Default Income Categories (Streamlined essentials)
  static List<CategoryItem> defaultIncomeCategories() {
    final now = DateTime.now();
    return [
      CategoryItem(id: 'cat_inc_salary', name: 'Salary', kind: 'income', iconName: 'payments', colorToken: 'teal', order: 0, createdAt: now),
      CategoryItem(id: 'cat_inc_freelance', name: 'Freelance & Business', kind: 'income', iconName: 'laptop_mac', colorToken: 'amber', order: 1, createdAt: now),
      CategoryItem(id: 'cat_inc_other', name: 'Other Income', kind: 'income', iconName: 'account_balance_wallet', colorToken: 'moss', order: 2, createdAt: now),
    ];
  }
}

