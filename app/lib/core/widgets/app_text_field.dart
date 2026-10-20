import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A form field with a leading icon; password fields get a show/hide toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.icon,
    this.validator,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    super.key,
  });
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    validator: widget.validator,
    obscureText: _hidden,
    keyboardType: widget.keyboardType,
    decoration: InputDecoration(
      labelText: widget.label,
      errorText: widget.errorText,
      prefixIcon: widget.icon == null ? null : Icon(widget.icon),
      suffixIcon: widget.obscureText
          ? IconButton(
              tooltip: 'auth.show_password'.tr,
              icon: Icon(
                _hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _hidden = !_hidden),
            )
          : null,
    ),
  );
}
