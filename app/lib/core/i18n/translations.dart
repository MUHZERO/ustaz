import 'package:get/get.dart';
import 'ar.dart';
import 'en.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => const {'ar': ar, 'en': en};
}
