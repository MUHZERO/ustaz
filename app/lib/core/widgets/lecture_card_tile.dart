import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/lecture_card.dart';
import '../theme/app_tokens.dart';
import 'app_badge.dart';
import 'lecture_cover.dart';
import 'locked_badge.dart';
import 'progress_bar.dart';

/// A lecture in a horizontal row: cover on top, title and progress below.
class LectureCardTile extends StatelessWidget {
  const LectureCardTile({required this.lecture, this.onTap, super.key});
  final LectureCard lecture;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 230,
    child: Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 124,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LectureCover(
                    seed: lecture.id,
                    number: lecture.position,
                    imageUrl: lecture.thumbnailUrl,
                  ),
                  PositionedDirectional(
                    end: AppSpacing.sm,
                    top: AppSpacing.sm,
                    child: _LectureFlag(lecture),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _LectureMeta(lecture, showNumber: false),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A lecture in a vertical list: small cover beside the title.
class LectureRow extends StatelessWidget {
  const LectureRow({required this.lecture, this.onTap, super.key});
  final LectureCard lecture;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: SizedBox(
                width: 104,
                height: 68,
                child: LectureCover(
                  seed: lecture.id,
                  imageUrl: lecture.thumbnailUrl,
                  compact: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _LectureMeta(lecture, showFlag: true)),
          ],
        ),
      ),
    ),
  );
}

class _LectureMeta extends StatelessWidget {
  const _LectureMeta(
    this.lecture, {
    this.showFlag = false,
    this.showNumber = true,
  });
  final LectureCard lecture;
  final bool showFlag;

  /// Off when the cover already shows the number.
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNumber)
          Row(
            children: [
              Expanded(
                child: Text(
                  'lecture.number'.trParams({'n': '${lecture.position}'}),
                  style: text.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (showFlag) _LectureFlag(lecture, onImage: false),
            ],
          ),
        Text(
          lecture.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: ProgressBar(percent: lecture.progressPercent)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${lecture.progressPercent.round()}%',
              style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

/// Locked beats free; nothing for an ordinary open lecture.
class _LectureFlag extends StatelessWidget {
  const _LectureFlag(this.lecture, {this.onImage = true});
  final LectureCard lecture;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    if (lecture.isLocked) return LockedBadge(onImage: onImage);
    if (lecture.isFree) {
      return AppBadge(
        label: 'category.free'.tr,
        color: AppColors.success,
        onImage: onImage,
      );
    }
    return const SizedBox.shrink();
  }
}
