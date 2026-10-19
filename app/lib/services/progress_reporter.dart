import 'dart:async';

import '../data/repositories/progress_repository.dart';

typedef PeriodicTimer =
    Timer Function(Duration duration, void Function(Timer timer) callback);

class ProgressReporter {
  ProgressReporter({
    required this.repository,
    required this.lectureId,
    required this.segmentId,
    this.periodicTimer = Timer.periodic,
  });

  final ProgressRepository repository;
  final int lectureId;
  final int segmentId;
  final PeriodicTimer periodicTimer;
  Timer? _timer;
  Duration _position = Duration.zero;
  Duration _maximumPosition = Duration.zero;

  void start() {
    _timer ??= periodicTimer(const Duration(seconds: 15), (_) => report());
  }

  void update(Duration position) {
    _position = position;
    if (position > _maximumPosition) _maximumPosition = position;
  }

  Future<void> report() async {
    try {
      await repository.report(
        lectureId: lectureId,
        segmentId: segmentId,
        positionSeconds: _position.inSeconds,
        watchedSeconds: _maximumPosition.inSeconds,
      );
    } catch (_) {
      // Reporting is best effort; the next tick carries the later position.
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await report();
  }
}
