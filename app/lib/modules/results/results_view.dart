import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        TabBar(
          tabs: [
            Tab(text: 'shell.results'.tr),
            Tab(text: 'homework.title'.tr),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              PagedList<ResultEntry>(
                controller: controller,
                itemBuilder: (_, entry) => ResultTile(
                  title: entry.title,
                  subtitle: 'assessment.kind_${entry.kind.name}'.tr,
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
