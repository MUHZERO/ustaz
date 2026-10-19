import 'package:get/get.dart';
import '../../core/network/token_store.dart';
import '../../core/routes/app_routes.dart';
import '../../data/repositories/auth_repository.dart';

class SplashController extends GetxController {
  SplashController(this._tokens, this._repository);
  final TokenStore _tokens;
  final AuthRepository _repository;

  @override
  void onReady() {
    super.onReady();
    route();
  }

  Future<void> route() async {
    if (_tokens.token == null || _tokens.token!.isEmpty) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    try {
      await _repository.me();
      Get.offAllNamed(AppRoutes.home);
    } catch (_) {
      await _tokens.clear();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
