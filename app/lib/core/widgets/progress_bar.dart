import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    required this.percent,
    this.color,
    this.trackColor,
    super.key,
  });
  final num percent;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
    value: (percent / 100).clamp(0, 1).toDouble(),
    color: color,
    backgroundColor: trackColor,
  );
}
