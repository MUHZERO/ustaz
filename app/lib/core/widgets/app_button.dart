import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(onPressed: onPressed, child: Text(label)),
  );
}
