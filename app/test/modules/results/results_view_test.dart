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
import 'package:ustaz/data/repositories/assessment_repository.dart';
import 'package:ustaz/modules/homework/homework_controller.dart';
import 'package:ustaz/modules/results/results_controller.dart';
import 'package:ustaz/modules/results/results_view.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_storage.dart';

late GetStorage _storage;

Map<String, Object?> _result(int id) => {
  'attempt_id': id,
  'title': 'Result $id',
  'kind': 'exam',
  'score': 8,
  'max_score': 10,
  'percent': 80,
  'passed': null,
  'submitted_at': '2026-10-19T10:00:00Z',
  'review_available': false,
  'review_request': null,
};

void main() {
  setUpAll(() async => _storage = await openTestStorage('results-test'));

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('results paginate', (tester) async {
    final pages = <String?>[];
    final api = ApiClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/me/homework')) {
          return http.Response(jsonEncode({'data': []}), 200);
        }
        final page = int.parse(request.url.queryParameters['page']!);
        pages.add('$page');
        final first = (page - 1) * 20 + 1;
        return http.Response(
          jsonEncode({
            'data': [
              for (var id = first; id < first + (page == 1 ? 20 : 3); id++)
                _result(id),
            ],
            'meta': {
              'current_page': page,
              'last_page': 2,
              'per_page': 20,
              'total': 23,
            },
          }),
          200,
        );
      }),
      TokenStore(_storage),
      DeviceIdStore(_storage, const Uuid()),
      'https://x',
    );
    final repository = AssessmentRepository(api);
    Get.put(ResultsController(repository));
    Get.put(HomeworkController(repository));
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const Scaffold(body: ResultsView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Result 1'), findsOneWidget);
    expect(pages, ['1']);

    await tester.scrollUntilVisible(
      find.text('Result 23'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(pages, ['1', '2']);
    expect(find.text('Result 23'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
