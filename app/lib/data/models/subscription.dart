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
      // The backend sends only the category's id and name here (the contract
      // says a full Category); the rest defaults so the profile still loads.
      category: Category.fromJson({
        'position': 0,
        'is_free': false,
        'is_subscribed': true,
        'lectures_count': 0,
        'exams_count': 0,
        'papers_count': 0,
        ...value['category'] as Map<String, dynamic>,
      }),
      startsAt: DateTime.parse(value['starts_at'] as String),
      endsAt: value['ends_at'] == null
          ? null
          : DateTime.parse(value['ends_at'] as String),
    );
  }
}
