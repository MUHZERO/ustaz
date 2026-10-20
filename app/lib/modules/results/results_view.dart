import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/paged_list.dart';
import '../../core/widgets/result_tile.dart';
import '../../data/models/result.dart';
import '../homework/homework_view.dart';
import 'results_controller.dart';

/// The Results tab: graded attempts, and homework to do.
class ResultsView extends GetView<ResultsController> {
  const ResultsView({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        Container(
          height: 48,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: TabBar(
            tabs: [
              Tab(text: 'shell.results'.tr),
              Tab(text: 'homework.title'.tr),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              PagedList<ResultEntry>(
                controller: controller,
                itemBuilder: (_, entry) => ResultTile(
                  title: entry.title,
                  subtitle: 'assessment.kind_${entry.kind.name}'.tr,
                  icon: ResultTile.iconFor(entry.kind),
                  percent: entry.result.percent,
                  onTap: () => controller.open(entry),
                ),
              ),
              const HomeworkView(),
            ],
          ),
        ),
      ],
    ),
  );
}
