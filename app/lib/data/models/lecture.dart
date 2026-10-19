import 'segment.dart';

class Lecture {
  const Lecture({
    required this.id,
    required this.title,
    this.description,
    required this.isFree,
    required this.isLocked,
    required this.categoryId,
    required this.segments,
  });

  final int id;
  final String title;
  final String? description;
  final bool isFree;
  final bool isLocked;
  final int categoryId;
  final List<Segment> segments;

  factory Lecture.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return Lecture(
      id: (value['id'] as num).toInt(),
      title: value['title'] as String,
      description: value['description'] as String?,
      isFree: value['is_free'] as bool,
      isLocked: value['is_locked'] as bool,
      categoryId: (value['category_id'] as num).toInt(),
      segments: (value['segments'] as List)
          .map(Segment.fromJson)
          .toList(growable: false),
    );
  }
}
