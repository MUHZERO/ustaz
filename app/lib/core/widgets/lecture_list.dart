import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/lecture_card.dart';
import '../routes/app_routes.dart';
import 'lecture_card_tile.dart';

/// A horizontal row of lecture cards; a tap opens the lecture.
class LectureList extends StatelessWidget {
  const LectureList({required this.lectures, super.key});
  final List<LectureCard> lectures;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 205,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: lectures.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, index) => LectureCardTile(
        lecture: lectures[index],
        onTap: () =>
            Get.toNamed(AppRoutes.lecture, arguments: lectures[index].id),
      ),
    ),
  );
}
