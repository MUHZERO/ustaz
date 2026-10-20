import 'package:flutter/material.dart';

/// The first letters of up to two words of [name] on a soft circle.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.name,
    this.size = 48,
    this.onImage = false,
    super.key,
  });
  final String name;
  final double size;

  /// White letters on a translucent circle, for gradient headers.
  final bool onImage;

  static String initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word.characters.first)
      .join('\u200C');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onImage
            ? Colors.white.withValues(alpha: 0.2)
            : colors.primaryContainer,
        border: onImage
            ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Text(
        initials(name),
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: onImage ? Colors.white : colors.onPrimaryContainer,
          height: 1.2,
        ),
      ),
    );
  }
}
