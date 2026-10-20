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
import 'package:ustaz/data/models/attempt.dart';
import 'package:ustaz/data/repositories/assessment_repository.dart';
import 'package:ustaz/modules/assessment/result/assessment_result_controller.dart';
import 'package:ustaz/modules/assessment/result/assessment_result_view.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_storage.dart';

late GetStorage _storage;

void main() {
  setUpAll(() async => _storage = await openTestStorage('result-test'));

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('review request is shown once for exams only', (tester) async {
    final requests = <String>[];
    await _pump(
      tester,
      AssessmentKind.exam,
      handler: (request) async {
        if (request.url.path.endsWith('/review-request')) {
          requests.add(jsonDecode(request.body)['note'] as String);
          return _ok(
            _result(reviewRequest: {'status': 'pending', 'reply': null}),
          );
        }
        return _ok(_result());
      },
    );
    expect(find.text('Request review'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('review-note')), 'Q3 is right');
    await tester.ensureVisible(find.text('Request review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request review'));
    await tester.pumpAndSettle();

    expect(requests, ['Q3 is right']);
    expect(find.text('Request review'), findsNothing);
    expect(
      find.text('Review request sent, waiting for the teacher'),
      findsOneWidget,
    );

    Get.reset();
    await _pump(tester, AssessmentKind.quiz);
    expect(find.text('Request review'), findsNothing);
  });

  testWidgets('review hidden until available', (tester) async {
    await _pump(tester, AssessmentKind.homework);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Review answers'), findsNothing);

    Get.reset();
    await _pump(
      tester,
      AssessmentKind.homework,
      handler: (_) async => _ok(_result(reviewAvailable: true)),
    );
    expect(find.text('Review answers'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  AssessmentKind kind, {
  Future<http.Response> Function(http.Request request)? handler,
}) async {
  Get.put(
    AssessmentResultController(
      AssessmentRepository(
        ApiClient(
          MockClient(handler ?? (_) async => _ok(_result())),
          TokenStore(_storage),
          DeviceIdStore(_storage, const Uuid()),
          'https://api.test',
        ),
      ),
      attemptId: 7,
      kind: kind,
    ),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      key: UniqueKey(),
      translations: AppTranslations(),
      locale: const Locale('en'),
      home: const AssessmentResultView(),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, Object?> _result({
  bool reviewAvailable = false,
  Map<String, Object?>? reviewRequest,
}) => {
  'attempt_id': 7,
  'score': 5,
  'max_score': 10,
  'percent': 50,
  'passed': null,
  'submitted_at': '2026-10-19T10:00:00Z',
  'review_available': reviewAvailable,
  'review_request': reviewRequest,
};

http.Response _ok(Object? data) =>
    http.Response(jsonEncode({'data': data}), 200);
