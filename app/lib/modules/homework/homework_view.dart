import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/paged_list.dart';
import '../../core/widgets/result_tile.dart';
import '../../data/models/attempt.dart';
import '../../data/models/homework.dart';
import 'homework_controller.dart';

class HomeworkView extends GetView<HomeworkController> {
  const HomeworkView({super.key});

  @override
  Widget build(BuildContext context) => PagedList<Homework>(
    controller: controller,
    itemBuilder: (_, homework) => ResultTile(
      title: homework.title,
      subtitle: 'homework.${homework.status.name}'.tr,
      icon: ResultTile.iconFor(AssessmentKind.homework),
      percent: homework.percent,
      onTap: () => controller.open(homework),
    ),
  );
}
