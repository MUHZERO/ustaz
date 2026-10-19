import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/base/state_view.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/lecture_list.dart';
import '../../core/widgets/locked_badge.dart';
import '../../core/widgets/section_header.dart';
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
        final locked = !data.category.isFree && !data.category.isSubscribed;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            key: const Key('category-list'),
            children: [
              const SizedBox(height: 8),
              if (locked) _LockedBanner(),
              if (data.lectures.isNotEmpty) ...[
                SectionHeader(title: 'category.lectures'.tr),
                LectureList(lectures: data.lectures),
              ],
              if (data.exams.isNotEmpty) ...[
                SectionHeader(title: 'category.exams'.tr),
                ...data.exams.map(
                  (exam) =>
                      _ExamCardTile(exam, () => controller.openExam(exam)),
                ),
              ],
              if (data.papers.isNotEmpty) ...[
                SectionHeader(title: 'category.papers'.tr),
                ...data.papers.map(_PaperTile.new),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ),
  );
}

class _LockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LockedBadge(),
        const SizedBox(height: 8),
        Text('category.locked_message'.tr),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Get.toNamed(AppRoutes.redeem),
          child: Text('category.redeem'.tr),
        ),
      ],
    ),
  );
}

class _ExamCardTile extends StatelessWidget {
  const _ExamCardTile(this.exam, this.onTap);
  final ExamCard exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      title: Text(exam.title),
      onTap: onTap,
      trailing: exam.isLocked
          ? const LockedBadge()
          : Text('category.exam_state_${exam.state.name}'.tr),
    ),
  );
}

class _PaperTile extends StatelessWidget {
  const _PaperTile(this.paper);
  final Paper paper;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(paper.title),
    leading: const Icon(Icons.picture_as_pdf_outlined),
    onTap: () => Get.toNamed(
      AppRoutes.pdf,
      arguments: {'url': paper.url, 'title': paper.title},
    ),
  );
}
