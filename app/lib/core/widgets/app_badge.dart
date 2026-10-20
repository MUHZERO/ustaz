import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// A small rounded label: status, price, lock, pass or fail.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    required this.color,
    this.icon,
    this.onImage = false,
    super.key,
  });
  final String label;
  final Color color;
  final IconData? icon;

  /// White on a translucent fill, for badges drawn over a gradient.
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final foreground = onImage ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.black.withValues(alpha: 0.22)
            : color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
