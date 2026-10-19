import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/state_view.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import 'assessment_result_controller.dart';

class AssessmentResultView extends GetView<AssessmentResultController> {
  const AssessmentResultView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('assessment.result'.tr)),
    body: StateView(
      controller: controller,
      onRetry: controller.load,
      builder: (_) => Obx(() {
        final result = controller.result.value;
        if (result == null) return const SizedBox.shrink();
        final request = result.reviewRequest;
        final textTheme = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${result.percent}%',
              style: textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            Text(
              'assessment.score'.trParams({
                'score': '${result.score}',
                'max': '${result.maxScore}',
              }),
              textAlign: TextAlign.center,
            ),
            if (result.passed != null)
              Text(
                result.passed!
                    ? 'assessment.passed'.tr
                    : 'assessment.failed'.tr,
                style: textTheme.titleMedium?.copyWith(
                  color: result.passed!
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            if (result.reviewAvailable)
              AppButton(
                label: 'assessment.review_answers'.tr,
                onPressed: () => Get.toNamed(
                  AppRoutes.assessmentReview,
                  arguments: result.attemptId,
                ),
              ),
            if (request != null) ...[
              const SizedBox(height: 16),
              Text('assessment.review_status_${request.status.name}'.tr),
              if (request.reply != null) Text(request.reply!),
            ] else if (controller.canRequestReview)
              _ReviewRequestForm(controller),
          ],
        );
      }),
    ),
  );
}

class _ReviewRequestForm extends StatefulWidget {
  const _ReviewRequestForm(this.controller);
  final AssessmentResultController controller;

  @override
  State<_ReviewRequestForm> createState() => _ReviewRequestFormState();
}

class _ReviewRequestFormState extends State<_ReviewRequestForm> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 16),
      TextField(
        key: const Key('review-note'),
        controller: _note,
        maxLength: 500,
        maxLines: 3,
        decoration: InputDecoration(labelText: 'assessment.review_note'.tr),
      ),
      AppButton(
        label: 'assessment.request_review'.tr,
        onPressed: () => widget.controller.requestReview(_note.text),
      ),
    ],
  );
}
