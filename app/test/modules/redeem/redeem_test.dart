import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ustaz/core/i18n/translations.dart';
import 'package:ustaz/core/network/device_id_store.dart';
import 'package:ustaz/data/repositories/access_repository.dart';
import 'package:ustaz/modules/redeem/redeem_controller.dart';
import 'package:ustaz/modules/redeem/redeem_view.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/fake_api.dart';
import '../../helpers/test_storage.dart';

late GetStorage _storage;

void main() {
  setUpAll(() async {
    _storage = await openTestStorage('redeem-test');
    await DeviceIdStore(_storage, const Uuid()).id();
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('redeem shows category on success', (tester) async {
    await _pump(tester, (
      200,
      {
        'data': {'category': categoryJson(name: 'Physics')},
      },
    ));

    await _submit(tester, 'ABC-123');

    expect(find.text('You are now subscribed to Physics'), findsOneWidget);
    expect(find.text('Open category'), findsOneWidget);
  });

  testWidgets('redeem maps code_expired to message', (tester) async {
    await _pump(tester, (
      422,
      {
        'message': 'server text',
        'code': 'code_expired',
        'errors': {
          'code': ['server text'],
        },
      },
    ));

    await _submit(tester, 'OLD-CODE');

    expect(find.text('This code has expired.'), findsOneWidget);
    expect(find.text('server text'), findsNothing);
  });
}

Future<void> _pump(WidgetTester tester, (int, Object?) response) async {
  Get.put(
    RedeemController(AccessRepository(fakeApi(_storage, (_) => response))),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en'),
      home: const RedeemView(),
    ),
  );
}

Future<void> _submit(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextFormField), code);
  await tester.tap(find.text('Activate'));
  await tester.pumpAndSettle();
}
