import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/state_view.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/question_card.dart';
import 'assessment_review_controller.dart';

class AssessmentReviewView extends GetView<AssessmentReviewController> {
  const AssessmentReviewView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('assessment.review_answers'.tr)),
    body: StateView(
      controller: controller,
      onRetry: controller.load,
      builder: (context) => Obx(
        () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xl),
          itemBuilder: (context, index) {
            final item = controller.items[index];
            final colors = Theme.of(context).colorScheme;
            final text = Theme.of(context).textTheme;
            final (label, icon, color) = item.chosenOptionId == null
                ? (
                    'assessment.unanswered'.tr,
                    Icons.remove_circle_outline,
                    colors.onSurfaceVariant,
                  )
                : item.isCorrect
                ? (
                    'assessment.correct'.tr,
                    Icons.check_circle,
                    AppColors.success,
                  )
                : ('assessment.wrong'.tr, Icons.cancel, colors.error);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'assessment.question_n'.trParams({'n': '${index + 1}'}),
                        style: text.titleSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    AppBadge(label: label, icon: icon, color: color),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                QuestionCard(
                  question: item.question,
                  selectedOptionId: item.chosenOptionId,
                  correctOptionId: item.correctOptionId,
                ),
                if (item.explanation != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: colors.onSecondaryContainer,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            item.explanation!,
                            style: text.bodyMedium?.copyWith(
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
