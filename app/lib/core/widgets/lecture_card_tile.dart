import 'package:flutter/material.dart';
import '../../data/models/lecture_card.dart';
import 'locked_badge.dart';
import 'network_image.dart';
import 'progress_bar.dart';

class LectureCardTile extends StatelessWidget {
  const LectureCardTile({required this.lecture, super.key});
  final LectureCard lecture;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 110,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageView(url: lecture.thumbnailUrl),
                if (lecture.isLocked)
                  const Align(
                    alignment: Alignment.center,
                    child: LockedBadge(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              lecture.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ProgressBar(percent: lecture.progressPercent),
          ),
        ],
      ),
    ),
  );
}
