import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/base/state_view.dart';
import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/category_tile.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/lecture_cover.dart';
import '../../core/widgets/lecture_list.dart';
import '../../core/widgets/network_image.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/tinted_icon.dart';
import '../../data/models/announcement.dart';
import '../../data/models/lecture_card.dart';
import '../shell/shell_controller.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion(
    value: SystemUiOverlayStyle.light,
    child: StateView(
      controller: controller,
      onRetry: controller.load,
      builder: (_) {
        final data = controller.data.value;
        if (data == null) return const SizedBox.shrink();
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                key: const Key('home-list'),
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                children: [
                  _Header(controller),
                  if (data.announcements.isNotEmpty) ...[
                    SectionHeader(title: 'home.announcements'.tr),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: data.announcements.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) => SizedBox(
                          width: _rowItemWidth(
                            context,
                            data.announcements.length,
                          ),
                          child: _AnnouncementBanner(
                            data.announcements[index],
                            index: index,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (data.continueWatching.isNotEmpty) ...[
                    SectionHeader(title: 'home.continue_watching'.tr),
                    SizedBox(
                      height: 168,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: data.continueWatching.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) => SizedBox(
                          width: _rowItemWidth(
                            context,
                            data.continueWatching.length,
                          ),
                          child: _ContinueCard(data.continueWatching[index]),
                        ),
                      ),
                    ),
                  ],
                  if (data.categories.isNotEmpty) ...[
                    SectionHeader(title: 'home.categories'.tr),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      itemCount: data.categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 184,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                          ),
                      itemBuilder: (_, index) {
                        final category = data.categories[index];
                        return CategoryTile(
                          category: category,
                          onTap: () => Get.toNamed(
                            AppRoutes.category,
                            arguments: category.id,
                          ),
                        );
                      },
                    ),
                  ],
                  if (data.free.isNotEmpty) ...[
                    SectionHeader(title: 'home.free_lectures'.tr),
                    LectureList(lectures: data.free),
                  ],
                ],
              ),
            ),
            // Keeps the status bar readable once the header scrolls away.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.paddingOf(context).top,
              child: const ColoredBox(color: AppConfig.primaryColor),
            ),
          ],
        );
      },
    ),
  );
}

/// Full width for a single card, otherwise most of it so the next one peeks.
double _rowItemWidth(BuildContext context, int count) {
  final width = MediaQuery.sizeOf(context).width;
  return count == 1 ? width - AppSpacing.lg * 2 : width * 0.82;
}

/// Greeting on the brand gradient, with the student's level and a bell.
class _Header extends StatelessWidget {
  const _Header(this.controller);
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.xl),
        ),
      ),
      child: Obx(() {
        final student = controller.student.value;
        return Row(
          children: [
            InitialsAvatar(name: student?.name ?? '', onImage: true),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student == null
                        ? 'splash'.tr
                        : 'home.greeting'.trParams({
                            'name': student.name.split(' ').first,
                          }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(color: Colors.white),
                  ),
                  Text(
                    student?.level.name ?? 'home.subtitle'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'shell.notifications'.tr,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () => Get.find<ShellController>().select(2),
            ),
          ],
        );
      }),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner(this.announcement, {required this.index});
  final Announcement announcement;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = index.isEven ? colors.primary : colors.secondary;
    final hasImage = announcement.imageUrl?.isNotEmpty ?? false;
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (hasImage)
            SizedBox(
              width: 96,
              height: double.infinity,
              child: NetworkImageView(url: announcement.imageUrl),
            )
          else
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
              child: TintedIcon(icon: Icons.campaign_rounded, color: accent),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  if (announcement.body?.isNotEmpty ?? false)
                    Text(
                      announcement.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The lecture to resume: its cover full bleed, progress and a resume button.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard(this.lecture);
  final LectureCard lecture;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    void open() => Get.toNamed(AppRoutes.lecture, arguments: lecture.id);
    return Card(
      child: InkWell(
        onTap: open,
        child: Stack(
          fit: StackFit.expand,
          children: [
            LectureCover(
              seed: lecture.id,
              imageUrl: lecture.thumbnailUrl,
              showPlay: false,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xAA000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'lecture.number'.trParams({'n': '${lecture.position}'}),
                    style: text.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    lecture.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProgressBar(
                              percent: lecture.progressPercent,
                              color: Colors.white,
                              trackColor: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'percent_done'.trParams({
                                'percent': '${lecture.progressPercent.round()}',
                              }),
                              style: text.labelMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: open,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          backgroundColor: Colors.white,
                          foregroundColor: AppGradients.base(lecture.id),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text('home.resume'.tr),
                      ),
                    ],
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
