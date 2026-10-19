import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/state_view.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/category_tile.dart';
import '../../core/widgets/lecture_list.dart';
import '../../core/widgets/network_image.dart';
import '../../core/widgets/section_header.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => StateView(
    controller: controller,
    onRetry: controller.load,
    builder: (_) {
      final data = controller.data.value;
      if (data == null) return const SizedBox.shrink();
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          key: const Key('home-list'),
          children: [
            if (data.announcements.isNotEmpty) ...[
              SectionHeader(title: 'home.announcements'.tr),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: data.announcements.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final announcement = data.announcements[index];
                    return SizedBox(
                      width: 260,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              height: double.infinity,
                              child: NetworkImageView(
                                url: announcement.imageUrl,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(announcement.title),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (data.continueWatching.isNotEmpty) ...[
              SectionHeader(title: 'home.continue_watching'.tr),
              LectureList(lectures: data.continueWatching),
            ],
            if (data.categories.isNotEmpty) ...[
              SectionHeader(title: 'home.categories'.tr),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, index) {
                  final category = data.categories[index];
                  return CategoryTile(
                    category: category,
                    onTap: () =>
                        Get.toNamed(AppRoutes.category, arguments: category.id),
                  );
                },
              ),
            ],
            if (data.free.isNotEmpty) ...[
              SectionHeader(title: 'home.free_lectures'.tr),
              LectureList(lectures: data.free),
            ],
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
