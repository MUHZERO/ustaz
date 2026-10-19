import 'attempt.dart';

enum ReviewRequestStatus { pending, accepted, rejected }

class ReviewRequest {
  const ReviewRequest({required this.status, this.reply});

  final ReviewRequestStatus status;
  final String? reply;

  factory ReviewRequest.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return ReviewRequest(
      status: ReviewRequestStatus.values.byName(value['status'] as String),
      reply: value['reply'] as String?,
    );
  }
}

class AssessmentResult {
  const AssessmentResult({
    required this.attemptId,
    required this.score,
    required this.maxScore,
    required this.percent,
    required this.submittedAt,
    required this.reviewAvailable,
    this.passed,
    this.reviewRequest,
  });

  final int attemptId;
  final num score;
  final num maxScore;
  final num percent;

  /// Only set for gating quizzes.
  final bool? passed;
  final DateTime submittedAt;
  final bool reviewAvailable;
  final ReviewRequest? reviewRequest;

  factory AssessmentResult.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return AssessmentResult(
      attemptId: (value['attempt_id'] as num).toInt(),
      score: value['score'] as num,
      maxScore: value['max_score'] as num,
      percent: value['percent'] as num,
      passed: value['passed'] as bool?,
      submittedAt: DateTime.parse(value['submitted_at'] as String),
      reviewAvailable: value['review_available'] as bool,
      reviewRequest: value['review_request'] == null
          ? null
          : ReviewRequest.fromJson(value['review_request']),
    );
  }
}

/// A row of `/me/results`: a result with its assessment title and kind.
class ResultEntry {
  const ResultEntry({
    required this.title,
    required this.kind,
    required this.result,
  });

  final String title;
  final AssessmentKind kind;
  final AssessmentResult result;

  factory ResultEntry.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return ResultEntry(
      title: value['title'] as String,
      kind: AssessmentKind.values.byName(value['kind'] as String),
      result: AssessmentResult.fromJson(value),
    );
  }
}
