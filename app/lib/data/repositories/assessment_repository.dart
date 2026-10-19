import '../../core/network/api_client.dart';
import '../models/attempt.dart';
import '../models/homework.dart';
import '../models/paged.dart';
import '../models/result.dart';
import '../models/review_item.dart';

class AssessmentRepository {
  AssessmentRepository(this._api);
  final ApiClient _api;

  /// Starts an attempt, or resumes the open one.
  Future<Attempt> start(int assessmentId) =>
      _api.post('/assessments/$assessmentId/attempts', null, Attempt.fromJson);

  Future<void> answer(int attemptId, int questionId, int optionId) => _api.put(
    '/attempts/$attemptId/answers',
    {'question_id': questionId, 'option_id': optionId},
    (_) {},
  );

  Future<AssessmentResult> submit(int attemptId) =>
      _api.post('/attempts/$attemptId/submit', null, AssessmentResult.fromJson);

  Future<AssessmentResult> result(int attemptId) =>
      _api.get('/attempts/$attemptId/result', AssessmentResult.fromJson);

  Future<List<ReviewItem>> review(int attemptId) => _api.get(
    '/attempts/$attemptId/review',
    (json) => (json as List).map(ReviewItem.fromJson).toList(growable: false),
  );

  Future<AssessmentResult> requestReview(int attemptId, String note) =>
      _api.post('/attempts/$attemptId/review-request', {
        'note': note,
      }, AssessmentResult.fromJson);

  Future<Paged<ResultEntry>> myResults(int page) =>
      _api.getPage('/me/results', ResultEntry.fromJson, page: page);

  Future<List<Homework>> myHomework() => _api.get(
    '/me/homework',
    (json) => (json as List).map(Homework.fromJson).toList(growable: false),
  );
}
