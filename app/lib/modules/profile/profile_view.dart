import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/state_view.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/section_header.dart';
import '../../services/settings_service.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) => StateView(
    controller: controller,
    onRetry: controller.load,
    builder: (_) => RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        key: const Key('profile-list'),
        children: [
          Obx(() {
            final student = controller.student.value;
            if (student == null) return const SizedBox.shrink();
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(student.name),
              subtitle: Text(
                [
                  student.phone,
                  student.level.name,
                  if (student.parentPhone != null)
                    '${'auth.parent_phone'.tr}: ${student.parentPhone}',
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'profile.edit'.tr,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Get.toNamed(AppRoutes.profileEdit),
              ),
            );
          }),
          SectionHeader(title: 'profile.subscriptions'.tr),
          Obx(
            () => controller.subscriptions.isEmpty
                ? ListTile(title: Text('profile.no_subscriptions'.tr))
                : Column(
                    children: [
                      for (final item in controller.subscriptions)
                        ListTile(
                          title: Text(item.category.name),
                          subtitle: Text(ProfileController.endLabel(item)),
                        ),
                    ],
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.redeem_outlined),
            title: Text('category.redeem'.tr),
            onTap: () async {
              await Get.toNamed(AppRoutes.redeem);
              await controller.load();
            },
          ),
          SectionHeader(title: 'profile.settings'.tr),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('profile.language'.tr),
            trailing: Obx(
              () => SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final code in SettingsService.languages)
                    ButtonSegment(
                      value: code,
                      label: Text('language.$code'.tr),
                    ),
                ],
                selected: {controller.language.value},
                onSelectionChanged: (value) =>
                    controller.setLanguage(value.first),
              ),
            ),
          ),
          Obx(
            () => SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: Text('profile.dark_mode'.tr),
              value: controller.themeMode.value == ThemeMode.dark,
              onChanged: controller.setDarkMode,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text('profile.logout'.tr),
            onTap: controller.logout,
          ),
        ],
      ),
    ),
  );
}
