import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_tokens.dart';
import 'network_image.dart';

/// A lecture's cover: its thumbnail when there is one, otherwise a gradient
/// picked by [seed] with the lecture number and a play badge.
class LectureCover extends StatelessWidget {
  const LectureCover({
    required this.seed,
    this.number,
    this.imageUrl,
    this.compact = false,
    this.showPlay = true,
    super.key,
  });
  final int seed;
  final int? number;
  final String? imageUrl;

  /// Small list thumbnails drop the number label.
  final bool compact;

  /// Off where the card has its own play or resume button.
  final bool showPlay;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final height = box.maxHeight.isFinite ? box.maxHeight : 120.0;
      final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
      return DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.of(seed)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PositionedDirectional(
              end: -height * 0.18,
              bottom: -height * 0.28,
              child: Icon(
                Icons.auto_stories_rounded,
                size: height * 1.1,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            PositionedDirectional(
              start: -height * 0.3,
              top: -height * 0.45,
              child: Container(
                width: height,
                height: height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            if (hasImage)
              NetworkImageView(url: imageUrl, placeholder: const SizedBox()),
            if (number != null && !compact && !hasImage)
              PositionedDirectional(
                start: AppSpacing.md,
                top: AppSpacing.md,
                child: Text(
                  'lecture.number'.trParams({'n': '$number'}),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            if (showPlay)
              Center(
                child: Container(
                  width: compact ? 30 : 46,
                  height: compact ? 30 : 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.92),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 12),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: compact ? 20 : 30,
                    color: AppGradients.base(seed),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
