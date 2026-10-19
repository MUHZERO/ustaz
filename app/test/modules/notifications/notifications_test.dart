import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ustaz/core/i18n/translations.dart';
import 'package:ustaz/core/network/device_id_store.dart';
import 'package:ustaz/data/repositories/notification_repository.dart';
import 'package:ustaz/modules/notifications/notifications_controller.dart';
import 'package:ustaz/modules/notifications/notifications_view.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/fake_api.dart';
import '../../helpers/test_storage.dart';

late GetStorage _storage;

void main() {
  setUpAll(() async {
    _storage = await openTestStorage('notifications-test');
    await DeviceIdStore(_storage, const Uuid()).id();
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('inbox marks item read on open', (tester) async {
    final requests = <http.Request>[];
    final api = fakeApi(
      _storage,
      (request) => request.method == 'GET'
          ? (
              200,
              {
                'data': [
                  {
                    'id': 'abc',
                    'title': 'New exam',
                    'body': 'Physics exam opens tomorrow',
                    'data': {'route': 'notifications'},
                    'read_at': null,
                    'created_at': '2026-10-19T10:00:00Z',
                  },
                ],
                'meta': {'current_page': 1, 'last_page': 1},
              },
            )
          : (204, null),
      requests: requests,
    );
    final controller = Get.put(
      NotificationsController(NotificationRepository(api)),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const Scaffold(body: NotificationsView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);

    await tester.tap(find.text('New exam'));
    await tester.pumpAndSettle();

    expect(controller.items.single.isRead, isTrue);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(
      requests.map((request) => '${request.method} ${request.url.path}'),
      contains('POST /notifications/abc/read'),
    );
  });
}
