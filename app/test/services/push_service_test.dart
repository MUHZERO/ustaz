import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ustaz/core/network/device_id_store.dart';
import 'package:ustaz/core/routes/app_routes.dart';
import 'package:ustaz/data/models/attempt.dart';
import 'package:ustaz/data/repositories/notification_repository.dart';
import 'package:ustaz/services/push_service.dart';
import 'package:uuid/uuid.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_storage.dart';

late GetStorage _storage;

void main() {
  setUpAll(() async {
    _storage = await openTestStorage('push-test');
    await DeviceIdStore(_storage, const Uuid()).id();
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  test('push disabled without firebase config', () async {
    final requests = <http.Request>[];
    final push = PushService(
      NotificationRepository(
        fakeApi(_storage, (_) => (204, null), requests: requests),
      ),
    );

    await push.init();

    expect(push.enabled, isFalse);
    expect(requests, isEmpty);
  });

  testWidgets('tap routes to lecture', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Text('root')),
          GetPage(
            name: AppRoutes.lecture,
            page: () => Text('lecture ${Get.arguments}'),
          ),
        ],
      ),
    );

    PushService.openRoute({'route': 'lecture', 'lecture_id': '5'});
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.lecture);
    expect(find.text('lecture 5'), findsOneWidget);
  });

  testWidgets('review decision routes to the exam result', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Text('root')),
          GetPage(
            name: AppRoutes.assessmentResult,
            page: () => Text('result ${Get.arguments}'),
          ),
        ],
      ),
    );

    PushService.openRoute({'route': 'result', 'attempt_id': '9'});
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.assessmentResult);
    expect(Get.arguments, {'attemptId': 9, 'kind': AssessmentKind.exam});
  });
}
