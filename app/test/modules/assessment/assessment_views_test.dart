import 'dart:async';
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
import 'package:ustaz/modules/assessment/player/assessment_player_controller.dart';
import 'package:ustaz/modules/assessment/player/assessment_player_view.dart';
import 'package:ustaz/modules/assessment/player/attempt_store.dart';
import 'package:ustaz/modules/assessment/review/assessment_review_controller.dart';
import 'package:ustaz/modules/assessment/review/assessment_review_view.dart';
import 'package:uuid/uuid.dart';
import '../../helpers/test_storage.dart';

late GetStorage s;

final start = DateTime.utc(2026);
Map<String, Object?> q(int id) => {
  'id': id,
  'text': 'Q$id',
  'image_url': null,
  'options': [
    {'id': id * 10, 'text': 'O${id * 10}', 'image_url': null},
    {'id': id * 10 + 1, 'text': 'O${id * 10 + 1}', 'image_url': null},
  ],
};
void main() {
  setUpAll(() async => s = await openTestStorage('smoke'));
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  testWidgets('player renders', (t) async {
    final api = ApiClient(
      MockClient((r) async {
        if (r.url.path.endsWith('/attempts')) {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 7,
                'assessment_id': 3,
                'kind': 'quiz',
                'started_at': start.toIso8601String(),
                'deadline_at': start
                    .add(const Duration(minutes: 5))
                    .toIso8601String(),
                'status': 'in_progress',
                'questions': [q(1), q(2)],
                'answers': [],
              },
            }),
            200,
          );
        }
        return http.Response('', 204);
      }),
      TokenStore(s),
      DeviceIdStore(s, const Uuid()),
      'https://x',
    );
    Get.put(
      AssessmentPlayerController(
        AssessmentRepository(api),
        AttemptStore(s),
        3,
        clock: () => start,
        periodicTimer: (_, _) => Timer(Duration.zero, () {}),
      ),
    );
    await t.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('ar'),
        home: const AssessmentPlayerView(),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('Q1'), findsOneWidget);
    await t.tap(find.text('O11'));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    await t.tap(find.text('2'));
    await t.pumpAndSettle();
    expect(find.text('Q2'), findsOneWidget);
    await t.tap(find.text('تسليم'));
    await t.pumpAndSettle();
    expect(find.text('إلغاء'), findsOneWidget);
  });
  testWidgets('review renders', (t) async {
    final api = ApiClient(
      MockClient(
        (r) async => http.Response(
          jsonEncode({
            'data': [
              {
                'question': q(1),
                'chosen_option_id': null,
                'correct_option_id': 10,
                'is_correct': false,
                'explanation': 'Because',
              },
            ],
          }),
          200,
        ),
      ),
      TokenStore(s),
      DeviceIdStore(s, const Uuid()),
      'https://x',
    );
    Get.put(AssessmentReviewController(AssessmentRepository(api), 7));
    await t.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const AssessmentReviewView(),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Because'), findsOneWidget);
    expect(find.text('Not answered'), findsOneWidget);
  });
}
