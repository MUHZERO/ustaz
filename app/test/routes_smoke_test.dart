import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ustaz/app_bootstrap.dart';
import 'package:ustaz/core/routes/app_pages.dart';
import 'package:ustaz/core/routes/app_routes.dart';
import 'package:ustaz/data/models/attempt.dart';
import 'package:ustaz/data/models/segment.dart';
import 'package:ustaz/main.dart';

import 'helpers/fake_api.dart';
import 'helpers/test_storage.dart';

late GetStorage _storage;

const _date = '2026-10-01T10:00:00Z';

/// Arguments each route expects when opened from inside the app.
final _arguments = <String, Object?>{
  AppRoutes.category: 7,
  AppRoutes.lecture: 1,
  AppRoutes.player: {
    'lectureId': 1,
    'segment': Segment.fromJson(_videoSegment),
    'studentName': 'Sara',
    'studentPhone': '0550000000',
  },
  AppRoutes.pdf: {'url': 'https://cdn.test/paper.pdf', 'title': 'Paper'},
  AppRoutes.assessment: 3,
  AppRoutes.assessmentResult: {'attemptId': 5, 'kind': AssessmentKind.exam},
  AppRoutes.assessmentReview: 5,
};

void main() {
  setUpAll(() async => _storage = await openTestStorage('routes-smoke'));

  for (final (code, direction) in [
    ('ar', TextDirection.rtl),
    ('en', TextDirection.ltr),
  ]) {
    group('every route builds in ar and en ($code)', () {
      setUp(() async {
        Get.testMode = true;
        Get.reset();
        await _storage.erase();
        await _storage.write('language', code);
        await _storage.write('auth_token', 'token');
        bootstrapDependencies(
          storage: _storage,
          api: fakeApi(_storage, _respond),
        );
      });

      for (final page in AppPages.routes) {
        testWidgets(page.name, (tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(const UstazApp());
          await _settle(tester);
          if (page.name != AppRoutes.splash) {
            Get.toNamed<void>(page.name, arguments: _arguments[page.name]);
            await _settle(tester);
          }

          expect(tester.takeException(), isNull);
          expect(Get.locale?.languageCode, code);
          final scaffold = find.byType(Scaffold).last;
          expect(Directionality.of(tester.element(scaffold)), direction);

          await Get.deleteAll(force: true);
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
        });
      }
    });
  }
}

/// Lets requests, route transitions and controllers finish without waiting
/// for spinners that never stop.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

(int, Object?) _respond(http.Request request) {
  final path = request.url.path;
  Object? data = switch (path) {
    '/me' => _student,
    '/home' => {
      'announcements': [
        {'id': 1, 'title': 'News', 'body': 'Body', 'created_at': _date},
      ],
      'continue_watching': [_lectureCard],
      'categories': [categoryJson()],
      'free': [_lectureCard],
    },
    '/categories/7' => {
      'category': categoryJson(),
      'lectures': [_lectureCard],
      'exams': [
        {
          'id': 3,
          'title': 'Exam',
          'opens_at': _date,
          'closes_at': '2026-12-01T10:00:00Z',
          'duration_minutes': 30,
          'state': 'open',
          'attempt': null,
          'is_locked': false,
        },
      ],
      'papers': [
        {'id': 1, 'title': 'Paper', 'url': 'https://cdn.test/paper.pdf'},
      ],
    },
    '/lectures/1' => {
      'id': 1,
      'title': 'Vectors',
      'description': 'Intro',
      'is_free': true,
      'is_locked': false,
      'category_id': 7,
      'segments': [_videoSegment],
    },
    '/assessments/3/attempts' => {
      'id': 5,
      'assessment_id': 3,
      'kind': 'exam',
      'started_at': _date,
      'server_time': _date,
      'deadline_at': '2026-10-01T10:30:00Z',
      'status': 'in_progress',
      'questions': [_question],
      'answers': <Object?>[],
    },
    '/attempts/5/result' => _result,
    '/attempts/5/review' => [
      {
        'question': _question,
        'chosen_option_id': 1,
        'correct_option_id': 1,
        'is_correct': true,
        'explanation': 'Because',
      },
    ],
    '/me/homework' => [
      {
        'assessment_id': 4,
        'title': 'Homework',
        'lecture_id': 1,
        'attempt': null,
      },
    ],
    '/subscriptions' => [
      {'category': categoryJson(), 'starts_at': _date, 'ends_at': null},
    ],
    '/notifications' => [
      {
        'id': 'n1',
        'title': 'Hello',
        'body': 'Body',
        'data': {'route': 'results'},
        'read_at': null,
        'created_at': _date,
      },
    ],
    '/levels' => [
      {'id': 1, 'name': 'Level 1'},
    ],
    _ => null,
  };
  if (path == '/me/results') {
    return (
      200,
      {
        'data': [
          {..._result, 'title': 'Exam', 'kind': 'exam'},
        ],
        'meta': {'current_page': 1, 'last_page': 1},
      },
    );
  }
  return data == null ? (404, {'message': 'Not found'}) : (200, {'data': data});
}

const _student = {
  'id': 1,
  'name': 'Sara',
  'phone': '0550000000',
  'parent_phone': null,
  'level': {'id': 1, 'name': 'Level 1'},
  'created_at': _date,
};

const _lectureCard = {
  'id': 1,
  'title': 'Vectors',
  'position': 1,
  'is_free': true,
  'is_locked': false,
  'progress_percent': 40,
  'thumbnail_url': null,
};

const _videoSegment = {
  'id': 11,
  'type': 'video',
  'position': 1,
  'title': 'Video',
  'is_gating': false,
  'is_locked': false,
  'video': {
    'youtube_id': 'abc',
    'duration_seconds': 600,
    'last_position_seconds': 0,
  },
};

const _question = {
  'id': 1,
  'text': 'Question',
  'options': [
    {'id': 1, 'text': 'A'},
    {'id': 2, 'text': 'B'},
  ],
};

const _result = {
  'attempt_id': 5,
  'score': 1,
  'max_score': 1,
  'percent': 100,
  'submitted_at': _date,
  'review_available': true,
  'review_request': null,
};
