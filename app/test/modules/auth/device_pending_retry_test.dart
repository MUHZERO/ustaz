import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ustaz/app_bootstrap.dart';
import 'package:ustaz/core/routes/app_routes.dart';
import 'package:ustaz/main.dart';

import '../../helpers/fake_api.dart';
import '../../helpers/test_storage.dart';

late GetStorage _storage;

void main() {
  setUpAll(
    () async => _storage = await openTestStorage('device-pending-retry'),
  );

  testWidgets('retrying after device pending returns to a usable login form', (
    tester,
  ) async {
    Get.testMode = true;
    Get.reset();
    await _storage.erase();
    await _storage.write('language', 'en');
    bootstrapDependencies(
      storage: _storage,
      api: fakeApi(_storage, (_) => (404, null)),
    );

    // No token: the splash screen sends the app to login.
    await tester.pumpWidget(const UstazApp());
    await _settle(tester);
    expect(Get.currentRoute, AppRoutes.login);
    await tester.enterText(find.byType(TextFormField).first, '01025105906');

    // What LoginController does on a 403 device_pending.
    Get.toNamed<void>(AppRoutes.devicePending);
    await _settle(tester);
    await tester.tap(find.text('auth.retry_login'.tr));
    await _settle(tester);

    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(Get.currentRoute, AppRoutes.login);
    expect(find.text('01025105906'), findsOneWidget);

    await Get.deleteAll(force: true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
