import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// An icon on a soft square of its own color.
class TintedIcon extends StatelessWidget {
  const TintedIcon({
    required this.icon,
    required this.color,
    this.size = 44,
    super.key,
  });
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: Icon(icon, color: color, size: size * 0.5),
  );
}
