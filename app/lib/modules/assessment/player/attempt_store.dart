import 'dart:async';

import 'package:get_storage/get_storage.dart';

/// Per-attempt local state that must survive a killed app or a network drop.
class AttemptStore {
  AttemptStore(this._storage);
  final GetStorage _storage;

  String _pendingKey(int attemptId) => 'attempt.$attemptId.pending';
  String _offsetKey(int attemptId) => 'attempt.$attemptId.server_offset_ms';

  /// Answers chosen but not yet acknowledged by the server.
  Map<int, int> pending(int attemptId) =>
      (_storage.read<Map>(_pendingKey(attemptId)) ?? const {}).map(
        (key, value) => MapEntry(int.parse('$key'), (value as num).toInt()),
      );

  void savePending(int attemptId, Map<int, int> answers) => unawaited(
    _storage.write(
      _pendingKey(attemptId),
      answers.map((key, value) => MapEntry('$key', value)),
    ),
  );

  Duration? serverOffset(int attemptId) {
    final milliseconds = _storage.read<int>(_offsetKey(attemptId));
    return milliseconds == null ? null : Duration(milliseconds: milliseconds);
  }

  void saveServerOffset(int attemptId, Duration offset) =>
      unawaited(_storage.write(_offsetKey(attemptId), offset.inMilliseconds));

  void clear(int attemptId) {
    unawaited(_storage.remove(_pendingKey(attemptId)));
    unawaited(_storage.remove(_offsetKey(attemptId)));
  }
}
