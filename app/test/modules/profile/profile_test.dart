import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ustaz/core/i18n/translations.dart';
import 'package:ustaz/core/network/device_id_store.dart';
import 'package:ustaz/core/network/token_store.dart';
import 'package:ustaz/data/repositories/access_repository.dart';
import 'package:ustaz/data/repositories/auth_repository.dart';
import 'package:ustaz/modules/profile/profile_controller.dart';
import 'package:ustaz/modules/profile/profile_view.dart';
import 'package:ustaz/services/auth_service.dart';
import 'package:ustaz/services/settings_service.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/fake_api.dart';
import '../../helpers/test_storage.dart';

late GetStorage _storage;

void main() {
  setUpAll(() async {
    _storage = await openTestStorage('profile-test');
    await DeviceIdStore(_storage, const Uuid()).id();
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('lifetime subscription label', (tester) async {
    await _pump(tester);

    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('مدى الحياة'), findsOneWidget);
    expect(find.text('ينتهي في \u20662027-06-30\u2069'), findsOneWidget);
  });

  testWidgets('language toggle switches to ltr', (tester) async {
    await _pump(tester);
    final profile = find.byType(ProfileView);
    expect(Directionality.of(tester.element(profile)), TextDirection.rtl);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(Get.locale, const Locale('en'));
    expect(Directionality.of(tester.element(profile)), TextDirection.ltr);
    expect(find.text('Lifetime'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester) async {
  final api = fakeApi(
    _storage,
    (request) => switch (request.url.path) {
      '/me' => (200, {'data': _student}),
      _ => (
        200,
        {
          'data': [
            {
              'category': categoryJson(name: 'Physics'),
              'starts_at': '2026-01-01T00:00:00Z',
              'ends_at': null,
            },
            {
              'category': categoryJson(name: 'Chemistry'),
              'starts_at': '2026-01-01T00:00:00Z',
              'ends_at': '2027-06-30T12:00:00Z',
            },
          ],
        },
      ),
    },
  );
  final tokens = TokenStore(_storage);
  final session = Get.put(AuthService(api, tokens));
  Get.put(
    ProfileController(
      AuthRepository(api, tokens, DeviceIdStore(_storage, const Uuid())),
      AccessRepository(api),
      session,
      SettingsService(_storage),
    ),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('ar'),
      home: const Scaffold(body: ProfileView()),
    ),
  );
  await tester.pumpAndSettle();
}

const _student = {
  'id': 1,
  'name': 'Student',
  'phone': '01012345678',
  'parent_phone': null,
  'level': {'id': 1, 'name': 'One'},
  'created_at': '2026-01-01T00:00:00Z',
};
