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
import 'package:ustaz/modules/category/category_controller.dart';
import 'package:ustaz/modules/category/category_view.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_storage.dart';

late GetStorage _storage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => _storage = await openTestStorage('category-test'));

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('category lists lectures exams and papers', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = await _controller(_categoryJson());
    await _pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Lecture'), findsOneWidget);
    expect(find.text('Exam'), findsOneWidget);
    expect(find.text('Paper'), findsOneWidget);
  });

  testWidgets('locked category shows redeem cta', (tester) async {
    final controller = await _controller(_categoryJson(isSubscribed: false));
    await _pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Subscribe or redeem a code'), findsOneWidget);
    expect(find.text('Redeem code'), findsOneWidget);
  });

  testWidgets('exam card shows state label', (tester) async {
    final controller = await _controller(_categoryJson(examState: 'upcoming'));
    await _pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsOneWidget);
  });
}

Future<CategoryController> _controller(Map<String, Object?> body) async {
  final api = ApiClient(
    MockClient((_) async => http.Response(jsonEncode({'data': body}), 200)),
    TokenStore(_storage),
    DeviceIdStore(_storage, const Uuid()),
    'https://api.test',
  );
  final controller = CategoryController(ContentRepository(api), 1);
  Get.put(controller);
  return controller;
}

Future<void> _pump(WidgetTester tester, CategoryController controller) =>
    tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const Scaffold(body: CategoryView()),
      ),
    );

Map<String, Object?> _categoryJson({
  bool isSubscribed = true,
  String examState = 'open',
}) => {
  'category': {
    'id': 1,
    'name': 'Category',
    'position': 1,
    'is_free': false,
    'is_subscribed': isSubscribed,
    'ends_at': null,
    'lectures_count': 1,
    'exams_count': 1,
    'papers_count': 1,
  },
  'lectures': [
    {
      'id': 1,
      'title': 'Lecture',
      'position': 1,
      'is_free': false,
      'is_locked': false,
      'progress_percent': 25,
      'thumbnail_url': null,
    },
  ],
  'exams': [
    {
      'id': 1,
      'title': 'Exam',
      'opens_at': '2026-10-20T10:00:00Z',
      'closes_at': '2026-10-21T10:00:00Z',
      'duration_minutes': 30,
      'state': examState,
      'attempt': null,
      'is_locked': false,
    },
  ],
  'papers': [
    {'id': 1, 'title': 'Paper', 'url': 'https://example.test/paper.pdf'},
  ],
};
