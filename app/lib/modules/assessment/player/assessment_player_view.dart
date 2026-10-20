import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/state_view.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/question_card.dart';
import 'assessment_player_controller.dart';

class AssessmentPlayerView extends GetView<AssessmentPlayerController> {
  const AssessmentPlayerView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Obx(
        () => Text(switch (controller.attempt.value?.kind) {
          final kind? => 'assessment.kind_${kind.name}'.tr,
          null => 'assessment.title'.tr,
        }),
      ),
      actions: [
        Obx(() {
          final left = controller.remaining.value;
          if (left == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
            child: _TimerChip(left),
          );
        }),
      ],
    ),
    body: StateView(
      controller: controller,
      onRetry: controller.load,
      builder: (context) => Obx(() {
        final attempt = controller.attempt.value;
        final question = controller.question;
        if (attempt == null || question == null) {
          return const SizedBox.shrink();
        }
        final colors = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        final index = controller.index.value;
        final count = attempt.questions.length;
        final isLast = index == count - 1;
        final flagged = controller.flagged.contains(question.id);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: LinearProgressIndicator(value: (index + 1) / count),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'assessment.question_of'.trParams({
                            'index': '${index + 1}',
                            'count': '$count',
                          }),
                          style: text.titleMedium,
                        ),
                        Text(
                          'assessment.answered'.trParams({
                            'n': '${controller.answers.length}',
                            'count': '$count',
                          }),
                          style: text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'assessment.flag'.tr,
                    isSelected: flagged,
                    style: IconButton.styleFrom(
                      foregroundColor: flagged
                          ? AppColors.warning(context)
                          : colors.onSurfaceVariant,
                      backgroundColor: flagged
                          ? colors.secondaryContainer
                          : null,
                    ),
                    icon: Icon(flagged ? Icons.flag : Icons.outlined_flag),
                    onPressed: () => controller.toggleFlag(question.id),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: QuestionCard(
                  question: question,
                  selectedOptionId: controller.answers[question.id],
                  onSelect: (option) => controller.select(question.id, option),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: index == 0
                            ? null
                            : () => controller.goTo(index - 1),
                        child: Text('assessment.previous'.tr),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        key: const Key('question-navigator'),
                        tooltip: 'assessment.questions'.tr,
                        constraints: const BoxConstraints.tightFor(
                          width: 52,
                          height: 52,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primaryContainer,
                          foregroundColor: colors.onPrimaryContainer,
                        ),
                        icon: const Icon(Icons.grid_view_rounded),
                        onPressed: () => _showNavigator(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: isLast
                            ? FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                ),
                                onPressed: controller.submitting.value
                                    ? null
                                    : _confirmSubmit,
                                child: Text('assessment.submit'.tr),
                              )
                            : FilledButton(
                                onPressed: () => controller.goTo(index + 1),
                                child: Text('assessment.next'.tr),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    ),
  );

  void _showNavigator(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => _Navigator(controller, onPick: Navigator.of(sheet).pop),
  );

  void _confirmSubmit() => Get.defaultDialog(
    title: 'assessment.submit'.tr,
    middleText: 'assessment.submit_confirm'.tr,
    textConfirm: 'assessment.submit'.tr,
    textCancel: 'cancel'.tr,
    onConfirm: () {
      Get.back<void>();
      controller.submit();
    },
  );
}

/// Amber under five minutes, red under one.
class _TimerChip extends StatelessWidget {
  const _TimerChip(this.left);
  final Duration left;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = left < const Duration(minutes: 1)
        ? colors.error
        : left < const Duration(minutes: 5)
        ? AppColors.warning(context)
        : colors.primary;
    final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${left.inMinutes.toString().padLeft(2, '0')}:$seconds',
            key: const Key('assessment-timer'),
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Navigator extends StatelessWidget {
  const _Navigator(this.controller, {required this.onPick});
  final AssessmentPlayerController controller;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final questions = controller.attempt.value!.questions;
    (Color, Color) style(int index) {
      final id = questions[index].id;
      if (index == controller.index.value) {
        return (colors.primary, colors.onPrimary);
      }
      if (controller.flagged.contains(id)) {
        return (colors.secondaryContainer, colors.onSecondaryContainer);
      }
      if (controller.answers.containsKey(id)) {
        return (colors.primaryContainer, colors.onPrimaryContainer);
      }
      return (colors.surfaceContainerHigh, colors.onSurfaceVariant);
    }

    Widget legend(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: text.bodySmall),
      ],
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Obx(() {
          // Read the observables here, not in the lazy grid builder.
          final styles = [for (var i = 0; i < questions.length; i++) style(i)];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('assessment.questions'.tr, style: text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  legend(colors.primary, 'assessment.legend_current'.tr),
                  legend(
                    colors.primaryContainer,
                    'assessment.legend_answered'.tr,
                  ),
                  legend(
                    colors.secondaryContainer,
                    'assessment.legend_flagged'.tr,
                  ),
                  legend(
                    colors.surfaceContainerHigh,
                    'assessment.legend_unanswered'.tr,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: questions.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 60,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                  ),
                  itemBuilder: (_, index) {
                    final (background, foreground) = styles[index];
                    return Material(
                      color: background,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        onTap: () {
                          controller.goTo(index);
                          onPick();
                        },
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: text.titleSmall?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
