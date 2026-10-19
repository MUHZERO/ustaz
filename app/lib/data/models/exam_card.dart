enum ExamState { upcoming, open, closed }

extension on String {
  ExamState get examState => switch (this) {
    'upcoming' => ExamState.upcoming,
    'open' => ExamState.open,
    'closed' => ExamState.closed,
    _ => throw FormatException('Unknown exam state: $this'),
  };
}

class ExamAttempt {
  const ExamAttempt({required this.id, required this.status, this.percent});

  final int id;
  final String status;
  final num? percent;

  factory ExamAttempt.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return ExamAttempt(
      id: (value['id'] as num).toInt(),
      status: value['status'] as String,
      percent: value['percent'] as num?,
    );
  }
}

class ExamCard {
  const ExamCard({
    required this.id,
    required this.title,
    required this.opensAt,
    required this.closesAt,
    required this.durationMinutes,
    required this.state,
    required this.attempt,
    required this.isLocked,
  });

  final int id;
  final String title;
  final DateTime opensAt;
  final DateTime closesAt;
  final int durationMinutes;
  final ExamState state;
  final ExamAttempt? attempt;
  final bool isLocked;

  factory ExamCard.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return ExamCard(
      id: (value['id'] as num).toInt(),
      title: value['title'] as String,
      opensAt: DateTime.parse(value['opens_at'] as String),
      closesAt: DateTime.parse(value['closes_at'] as String),
      durationMinutes: (value['duration_minutes'] as num).toInt(),
      state: (value['state'] as String).examState,
      attempt: value['attempt'] == null
          ? null
          : ExamAttempt.fromJson(value['attempt']),
      isLocked: value['is_locked'] as bool,
    );
  }
}
