import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/base/state_view.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/lecture_card_tile.dart';
import '../../core/widgets/locked_badge.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/exam_card.dart';
import '../../data/models/paper.dart';
import 'category_controller.dart';

class CategoryView extends GetView<CategoryController> {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) => StateView(
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                data.category.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (locked) _LockedBanner(),
            if (data.lectures.isNotEmpty) ...[
              SectionHeader(title: 'category.lectures'.tr),
              SizedBox(
                height: 205,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: data.lectures.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => LectureCardTile(
                    lecture: data.lectures[index],
                    onTap: () => Get.toNamed(
                      AppRoutes.lecture,
                      arguments: data.lectures[index].id,
                    ),
                  ),
                ),
              ),
            ],
            if (data.exams.isNotEmpty) ...[
              SectionHeader(title: 'category.exams'.tr),
              ...data.exams.map(_ExamCardTile.new),
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
  const _ExamCardTile(this.exam);
  final ExamCard exam;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      title: Text(exam.title),
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
