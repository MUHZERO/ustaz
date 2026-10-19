import '../../core/network/api_client.dart';

class ProgressRepository {
  ProgressRepository(this._api);
  final ApiClient _api;

  Future<void> report({
    required int lectureId,
    required int segmentId,
    required int positionSeconds,
    required int watchedSeconds,
  }) => _api.post('/lectures/$lectureId/progress', {
    'segment_id': segmentId,
    'position_seconds': positionSeconds,
    'watched_seconds': watchedSeconds,
  }, (_) {});
}
