import 'package:get/get.dart';

import '../../core/security/screen_capture_guard.dart';
import '../../data/models/segment.dart';
import '../../data/repositories/progress_repository.dart';
import 'player_controller.dart';
import 'video_source.dart';

class PlayerBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments as Map;
    Get.lazyPut(
      () => PlayerController(
        lectureId: arguments['lectureId'] as int,
        segment: arguments['segment'] as Segment,
        progressRepository: Get.find<ProgressRepository>(),
        sourceFactory: VideoSource.forPlatform,
        fallbackSourceFactory: IframeSource.new,
        captureGuard: Get.find<ScreenCaptureGuard>(),
      ),
    );
  }
}
