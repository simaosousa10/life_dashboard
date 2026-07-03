import 'model_helpers.dart';

class AppCategory {
  const AppCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    this.color,
    this.icon,
  });

  final String id;
  final String userId;
  final String name;
  final String? color;
  final String? icon;
  final DateTime createdAt;

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      createdAt: parseDate(map['created_at']),
    );
  }
}

class AppCategoryInput {
  const AppCategoryInput({required this.name, this.color, this.icon});

  final String name;
  final String? color;
  final String? icon;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'name': name.trim(),
    'color': color,
    'icon': icon,
  };
}
