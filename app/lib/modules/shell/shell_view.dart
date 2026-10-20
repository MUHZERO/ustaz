import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/home_view.dart';
import '../results/results_view.dart';
import '../notifications/notifications_view.dart';
import '../profile/profile_view.dart';
import 'shell_controller.dart';

class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  static const _tabs = [
    ('shell.home', Icons.home_outlined, Icons.home_rounded),
    ('shell.results', Icons.insights_outlined, Icons.insights_rounded),
    (
      'shell.notifications',
      Icons.notifications_outlined,
      Icons.notifications_rounded,
    ),
    ('shell.profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) => Obx(() {
    final index = controller.selectedIndex.value;
    return Scaffold(
      // Home draws its own greeting header.
      appBar: index == 0 ? null : AppBar(title: Text(_tabs[index].$1.tr)),
      body: switch (index) {
        0 => const HomeView(),
        1 => const ResultsView(),
        2 => const NotificationsView(),
        _ => const ProfileView(),
      },
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: controller.select,
          destinations: [
            for (final (label, icon, selected) in _tabs)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selected),
                label: label.tr,
              ),
          ],
        ),
      ),
    );
  });
}
