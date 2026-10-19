class LectureCard {
  const LectureCard({
    required this.id,
    required this.title,
    required this.position,
    required this.isFree,
    required this.isLocked,
    required this.progressPercent,
    this.thumbnailUrl,
  });

  final int id;
  final String title;
  final int position;
  final bool isFree;
  final bool isLocked;
  final num progressPercent;
  final String? thumbnailUrl;

  factory LectureCard.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return LectureCard(
      id: (value['id'] as num).toInt(),
      title: value['title'] as String,
      position: (value['position'] as num).toInt(),
      isFree: value['is_free'] as bool,
      isLocked: value['is_locked'] as bool,
      progressPercent: value['progress_percent'] as num,
      thumbnailUrl: value['thumbnail_url'] as String?,
    );
  }
}
