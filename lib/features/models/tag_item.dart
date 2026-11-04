class TagItem {
  final String id;
  final String name;
  final DateTime createdAt;

  const TagItem({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TagItem.fromJson(Map<String, dynamic> json) {
    return TagItem(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  TagItem copyWith({String? id, String? name, DateTime? createdAt}) {
    return TagItem(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

