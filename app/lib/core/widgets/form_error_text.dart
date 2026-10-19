import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../base/base_controller.dart';

/// The controller's error message under a form, shown only in the error state.
class FormErrorText extends StatelessWidget {
  const FormErrorText({required this.controller, super.key});
  final BaseController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => controller.status.value == ViewStatus.error
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              controller.error ?? '',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          )
        : const SizedBox.shrink(),
  );
}
