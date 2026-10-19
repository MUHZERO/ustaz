import 'package:get/get.dart';

abstract final class Validators {
  static final _egyptianPhone = RegExp(r'^01[0125][0-9]{8}$');

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'validation.required'.tr;
    return _egyptianPhone.hasMatch(value.trim()) ? null : 'validation.phone'.tr;
  }

  static String? optionalPhone(String? value) =>
      value == null || value.trim().isEmpty ? null : phone(value);

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'validation.required'.tr;
    return value.length >= 8 ? null : 'validation.password'.tr;
  }

  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'validation.required'.tr : null;
}
