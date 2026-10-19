import 'dart:async';

import 'package:get/get.dart';

import '../../core/base/base_controller.dart';
import '../../core/security/screen_capture_guard.dart';
import '../../data/models/segment.dart';
import '../../data/repositories/progress_repository.dart';
import '../../services/progress_reporter.dart';
import 'video_source.dart';

typedef VideoSourceFactory = VideoSource Function();

class PlayerController extends BaseController {
  PlayerController({
    required this.lectureId,
    required this.segment,
    required this.progressRepository,
    required this.sourceFactory,
    VideoSourceFactory? fallbackSourceFactory,
    required this.captureGuard,
    this.periodicTimer = Timer.periodic,
  }) : _fallbackSourceFactory = fallbackSourceFactory ?? IframeSource.new;

  final int lectureId;
  final Segment segment;
  final ProgressRepository progressRepository;
  final VideoSourceFactory sourceFactory;
  final VideoSourceFactory _fallbackSourceFactory;
  final ScreenCaptureGuard captureGuard;
  final PeriodicTimer periodicTimer;
  final source = Rxn<VideoSource>();
  StreamSubscription<Duration>? _positions;
  StreamSubscription<bool>? _capture;
  ProgressReporter? _reporter;

  @override
  void onInit() {
    super.onInit();
    _capture = captureGuard.isCaptured.listen((captured) {
      if (captured) pause();
    });
    initialize();
  }

  Future<void> initialize() => run(() async {
    final video = segment.video;
    if (video == null) return;
    VideoSource next = sourceFactory();
    try {
      await next.init(
        video.youtubeId,
        Duration(seconds: video.lastPositionSeconds),
      );
    } catch (_) {
      await next.dispose();
      next = _fallbackSourceFactory();
      await next.init(
        video.youtubeId,
        Duration(seconds: video.lastPositionSeconds),
      );
    }
    source.value = next;
    _reporter =
        ProgressReporter(
            repository: progressRepository,
            lectureId: lectureId,
            segmentId: segment.id,
            periodicTimer: periodicTimer,
          )
          ..update(Duration(seconds: video.lastPositionSeconds))
          ..start();
    _positions = next.position.listen(_reporter!.update);
  });

  Future<void> pause() async {
    source.value?.pause();
    await _reporter?.report();
  }

  @override
  void onClose() {
    _capture?.cancel();
    _positions?.cancel();
    source.value?.pause();
    final reporter = _reporter;
    final video = source.value;
    if (reporter != null && video != null) {
      unawaited(Future.wait([reporter.dispose(), video.dispose()]));
    } else {
      unawaited(video?.dispose() ?? Future<void>.value());
    }
    super.onClose();
  }
}
