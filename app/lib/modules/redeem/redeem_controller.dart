import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/category.dart';
import '../../data/repositories/access_repository.dart';

class RedeemController extends BaseController {
  RedeemController(this._repository);
  static const _codeErrors = {'code_invalid', 'code_expired', 'code_used_up'};
  final AccessRepository _repository;
  final formKey = GlobalKey<FormState>();
  final code = TextEditingController();
  final category = Rxn<Category>();

  Future<void> redeem() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await run(() async {
      try {
        category.value = await _repository.redeem(code.text.trim());
      } on ApiException catch (error) {
        if (!_codeErrors.contains(error.code)) rethrow;
        throw ApiException(
          statusCode: error.statusCode,
          code: error.code,
          message: 'redeem.${error.code}'.tr,
        );
      }
    });
  }

  @override
  void onClose() {
    code.dispose();
    super.onClose();
  }
}
