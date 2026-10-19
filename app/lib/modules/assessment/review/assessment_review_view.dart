import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/state_view.dart';
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
      builder: (_) => Obx(
        () => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: controller.items.length,
          separatorBuilder: (_, _) => const Divider(height: 32),
          itemBuilder: (_, index) {
            final item = controller.items[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuestionCard(
                  question: item.question,
                  selectedOptionId: item.chosenOptionId,
                  correctOptionId: item.correctOptionId,
                ),
                if (item.chosenOptionId == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('assessment.unanswered'.tr),
                  ),
                if (item.explanation != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(item.explanation!),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
