enum SegmentType { video, pdf, quiz }

class SegmentVideo {
  const SegmentVideo({
    required this.youtubeId,
    required this.durationSeconds,
    required this.lastPositionSeconds,
  });

  final String youtubeId;
  final int durationSeconds;
  final int lastPositionSeconds;

  factory SegmentVideo.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return SegmentVideo(
      youtubeId: value['youtube_id'] as String,
      durationSeconds: (value['duration_seconds'] as num).toInt(),
      lastPositionSeconds: (value['last_position_seconds'] as num).toInt(),
    );
  }
}

class SegmentPdf {
  const SegmentPdf({required this.url});
  final String url;

  factory SegmentPdf.fromJson(Object? json) =>
      SegmentPdf(url: (json as Map<String, dynamic>)['url'] as String);
}

class SegmentQuiz {
  const SegmentQuiz({
    required this.assessmentId,
    required this.passPercent,
    this.bestPercent,
  });

  final int assessmentId;
  final num passPercent;
  final num? bestPercent;

  factory SegmentQuiz.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return SegmentQuiz(
      assessmentId: (value['assessment_id'] as num).toInt(),
      passPercent: value['pass_percent'] as num,
      bestPercent: value['best_percent'] as num?,
    );
  }
}

class Segment {
  const Segment({
    required this.id,
    required this.type,
    required this.position,
    required this.title,
    required this.isGating,
    required this.isLocked,
    this.passed,
    this.video,
    this.pdf,
    this.quiz,
  });

  final int id;
  final SegmentType type;
  final int position;
  final String title;
  final bool isGating;
  final bool isLocked;
  final bool? passed;
  final SegmentVideo? video;
  final SegmentPdf? pdf;
  final SegmentQuiz? quiz;

  factory Segment.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return Segment(
      id: (value['id'] as num).toInt(),
      type: SegmentType.values.byName(value['type'] as String),
      position: (value['position'] as num).toInt(),
      title: value['title'] as String,
      isGating: value['is_gating'] as bool,
      isLocked: value['is_locked'] as bool,
      passed: value['passed'] as bool?,
      video: value['video'] == null
          ? null
          : SegmentVideo.fromJson(value['video']),
      pdf: value['pdf'] == null ? null : SegmentPdf.fromJson(value['pdf']),
      quiz: value['quiz'] == null ? null : SegmentQuiz.fromJson(value['quiz']),
    );
  }
}
