import 'package:get/get.dart';
import '../network/api_exception.dart';

enum ViewStatus { idle, loading, success, empty, error }

abstract class BaseController extends GetxController {
  final status = ViewStatus.idle.obs;
  String? error;
  Future<void> run(Future<void> Function() task) async {
    status.value = ViewStatus.loading;
    error = null;
    try {
      await task();
      status.value = ViewStatus.success;
    } on ApiException catch (exception) {
      error = exception.message;
      status.value = ViewStatus.error;
    } catch (_) {
      error = 'errors.generic'.tr;
      status.value = ViewStatus.error;
    }
  }
}
