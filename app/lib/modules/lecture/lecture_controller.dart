import 'package:get/get.dart';

import '../../core/base/base_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/lecture.dart';
import '../../data/models/segment.dart';
import '../../data/models/student.dart';
import '../../data/repositories/content_repository.dart';

class LectureController extends BaseController {
  LectureController(
    this._repository,
    this.lectureId, {
    void Function(String title, String message)? showLockedMessage,
    this.studentForWatermark,
  }) : _showLockedMessage =
           showLockedMessage ??
           ((title, message) => Get.snackbar(title, message));

  final ContentRepository _repository;
  final int lectureId;
  final void Function(String title, String message) _showLockedMessage;
  final Future<Student> Function()? studentForWatermark;
  final data = Rxn<Lecture>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() =>
      run(() async => data.value = await _repository.lecture(lectureId));

  /// A video watched to 90% or a passed quiz; null for PDFs, which are not
  /// tracked.
  static bool? isDone(Segment segment) => switch (segment.type) {
    SegmentType.video => switch (segment.video) {
      final video? =>
        video.durationSeconds > 0 &&
            video.lastPositionSeconds >= video.durationSeconds * 0.9,
      null => false,
    },
    SegmentType.quiz =>
      segment.passed == true ||
          (segment.quiz?.bestPercent ?? -1) >= (segment.quiz?.passPercent ?? 0),
    SegmentType.pdf => null,
  };

  /// Video time watched, 0 to 100: the same measure as the lecture cards'
  /// `progress_percent`.
  int get progressPercent {
    final videos = (data.value?.segments ?? const <Segment>[])
        .map((segment) => segment.video)
        .whereType<SegmentVideo>()
        .where((video) => video.durationSeconds > 0);
    final total = videos.fold(0, (sum, video) => sum + video.durationSeconds);
    if (total == 0) return 0;
    final watched = videos.fold(
      0,
      (sum, video) =>
          sum +
          video.lastPositionSeconds.clamp(0, video.durationSeconds).toInt(),
    );
    return watched * 100 ~/ total;
  }

  Future<void> open(Segment segment) async {
    if (segment.isLocked) {
      final gating = _segmentsBefore(segment).where(
        (item) =>
            item.type == SegmentType.quiz &&
            item.isGating &&
            item.passed != true,
      );
      final quiz = gating.isEmpty ? null : gating.first;
      _showLockedMessage(
        'lecture.locked_title'.tr,
        'lecture.locked_message'.tr,
      );
      if (quiz != null) await _openQuiz(quiz);
      return;
    }

    switch (segment.type) {
      case SegmentType.video:
        final student = await studentForWatermark?.call();
        await Get.toNamed(
          AppRoutes.player,
          arguments: {
            'lectureId': lectureId,
            'segment': segment,
            'studentName': student?.name ?? '',
            'studentPhone': student?.phone ?? '',
          },
        );
        return;
      case SegmentType.pdf:
        final pdf = segment.pdf;
        if (pdf != null) {
          await Get.toNamed(
            AppRoutes.pdf,
            arguments: {'url': pdf.url, 'title': segment.title},
          );
        }
        return;
      case SegmentType.quiz:
        await _openQuiz(segment);
        return;
    }
  }

  Iterable<Segment> _segmentsBefore(Segment segment) =>
      (data.value?.segments ?? const <Segment>[])
          .where((item) => item.position < segment.position)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

  Future<void> _openQuiz(Segment segment) async {
    final quiz = segment.quiz;
    if (quiz == null) return;
    await Get.toNamed(AppRoutes.assessment, arguments: quiz.assessmentId);
    await load();
  }
}
