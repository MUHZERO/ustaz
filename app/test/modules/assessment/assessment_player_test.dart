import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ustaz/core/network/api_client.dart';
import 'package:ustaz/core/network/device_id_store.dart';
import 'package:ustaz/core/network/token_store.dart';
import 'package:ustaz/data/models/attempt.dart';
import 'package:ustaz/data/models/result.dart';
import 'package:ustaz/data/repositories/assessment_repository.dart';
import 'package:ustaz/modules/assessment/player/assessment_player_controller.dart';
import 'package:ustaz/modules/assessment/player/attempt_store.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_storage.dart';

late GetStorage _storage;
final _serverStart = DateTime.utc(2026, 10, 19, 10);

void main() {
  setUpAll(() async => _storage = await openTestStorage('assessment-test'));
  setUp(() => _storage.erase());

  test('answers autosave on select', () async {
    final backend = _Backend();
    final controller = await _start(backend);

    controller.select(1, 11);
    expect(controller.answers[1], 11);
    await _settle();

    expect(backend.saved, [
      {'question_id': 1, 'option_id': 11},
    ]);
    expect(controller.pendingAnswers, isEmpty);
    expect(AttemptStore(_storage).pending(7), isEmpty);
  });

  test('pending answers are retried', () async {
    final backend = _Backend()..offline = true;
    final controller = await _start(backend);

    controller.select(1, 12);
    await _settle();
    expect(controller.answers[1], 12);
    expect(controller.pendingAnswers, {1: 12});
    expect(AttemptStore(_storage).pending(7), {1: 12});

    backend.offline = false;
    for (var i = 0; i < 5; i++) {
      controller.tick();
    }
    await _settle();

    expect(backend.saved.last, {'question_id': 1, 'option_id': 12});
    expect(controller.pendingAnswers, isEmpty);
    expect(AttemptStore(_storage).pending(7), isEmpty);
  });

  test('timer uses server deadline', () async {
    // The phone clock runs one hour ahead of the server.
    var now = _serverStart.add(const Duration(hours: 1));
    final controller = await _start(_Backend(), clock: () => now);

    expect(controller.remaining.value, const Duration(minutes: 10));
    now = now.add(const Duration(minutes: 1));
    controller.tick();
    expect(controller.remaining.value, const Duration(minutes: 9));
  });

  test('auto submits at zero', () async {
    var now = _serverStart;
    final finished = <AssessmentResult>[];
    final backend = _Backend();
    final controller = await _start(
      backend,
      clock: () => now,
      onFinished: (result, _) => finished.add(result),
    );

    now = now.add(const Duration(minutes: 10));
    controller.tick();
    controller.tick();
    await _settle();

    expect(controller.remaining.value, Duration.zero);
    expect(backend.submits, 1);
    expect(finished.single.attemptId, 7);
    expect(AttemptStore(_storage).pending(7), isEmpty);
  });

  test('resume restores answers', () async {
    AttemptStore(_storage)
      ..savePending(7, {2: 21})
      ..saveServerOffset(7, Duration.zero);
    final backend = _Backend()..serverAnswers = {'1': 11};
    final controller = await _start(backend);
    await _settle();

    expect(controller.answers, {1: 11, 2: 21});
    expect(backend.saved, [
      {'question_id': 2, 'option_id': 21},
    ]);
    expect(controller.pendingAnswers, isEmpty);
  });
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

Future<AssessmentPlayerController> _start(
  _Backend backend, {
  DateTime Function()? clock,
  AssessmentFinished? onFinished,
}) async {
  final controller = AssessmentPlayerController(
    AssessmentRepository(
      ApiClient(
        MockClient(backend.handle),
        TokenStore(_storage),
        DeviceIdStore(_storage, const Uuid()),
        'https://api.test',
      ),
    ),
    AttemptStore(_storage),
    3,
    clock: clock ?? () => _serverStart,
    periodicTimer: (_, _) => Timer(Duration.zero, () {}),
    onFinished: onFinished ?? (_, _) {},
    showMessage: (_) {},
  )..onInit();
  await _settle();
  expect(controller.attempt.value?.kind, AssessmentKind.exam);
  return controller;
}

class _Backend {
  bool offline = false;
  int submits = 0;
  Map<String, int> serverAnswers = {};
  final saved = <Map<String, dynamic>>[];

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'POST' && path == '/assessments/3/attempts') {
      return _ok(_attempt());
    }
    if (request.method == 'PUT' && path == '/attempts/7/answers') {
      if (offline) throw http.ClientException('offline');
      saved.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response('', 204);
    }
    if (request.method == 'POST' && path == '/attempts/7/submit') {
      submits++;
      return _ok(_result());
    }
    return http.Response('{"code":"not_found"}', 404);
  }

  Map<String, Object?> _attempt() => {
    'id': 7,
    'assessment_id': 3,
    'kind': 'exam',
    'started_at': _serverStart.toIso8601String(),
    'deadline_at': _serverStart
        .add(const Duration(minutes: 10))
        .toIso8601String(),
    'status': 'in_progress',
    'questions': [
      _question(1, [11, 12]),
      _question(2, [21, 22]),
    ],
    'answers': serverAnswers.isEmpty ? <Object?>[] : serverAnswers,
  };
}

Map<String, Object?> _question(int id, List<int> options) => {
  'id': id,
  'text': 'Question $id',
  'image_url': null,
  'options': [
    for (final option in options)
      {'id': option, 'text': 'Option $option', 'image_url': null},
  ],
};

Map<String, Object?> _result() => {
  'attempt_id': 7,
  'score': 1,
  'max_score': 2,
  'percent': 50,
  'passed': null,
  'submitted_at': _serverStart.toIso8601String(),
  'review_available': false,
  'review_request': null,
};

http.Response _ok(Object? data) =>
    http.Response(jsonEncode({'data': data}), 200);
