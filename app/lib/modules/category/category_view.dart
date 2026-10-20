import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/base/state_view.dart';
import '../../core/formatters.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/category_tile.dart';
import '../../core/widgets/lecture_card_tile.dart';
import '../../core/widgets/locked_badge.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/tinted_icon.dart';
import '../../data/models/category.dart';
import '../../data/models/exam_card.dart';
import '../../data/models/paper.dart';
import 'category_controller.dart';

class CategoryView extends GetView<CategoryController> {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Obx(() => Text(controller.data.value?.category.name ?? '')),
    ),
    body: StateView(
      controller: controller,
      onRetry: controller.load,
      builder: (_) {
        final data = controller.data.value;
        if (data == null) return const SizedBox.shrink();
        const gap = SizedBox(height: AppSpacing.sm + 2);
        const side = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            key: const Key('category-list'),
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              _Header(data.category),
              if (isCategoryLocked(data.category)) const _LockedBanner(),
              if (data.lectures.isNotEmpty) ...[
                SectionHeader(title: 'category.lectures'.tr),
                for (final lecture in data.lectures) ...[
                  Padding(
                    padding: side,
                    child: LectureRow(
                      lecture: lecture,
                      onTap: () =>
                          Get.toNamed(AppRoutes.lecture, arguments: lecture.id),
                    ),
                  ),
                  gap,
                ],
              ],
              if (data.exams.isNotEmpty) ...[
                SectionHeader(title: 'category.exams'.tr),
                for (final exam in data.exams) ...[
                  Padding(
                    padding: side,
                    child: _ExamCardTile(exam, () => controller.openExam(exam)),
                  ),
                  gap,
                ],
              ],
              if (data.papers.isNotEmpty) ...[
                SectionHeader(title: 'category.papers'.tr),
                for (final paper in data.papers) ...[
                  Padding(padding: side, child: _PaperTile(paper)),
                  gap,
                ],
              ],
            ],
          ),
        );
      },
    ),
  );
}

/// The category's gradient card: name, counts and access status.
class _Header extends StatelessWidget {
  const _Header(this.category);
  final Category category;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      decoration: BoxDecoration(
        gradient: AppGradients.of(category.id),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: text.titleLarge?.copyWith(color: Colors.white),
                ),
                Text(
                  categoryCounts(category),
                  style: text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                isCategoryLocked(category)
                    ? const LockedBadge(onImage: true)
                    : CategoryStatusBadge(category: category, onImage: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          TintedIcon(icon: Icons.vpn_key_rounded, color: colors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'category.locked_message'.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 42),
              backgroundColor: colors.secondary,
              foregroundColor: colors.onSecondary,
            ),
            onPressed: () => Get.toNamed(AppRoutes.redeem),
            child: Text('category.redeem'.tr),
          ),
        ],
      ),
    );
  }
}

class _ExamCardTile extends StatelessWidget {
  const _ExamCardTile(this.exam, this.onTap);
  final ExamCard exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final percent = exam.attempt?.percent;
    final stateColor = switch (exam.state) {
      ExamState.open => AppColors.success,
      ExamState.upcoming => colors.primary,
      ExamState.closed => colors.onSurfaceVariant,
    };
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              TintedIcon(icon: Icons.timer_outlined, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.title, style: text.titleSmall),
                    Text(
                      [
                        'minutes'.trParams({'n': '${exam.durationMinutes}'}),
                        'category.closes_at'.trParams({
                          'date': Formatters.date(exam.closesAt),
                        }),
                      ].join(' · '),
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (exam.isLocked)
                const LockedBadge()
              else if (percent != null)
                AppBadge(
                  label: '$percent%',
                  color: AppColors.forPercent(context, percent),
                )
              else
                AppBadge(
                  label: 'category.exam_state_${exam.state.name}'.tr,
                  color: stateColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperTile extends StatelessWidget {
  const _PaperTile(this.paper);
  final Paper paper;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: () => Get.toNamed(
        AppRoutes.pdf,
        arguments: {'url': paper.url, 'title': paper.title},
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const TintedIcon(
              icon: Icons.picture_as_pdf_rounded,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                paper.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ),
  );
}
