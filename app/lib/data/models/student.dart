import 'level.dart';

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.phone,
    this.parentPhone,
    required this.level,
    required this.createdAt,
  });
  final int id;
  final String name;
  final String phone;
  final String? parentPhone;
  final Level level;
  final DateTime createdAt;

  factory Student.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return Student(
      id: (value['id'] as num).toInt(),
      name: value['name'] as String,
      phone: value['phone'] as String,
      parentPhone: value['parent_phone'] as String?,
      level: Level.fromJson(value['level']),
      createdAt: DateTime.parse(value['created_at'] as String),
    );
  }
}
