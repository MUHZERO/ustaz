import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ustaz/core/network/api_client.dart';
import 'package:ustaz/core/network/device_id_store.dart';
import 'package:ustaz/core/network/token_store.dart';
import 'package:ustaz/core/security/screen_capture_guard.dart';
import 'package:ustaz/core/security/watermark.dart';
import 'package:ustaz/data/models/segment.dart';
import 'package:ustaz/data/repositories/progress_repository.dart';
import 'package:ustaz/modules/player/player_controller.dart';
import 'package:ustaz/modules/player/video_source.dart';
import 'package:ustaz/services/progress_reporter.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GetStorage storage;

  setUpAll(() async => storage = await openTestStorage('player-test'));

  test(
    'resumes at last position and pauses while screen is captured',
    () async {
      final capture = StreamController<bool>();
      final source = _FakeSource();
      final controller = PlayerController(
        lectureId: 1,
        segment: _segment(),
        progressRepository: _progressRepository(
          storage,
          (_) async => http.Response('', 204),
        ),
        sourceFactory: () => source,
        captureGuard: ScreenCaptureGuard(capturedStream: capture.stream),
      )..onInit();

      await Future<void>.delayed(Duration.zero);
      expect(source.startedAt, const Duration(seconds: 12));
      capture.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(source.paused, isTrue);
      controller.onClose();
    },
  );

  test('reports progress and keeps the maximum watched position', () async {
    final reports = <Map<String, dynamic>>[];
    final reporter = ProgressReporter(
      repository: _progressRepository(storage, (request) async {
        reports.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response('', 204);
      }),
      lectureId: 1,
      segmentId: 2,
    );
    reporter.update(const Duration(seconds: 30));
    reporter.update(const Duration(seconds: 20));
    await reporter.report();
    expect(reports.single, {
      'segment_id': 2,
      'position_seconds': 20,
      'watched_seconds': 30,
    });
  });

  test('player falls back on resolve error', () async {
    final fallback = _FakeSource();
    final controller = PlayerController(
      lectureId: 1,
      segment: _segment(),
      progressRepository: _progressRepository(
        storage,
        (_) async => http.Response('', 204),
      ),
      sourceFactory: _FailingSource.new,
      fallbackSourceFactory: () => fallback,
      captureGuard: ScreenCaptureGuard(capturedStream: const Stream.empty()),
    )..onInit();
    await Future<void>.delayed(Duration.zero);
    expect(controller.source.value, same(fallback));
    controller.onClose();
  });

  testWidgets('watermark shows student name and phone without video id text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 300,
          height: 200,
          child: Watermark(
            studentName: 'Student',
            studentPhone: '01012345678',
            child: SizedBox(),
          ),
        ),
      ),
    );
    expect(find.textContaining('Student'), findsOneWidget);
    expect(find.textContaining('01012345678'), findsOneWidget);
    expect(find.text('secret-video-id'), findsNothing);
  });
}

ProgressRepository _progressRepository(
  GetStorage storage,
  Future<http.Response> Function(http.Request request) handler,
) => ProgressRepository(
  ApiClient(
    MockClient(handler),
    TokenStore(storage),
    DeviceIdStore(storage, const Uuid()),
    'https://api.test',
  ),
);

Segment _segment() => const Segment(
  id: 2,
  type: SegmentType.video,
  position: 1,
  title: 'Video',
  isGating: false,
  isLocked: false,
  video: SegmentVideo(
    youtubeId: 'secret-video-id',
    durationSeconds: 100,
    lastPositionSeconds: 12,
  ),
);

class _FakeSource implements VideoSource {
  final positions = StreamController<Duration>.broadcast();
  Duration? startedAt;
  bool paused = false;
  @override
  Future<void> dispose() async => positions.close();
  @override
  Future<void> init(String _, Duration startAt) async => startedAt = startAt;
  @override
  void pause() => paused = true;
  @override
  Stream<Duration> get position => positions.stream;
  @override
  Widget view() => const SizedBox();
}

class _FailingSource extends _FakeSource {
  @override
  Future<void> init(String _, Duration _) => Future.error(Exception());
}
