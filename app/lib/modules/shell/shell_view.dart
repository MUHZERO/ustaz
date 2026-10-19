import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/home_view.dart';
import '../profile/profile_view.dart';
import 'shell_controller.dart';

class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) => Obx(
    () => Scaffold(
      appBar: AppBar(title: Text('app_name'.tr)),
      body: switch (controller.selectedIndex.value) {
        0 => const HomeView(),
        1 => _Placeholder(label: 'shell.results'.tr),
        2 => _Placeholder(label: 'shell.notifications'.tr),
        _ => const ProfileView(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.selectedIndex.value,
        onDestinationSelected: controller.select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: 'shell.home'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assessment_outlined),
            label: 'shell.results'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            label: 'shell.notifications'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: 'shell.profile'.tr,
          ),
        ],
      ),
    ),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}
