import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'core/config/env.dart';
import 'core/network/api_client.dart';
import 'core/network/device_id_store.dart';
import 'core/network/token_store.dart';
import 'data/repositories/assessment_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/content_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'core/security/screen_capture_guard.dart';
import 'modules/assessment/player/attempt_store.dart';
import 'services/auth_service.dart';

void bootstrapDependencies() {
  final storage = GetStorage();
  Get.put(TokenStore(storage), permanent: true);
  Get.put(DeviceIdStore(storage, const Uuid()), permanent: true);
  Get.put(
    ApiClient(http.Client(), Get.find(), Get.find(), Env.apiUrl),
    permanent: true,
  );
  Get.put(AuthRepository(Get.find(), Get.find(), Get.find()), permanent: true);
  Get.put(ContentRepository(Get.find()), permanent: true);
  Get.put(ProgressRepository(Get.find()), permanent: true);
  Get.put(AssessmentRepository(Get.find()), permanent: true);
  Get.put(AttemptStore(storage), permanent: true);
  Get.put(ScreenCaptureGuard(), permanent: true);
  Get.put(AuthService(Get.find(), Get.find()), permanent: true);
}
