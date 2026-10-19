import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/base/state_view.dart';
import '../../core/widgets/locked_badge.dart';
import '../../data/models/segment.dart';
import 'lecture_controller.dart';

class LectureView extends GetView<LectureController> {
  const LectureView({super.key});

  @override
  Widget build(BuildContext context) => StateView(
    controller: controller,
    onRetry: controller.load,
    builder: (_) {
      final lecture = controller.data.value;
      if (lecture == null) return const SizedBox.shrink();
      final segments = [...lecture.segments]
        ..sort((a, b) => a.position.compareTo(b.position));
      return ListView(
        key: const Key('lecture-segments'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              lecture.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (lecture.description != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(lecture.description!),
            ),
            const SizedBox(height: 8),
          ],
          ...segments.map(
            (segment) => ListTile(
              leading: Icon(_iconFor(segment.type)),
              title: Text(segment.title),
              trailing: _trailing(segment),
              onTap: () => controller.open(segment),
            ),
          ),
        ],
      );
    },
  );

  IconData _iconFor(SegmentType type) => switch (type) {
    SegmentType.video => Icons.play_circle_outline,
    SegmentType.pdf => Icons.picture_as_pdf_outlined,
    SegmentType.quiz => Icons.quiz_outlined,
  };

  Widget? _trailing(Segment segment) {
    if (segment.isLocked) return const LockedBadge();
    if (segment.type == SegmentType.quiz &&
        segment.isGating &&
        segment.passed == true) {
      return const Icon(Icons.check_circle_outline, color: Colors.green);
    }
    return null;
  }
}
