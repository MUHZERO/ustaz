import 'category.dart';

class Subscription {
  const Subscription({
    required this.category,
    required this.startsAt,
    this.endsAt,
  });

  final Category category;
  final DateTime startsAt;
  final DateTime? endsAt;

  factory Subscription.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return Subscription(
      category: Category.fromJson(value['category']),
      startsAt: DateTime.parse(value['starts_at'] as String),
      endsAt: value['ends_at'] == null
          ? null
          : DateTime.parse(value['ends_at'] as String),
    );
  }
}
