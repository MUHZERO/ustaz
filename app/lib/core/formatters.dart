abstract final class Formatters {
  /// `yyyy-MM-dd` in local time; digits stay Latin in both languages.
  static String date(DateTime value) =>
      value.toLocal().toIso8601String().substring(0, 10);
}
