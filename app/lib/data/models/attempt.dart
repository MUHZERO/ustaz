import 'question.dart';

enum AssessmentKind { quiz, homework, exam }

class Attempt {
  const Attempt({
    required this.id,
    required this.assessmentId,
    required this.kind,
    required this.startedAt,
    required this.serverTime,
    required this.isSubmitted,
    required this.questions,
    required this.answers,
    this.deadlineAt,
  });

  final int id;
  final int assessmentId;
  final AssessmentKind kind;
  final DateTime startedAt;

  /// The server's clock when this response was built.
  final DateTime serverTime;
  final DateTime? deadlineAt;
  final bool isSubmitted;
  final List<Question> questions;

  /// question id → option id.
  final Map<int, int> answers;

  factory Attempt.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    // An empty PHP map arrives as `[]`.
    final answers = value['answers'] is Map
        ? value['answers'] as Map
        : const <Object?, Object?>{};
    return Attempt(
      id: (value['id'] as num).toInt(),
      assessmentId: (value['assessment_id'] as num).toInt(),
      kind: AssessmentKind.values.byName(value['kind'] as String),
      startedAt: DateTime.parse(value['started_at'] as String),
      serverTime: DateTime.parse(value['server_time'] as String),
      deadlineAt: value['deadline_at'] == null
          ? null
          : DateTime.parse(value['deadline_at'] as String),
      isSubmitted: value['status'] == 'submitted',
      questions: (value['questions'] as List)
          .map(Question.fromJson)
          .toList(growable: false),
      answers: answers.map(
        (key, option) => MapEntry(int.parse('$key'), (option as num).toInt()),
      ),
    );
  }
}
