import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/base/state_view.dart';
import '../../core/i18n/plural.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/lecture_cover.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lecture.dart';
import '../../data/models/segment.dart';
import 'lecture_controller.dart';

class LectureView extends GetView<LectureController> {
  const LectureView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      leading: Navigator.canPop(context)
          ? Center(
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.28),
                  foregroundColor: Colors.white,
                ),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const BackButtonIcon(),
                onPressed: () => Navigator.maybePop(context),
              ),
            )
          : null,
    ),
    body: StateView(
      controller: controller,
      onRetry: controller.load,
      builder: (_) {
        final lecture = controller.data.value;
        if (lecture == null) return const SizedBox.shrink();
        final segments = [...lecture.segments]
          ..sort((a, b) => a.position.compareTo(b.position));
        return ListView(
          key: const Key('lecture-segments'),
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            _Header(
              lecture,
              progress: controller.progressPercent,
              onPlay: switch (segments.where(
                (segment) =>
                    segment.type == SegmentType.video && !segment.isLocked,
              )) {
                final videos when videos.isNotEmpty => () => controller.open(
                  videos.first,
                ),
                _ => null,
              },
            ),
            SectionHeader(
              title: 'lecture.content'.tr,
              trailing: Text(
                'count.segments'.plural(segments.length),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final (index, segment) in segments.indexed)
              _SegmentStep(
                segment,
                number: index + 1,
                isLast: index == segments.length - 1,
                onTap: () => controller.open(segment),
              ),
          ],
        );
      },
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header(this.lecture, {required this.progress, this.onPlay});
  final Lecture lecture;
  final int progress;

  /// Opens the first playable video; the cover shows a play button for it.
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final background = Theme.of(context).scaffoldBackgroundColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 210 + MediaQuery.paddingOf(context).top,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: onPlay,
                child: LectureCover(seed: lecture.id, showPlay: onPlay != null),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -1,
                height: AppRadii.xl,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.xl),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lecture.isFree) ...[
                AppBadge(
                  label: 'category.free'.tr,
                  icon: Icons.card_giftcard_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(lecture.title, style: text.headlineSmall),
              if (lecture.description != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  lecture.description!,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up_rounded, color: colors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: ProgressBar(percent: progress)),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'percent_done'.trParams({'percent': '$progress'}),
                        style: text.labelLarge?.copyWith(color: colors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One step of the lecture timeline: numbered circle, connector and card.
class _SegmentStep extends StatelessWidget {
  const _SegmentStep(
    this.segment, {
    required this.number,
    required this.isLast,
    required this.onTap,
  });
  final Segment segment;
  final int number;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final done = LectureController.isDone(segment) ?? false;
    final gating = segment.type == SegmentType.quiz && segment.isGating;
    final (typeIcon, typeColor) = switch (segment.type) {
      SegmentType.video => (Icons.play_circle_rounded, colors.primary),
      SegmentType.pdf => (Icons.picture_as_pdf_rounded, colors.error),
      SegmentType.quiz => (Icons.quiz_rounded, AppColors.warning),
    };
    final video = segment.video;
    final highlight = gating && !done && !segment.isLocked;
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _StepCircle(
                    number: number,
                    done: done,
                    locked: segment.isLocked,
                    highlight: highlight,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: AppSpacing.xs),
                        color: done
                            ? AppColors.success.withValues(alpha: 0.5)
                            : colors.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Card(
                  shape: highlight
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          side: BorderSide(color: colors.secondary, width: 1.6),
                        )
                      : null,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md + 2),
                      child: Opacity(
                        opacity: segment.isLocked ? 0.6 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: [
                                AppBadge(
                                  label: 'lecture.type_${segment.type.name}'.tr,
                                  icon: typeIcon,
                                  color: typeColor,
                                ),
                                if (video != null && video.durationSeconds > 0)
                                  AppBadge(
                                    label: 'minutes'.trParams({
                                      'n':
                                          '${(video.durationSeconds / 60).ceil()}',
                                    }),
                                    icon: Icons.schedule_rounded,
                                    color: colors.onSurfaceVariant,
                                  ),
                                if (gating)
                                  AppBadge(
                                    label: 'lecture.gating'.tr,
                                    icon: Icons.flag_rounded,
                                    color: AppColors.warning,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(segment.title, style: text.titleSmall),
                            if (segment.isLocked)
                              Text(
                                'lecture.locked_reason'.tr,
                                style: text.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              )
                            else if (gating && segment.quiz != null)
                              Text(
                                'lecture.pass_mark'.trParams({
                                  'percent': '${segment.quiz!.passPercent}',
                                }),
                                style: text.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.number,
    required this.done,
    required this.locked,
    required this.highlight,
  });
  final int number;
  final bool done;
  final bool locked;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = done
        ? (AppColors.success, Colors.white)
        : locked
        ? (colors.surfaceContainerHigh, colors.onSurfaceVariant)
        : highlight
        ? (colors.secondary, colors.onSecondary)
        : (colors.primaryContainer, colors.primary);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: done
          ? Icon(Icons.check_rounded, color: foreground, size: 20)
          : locked
          ? Icon(Icons.lock_outline, color: foreground, size: 18)
          : Text(
              '$number',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
