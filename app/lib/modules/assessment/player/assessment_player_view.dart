import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/state_view.dart';
import '../../../core/widgets/question_card.dart';
import 'assessment_player_controller.dart';

class AssessmentPlayerView extends GetView<AssessmentPlayerController> {
  const AssessmentPlayerView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Obx(() {
        final left = controller.remaining.value;
        if (left == null) return Text('assessment.title'.tr);
        final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
        return Text(
          '${left.inMinutes.toString().padLeft(2, '0')}:$seconds',
          key: const Key('assessment-timer'),
        );
      }),
    ),
    body: StateView(
      controller: controller,
      onRetry: controller.load,
      builder: (_) => Obx(() {
        final attempt = controller.attempt.value;
        final question = controller.question;
        if (attempt == null || question == null) {
          return const SizedBox.shrink();
        }
        final index = controller.index.value;
        final count = attempt.questions.length;
        final isLast = index == count - 1;
        return Column(
          children: [
            ListTile(
              title: Text(
                'assessment.question_of'.trParams({
                  'index': '${index + 1}',
                  'count': '$count',
                }),
              ),
              trailing: IconButton(
                tooltip: 'assessment.flag'.tr,
                icon: Icon(
                  controller.flagged.contains(question.id)
                      ? Icons.flag
                      : Icons.outlined_flag,
                ),
                onPressed: () => controller.toggleFlag(question.id),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: QuestionCard(
                  question: question,
                  selectedOptionId: controller.answers[question.id],
                  onSelect: (option) => controller.select(question.id, option),
                ),
              ),
            ),
            _Navigator(controller),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: index == 0
                        ? null
                        : () => controller.goTo(index - 1),
                    child: Text('assessment.previous'.tr),
                  ),
                  const Spacer(),
                  if (isLast)
                    FilledButton(
                      onPressed: controller.submitting.value
                          ? null
                          : _confirmSubmit,
                      child: Text('assessment.submit'.tr),
                    )
                  else
                    FilledButton(
                      onPressed: () => controller.goTo(index + 1),
                      child: Text('assessment.next'.tr),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    ),
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

class _Navigator extends StatelessWidget {
  const _Navigator(this.controller);
  final AssessmentPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final questions = controller.attempt.value!.questions;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final id = questions[index].id;
          final background = index == controller.index.value
              ? colors.primary
              : controller.flagged.contains(id)
              ? colors.tertiaryContainer
              : controller.answers.containsKey(id)
              ? colors.secondaryContainer
              : colors.surfaceContainerHighest;
          return InkWell(
            customBorder: const CircleBorder(),
            onTap: () => controller.goTo(index),
            child: CircleAvatar(
              backgroundColor: background,
              foregroundColor: index == controller.index.value
                  ? colors.onPrimary
                  : colors.onSurface,
              child: Text('${index + 1}'),
            ),
          );
        },
      ),
    );
  }
}
