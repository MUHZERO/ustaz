import 'dart:async';
import 'package:get/get.dart';
import '../core/network/api_client.dart';
import '../core/network/token_store.dart';
import '../core/routes/app_routes.dart';

class AuthService extends GetxService {
  AuthService(this._api, this._tokens);
  final ApiClient _api;
  final TokenStore _tokens;
  StreamSubscription<String?>? _subscription;
  bool _routing = false;

  @override
  void onInit() {
    super.onInit();
    _subscription = _api.onUnauthorized.listen((_) async {
      if (_routing) return;
      _routing = true;
      await _tokens.clear();
      Get.offAllNamed(AppRoutes.login);
      _routing = false;
    });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
