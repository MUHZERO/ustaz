import 'package:get/get.dart';

extension Plural on String {
  /// `'count.lectures'.plural(3)` → the `few` form with `@n` = 3. Forms follow
  /// Arabic (zero, one, two, few for 3–10, other); a language that lacks a form
  /// falls back to `other`.
  String plural(int n) {
    final form = switch (n) {
      0 => 'zero',
      1 => 'one',
      2 => 'two',
      >= 3 && <= 10 => 'few',
      _ => 'other',
    };
    var key = '$this.$form';
    if (key.tr == key) key = '$this.other';
    return key.trParams({'n': '$n'});
  }
}
