import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ustaz/core/formatters.dart';
import 'package:ustaz/core/i18n/plural.dart';
import 'package:ustaz/core/i18n/translations.dart';

void main() {
  setUp(() => Get.addTranslations(AppTranslations().keys));

  test('plural picks the Arabic form and falls back to other', () {
    Get.locale = const Locale('ar');
    expect('count.lectures'.plural(1), 'محاضرة واحدة');
    expect('count.lectures'.plural(2), 'محاضرتان');
    expect('count.lectures'.plural(6), '6 محاضرات');
    expect('count.lectures'.plural(11), '11 محاضرة');
    Get.locale = const Locale('en');
    expect('count.lectures'.plural(1), '1 lecture');
    expect('count.lectures'.plural(2), '2 lectures');
    expect('count.lectures'.plural(0), '0 lectures');
  });

  test('relative time switches to the date after a week', () {
    Get.locale = const Locale('en');
    final now = DateTime(2026, 10, 20, 12);
    String at(Duration age) => Formatters.relative(now.subtract(age), now: now);
    expect(at(const Duration(seconds: 20)), 'Just now');
    expect(at(const Duration(minutes: 5)), '5 min ago');
    expect(at(const Duration(hours: 3)), '3 h ago');
    expect(at(const Duration(days: 2)), '2 d ago');
    expect(at(const Duration(days: 9)), '2026-10-11');
  });
}
