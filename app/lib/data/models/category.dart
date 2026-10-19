class Category {
  const Category({
    required this.id,
    required this.name,
    required this.position,
    required this.isFree,
    required this.isSubscribed,
    this.endsAt,
    required this.lecturesCount,
    required this.examsCount,
    required this.papersCount,
  });

  final int id;
  final String name;
  final int position;
  final bool isFree;
  final bool isSubscribed;
  final DateTime? endsAt;
  final int lecturesCount;
  final int examsCount;
  final int papersCount;

  factory Category.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return Category(
      id: (value['id'] as num).toInt(),
      name: value['name'] as String,
      position: (value['position'] as num).toInt(),
      isFree: value['is_free'] as bool,
      isSubscribed: value['is_subscribed'] as bool,
      endsAt: value['ends_at'] == null
          ? null
          : DateTime.parse(value['ends_at'] as String),
      lecturesCount: (value['lectures_count'] as num).toInt(),
      examsCount: (value['exams_count'] as num).toInt(),
      papersCount: (value['papers_count'] as num).toInt(),
    );
  }
}
