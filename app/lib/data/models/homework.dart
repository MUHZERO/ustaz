enum HomeworkStatus { notStarted, inProgress, done }

class Homework {
  const Homework({
    required this.assessmentId,
    required this.title,
    required this.lectureId,
    required this.status,
    this.percent,
  });

  final int assessmentId;
  final String title;
  final int lectureId;
  final HomeworkStatus status;
  final num? percent;

  factory Homework.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    final attempt = value['attempt'] as Map<String, dynamic>?;
    return Homework(
      assessmentId: (value['assessment_id'] as num).toInt(),
      title: value['title'] as String,
      lectureId: (value['lecture_id'] as num).toInt(),
      status: switch (attempt?['status']) {
        null => HomeworkStatus.notStarted,
        'submitted' => HomeworkStatus.done,
        _ => HomeworkStatus.inProgress,
      },
      percent: attempt?['percent'] as num?,
    );
  }
}
