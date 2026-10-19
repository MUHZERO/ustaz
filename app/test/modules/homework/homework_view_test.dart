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
import 'package:ustaz/core/routes/app_routes.dart';
import 'package:ustaz/data/repositories/assessment_repository.dart';
import 'package:ustaz/modules/homework/homework_controller.dart';
import 'package:ustaz/modules/homework/homework_view.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_storage.dart';

late GetStorage _storage;

void main() {
  setUpAll(() async => _storage = await openTestStorage('homework-test'));

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('homework shows not started done and score', (tester) async {
    final api = ApiClient(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {
                'assessment_id': 1,
                'title': 'New',
                'lecture_id': 5,
                'attempt': null,
              },
              {
                'assessment_id': 2,
                'title': 'Started',
                'lecture_id': 5,
                'attempt': {'id': 4, 'status': 'in_progress', 'percent': null},
              },
              {
                'assessment_id': 3,
                'title': 'Finished',
                'lecture_id': 5,
                'attempt': {'id': 5, 'status': 'submitted', 'percent': 85},
              },
            ],
          }),
          200,
        ),
      ),
      TokenStore(_storage),
      DeviceIdStore(_storage, const Uuid()),
      'https://x',
    );
    Get.put(HomeworkController(AssessmentRepository(api)));
    Object? opened;
    Object? result;
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const Scaffold(body: HomeworkView()),
        getPages: [
          GetPage(
            name: AppRoutes.assessmentResult,
            page: () {
              result = Get.arguments;
              return const SizedBox();
            },
          ),
          GetPage(
            name: AppRoutes.assessment,
            page: () {
              opened = Get.arguments;
              return const SizedBox();
            },
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not started'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);

    await tester.tap(find.text('Finished'));
    await tester.pumpAndSettle();
    expect(opened, isNull);
    expect((result! as Map)['attemptId'], 5);
    Get.back();
    await tester.pumpAndSettle();

    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });
}
