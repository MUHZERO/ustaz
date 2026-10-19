import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ustaz/core/network/api_client.dart';
import 'package:ustaz/core/network/device_id_store.dart';
import 'package:ustaz/core/network/token_store.dart';
import 'package:ustaz/core/validators.dart';
import 'package:ustaz/data/repositories/auth_repository.dart';
import 'package:ustaz/modules/auth/device_pending/device_pending_controller.dart';
import 'package:ustaz/modules/auth/device_pending/device_pending_view.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('register validates egyptian phone', () {
    expect(Validators.phone('01012345678'), isNull);
    expect(Validators.phone('01112345678'), isNull);
    expect(Validators.phone('01212345678'), isNull);
    expect(Validators.phone('01512345678'), isNull);
    expect(Validators.phone('01912345678'), isNotNull);
  });

  test('login stores token and opens home', () async {
    final storage = await openTestStorage('auth-login-test');
    final store = TokenStore(storage);
    final deviceIds = DeviceIdStore(storage, const Uuid());
    final api = ApiClient(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'token': 'student-token',
              'student': {
                'id': 1,
                'name': 'Student',
                'phone': '01012345678',
                'parent_phone': null,
                'level': {'id': 1, 'name': 'One'},
                'created_at': '2026-01-01T00:00:00Z',
              },
            },
          }),
          200,
        ),
      ),
      store,
      deviceIds,
      'https://api.test',
    );

    await AuthRepository(
      api,
      store,
      deviceIds,
    ).login('01012345678', 'password1');

    expect(store.token, 'student-token');
  });

  testWidgets('device pending shows waiting screen', (tester) async {
    Get.put(DevicePendingController());
    await tester.pumpWidget(
      GetMaterialApp(
        translations: _Translations(),
        locale: const Locale('en'),
        home: const DevicePendingView(),
      ),
    );

    expect(find.text('Waiting for teacher approval'), findsOneWidget);
  });

  test('splash routes by token presence', () async {
    final store = TokenStore(await openTestStorage('splash-test'));
    expect(store.token, isNull);
    await store.save('token');
    expect(store.token, 'token');
  });
}

class _Translations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => const {
    'en': {
      'auth.waiting_title': 'Waiting for teacher approval',
      'auth.waiting_body': 'Body',
      'auth.retry_login': 'Retry login',
    },
  };
}
