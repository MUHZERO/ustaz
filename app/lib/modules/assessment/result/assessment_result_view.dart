import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/state_view.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/tinted_icon.dart';
import '../../../data/models/result.dart';
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
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ScoreCard(result),
            const SizedBox(height: AppSpacing.xl),
            if (result.reviewAvailable)
              AppButton(
                label: 'assessment.review_answers'.tr,
                icon: Icons.fact_check_outlined,
                onPressed: () => Get.toNamed(
                  AppRoutes.assessmentReview,
                  arguments: result.attemptId,
                ),
              ),
            if (request != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ReviewStatus(request),
            ] else if (controller.canRequestReview)
              _ReviewRequestForm(controller),
          ],
        );
      }),
    ),
  );
}

/// The percent in a ring colored by the grade, the score and pass or fail.
class _ScoreCard extends StatelessWidget {
  const _ScoreCard(this.result);
  final AssessmentResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final passed = result.passed;
    final color = switch (passed) {
      true => AppColors.success,
      false => colors.error,
      null => AppColors.forPercent(context, result.percent),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl,
          horizontal: AppSpacing.lg,
        ),
        child: Column(
          children: [
            Text(
              'assessment.your_score'.tr,
              style: text.titleSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox.square(
              dimension: 176,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: (result.percent / 100).clamp(0, 1).toDouble(),
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.12),
                  ),
                  Center(
                    child: Text(
                      '${result.percent}%',
                      style: text.displaySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'assessment.score'.trParams({
                'score': '${result.score}',
                'max': '${result.maxScore}',
              }),
              style: text.titleMedium,
            ),
            if (passed != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppBadge(
                label: passed ? 'assessment.passed'.tr : 'assessment.failed'.tr,
                icon: passed
                    ? Icons.emoji_events_rounded
                    : Icons.replay_rounded,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewStatus extends StatelessWidget {
  const _ReviewStatus(this.request);
  final ReviewRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, color) = switch (request.status) {
      ReviewRequestStatus.pending => (
        Icons.hourglass_top_rounded,
        AppColors.warning(context),
      ),
      ReviewRequestStatus.accepted => (
        Icons.check_circle_rounded,
        AppColors.success,
      ),
      ReviewRequestStatus.rejected => (Icons.cancel_rounded, colors.error),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintedIcon(icon: icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'assessment.review_status_${request.status.name}'.tr,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (request.reply != null)
                    Text(
                      request.reply!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('review-note'),
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'assessment.review_note'.tr,
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.send_rounded),
              onPressed: () => widget.controller.requestReview(_note.text),
              label: Text('assessment.request_review'.tr),
            ),
          ],
        ),
      ),
    ),
  );
}
