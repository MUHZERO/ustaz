import 'package:get/get.dart';

abstract final class Formatters {
  /// `yyyy-MM-dd` in local time; digits stay Latin in both languages. The
  /// left-to-right isolate keeps the parts in order inside Arabic text.
  static String date(DateTime value) =>
      '\u2066${value.toLocal().toIso8601String().substring(0, 10)}\u2069';

  /// "5 min ago" up to a week, then the date.
  static String relative(DateTime value, {DateTime? now}) {
    final age = (now ?? DateTime.now()).difference(value);
    String ago(String key, int n) => key.trParams({'n': '$n'});
    if (age.inMinutes < 1) return 'time.just_now'.tr;
    if (age.inHours < 1) return ago('time.minutes_ago', age.inMinutes);
    if (age.inDays < 1) return ago('time.hours_ago', age.inHours);
    if (age.inDays < 7) return ago('time.days_ago', age.inDays);
    return date(value);
  }
}
