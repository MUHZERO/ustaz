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
