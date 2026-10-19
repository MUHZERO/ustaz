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
import 'package:ustaz/modules/home/home_controller.dart';
import 'package:ustaz/modules/home/home_view.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_storage.dart';

late GetStorage _storage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => _storage = await openTestStorage('home-test'));

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('home shows sections from api', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = await _controller(_homeJson());
    await _pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Announcement'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
  });

  testWidgets('empty continue watching hides section', (tester) async {
    final controller = await _controller(_homeJson(continueWatching: const []));
    await _pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Continue watching'), findsNothing);
  });

  testWidgets('pull to refresh reloads', (tester) async {
    var calls = 0;
    final controller = await _controller(_homeJson(), onRequest: () => calls++);
    await _pump(tester, controller);
    await tester.pumpAndSettle();
    final before = calls;

    await tester.fling(
      find.byKey(const Key('home-list')),
      const Offset(0, 400),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(calls, greaterThan(before));
  });
}

Future<HomeController> _controller(
  Map<String, Object?> body, {
  void Function()? onRequest,
}) async {
  final storage = _storage;
  final api = ApiClient(
    MockClient((_) async {
      onRequest?.call();
      return http.Response(jsonEncode({'data': body}), 200);
    }),
    TokenStore(storage),
    DeviceIdStore(storage, const Uuid()),
    'https://api.test',
  );
  final controller = HomeController(ContentRepository(api));
  Get.put(controller);
  return controller;
}

Future<void> _pump(WidgetTester tester, HomeController controller) =>
    tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: Scaffold(body: HomeView()),
      ),
    );

Map<String, Object?> _homeJson({List<Object?>? continueWatching}) => {
  'announcements': [
    {
      'id': 1,
      'title': 'Announcement',
      'body': null,
      'image_url': null,
      'created_at': '2026-01-01T00:00:00Z',
    },
  ],
  'continue_watching': continueWatching ?? [_lecture('Continue')],
  'categories': [
    {
      'id': 1,
      'name': 'Category',
      'position': 1,
      'is_free': false,
      'is_subscribed': true,
      'ends_at': null,
      'lectures_count': 1,
      'exams_count': 0,
      'papers_count': 0,
    },
  ],
  'free': [_lecture('Free')],
};

Map<String, Object?> _lecture(String title) => {
  'id': 1,
  'title': title,
  'position': 1,
  'is_free': true,
  'is_locked': false,
  'progress_percent': 25,
  'thumbnail_url': null,
};
