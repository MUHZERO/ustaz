import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ustaz/core/i18n/translations.dart';
import 'package:ustaz/core/network/api_client.dart';
import 'package:ustaz/core/network/device_id_store.dart';
import 'package:ustaz/core/network/token_store.dart';
import 'package:ustaz/data/repositories/content_repository.dart';
import 'package:ustaz/modules/lecture/lecture_controller.dart';
import 'package:ustaz/modules/lecture/lecture_view.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_storage.dart';

late GetStorage _storage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => _storage = await openTestStorage('lecture-test'));

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('segments render in position order', (tester) async {
    final controller = await _controller(_lectureJson());
    await _pump(tester, controller);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('First')).dy,
      lessThan(tester.getTopLeft(find.text('Second')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Second')).dy,
      lessThan(tester.getTopLeft(find.text('Third')).dy),
    );
  });

  testWidgets('tapping locked segment opens the gating quiz', (tester) async {
    final controller = await _controller(_lectureJson());
    await _pump(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Third'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('assessment-20'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('passing quiz refreshes locks', (tester) async {
    var requests = 0;
    final controller = await _controller(
      _lectureJson(),
      onRequest: () => requests++,
      response: () => _lectureJson(locked: requests < 2),
    );
    await _pump(tester, controller);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    await tester.tap(find.text('Second'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('assessment-20'), findsOneWidget);
    await tester.tap(find.text('finish-assessment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(requests, greaterThanOrEqualTo(2));
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}

Future<LectureController> _controller(
  Map<String, Object?> body, {
  void Function()? onRequest,
  Map<String, Object?> Function()? response,
}) async {
  final api = ApiClient(
    MockClient((_) async {
      onRequest?.call();
      return http.Response(jsonEncode({'data': response?.call() ?? body}), 200);
    }),
    TokenStore(_storage),
    DeviceIdStore(_storage, const Uuid()),
    'https://api.test',
  );
  final controller = LectureController(
    ContentRepository(api),
    1,
    showLockedMessage: (_, _) {},
  );
  Get.put(controller);
  return controller;
}

Future<void> _pump(WidgetTester tester, LectureController controller) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en'),
      getPages: [
        GetPage(
          name: '/assessment',
          page: () => Scaffold(
            body: Column(
              children: [
                Text('assessment-${Get.arguments}'),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('finish-assessment'),
                ),
              ],
            ),
          ),
        ),
      ],
      home: const Scaffold(body: LectureView()),
    ),
  );
}

Map<String, Object?> _lectureJson({bool locked = true}) => {
  'id': 1,
  'title': 'Lecture',
  'description': null,
  'is_free': true,
  'is_locked': false,
  'category_id': 1,
  'segments': [
    {
      'id': 30,
      'type': 'video',
      'position': 3,
      'title': 'Third',
      'is_gating': false,
      'is_locked': locked,
      'passed': null,
    },
    {
      'id': 20,
      'type': 'quiz',
      'position': 2,
      'title': 'Second',
      'is_gating': true,
      'is_locked': false,
      'passed': false,
      'quiz': {'assessment_id': 20, 'pass_percent': 50, 'best_percent': null},
    },
    {
      'id': 10,
      'type': 'pdf',
      'position': 1,
      'title': 'First',
      'is_gating': false,
      'is_locked': false,
      'passed': null,
      'pdf': {'url': 'https://example.test/first.pdf'},
    },
  ],
};
