import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/state_view.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/tinted_icon.dart';
import '../../data/models/student.dart';
import '../../data/models/subscription.dart';
import '../../services/settings_service.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const side = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
    return StateView(
      controller: controller,
      onRetry: controller.load,
      builder: (_) => RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          key: const Key('profile-list'),
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            Obx(() {
              final student = controller.student.value;
              if (student == null) return const SizedBox.shrink();
              return Padding(padding: side, child: _Header(student));
            }),
            SectionHeader(title: 'profile.subscriptions'.tr),
            Obx(
              () => Padding(
                padding: side,
                child: Column(
                  children: [
                    if (controller.subscriptions.isEmpty)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.inbox_rounded),
                          title: Text('profile.no_subscriptions'.tr),
                        ),
                      ),
                    for (final item in controller.subscriptions) ...[
                      _SubscriptionCard(item),
                      const SizedBox(height: AppSpacing.sm + 2),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: side,
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  leading: TintedIcon(
                    icon: Icons.vpn_key_rounded,
                    color: AppColors.warning(context),
                    size: 40,
                  ),
                  title: Text('category.redeem'.tr),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await Get.toNamed(AppRoutes.redeem);
                    await controller.load();
                  },
                ),
              ),
            ),
            SectionHeader(title: 'profile.settings'.tr),
            Padding(
              padding: side,
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      leading: TintedIcon(
                        icon: Icons.translate_rounded,
                        color: colors.primary,
                        size: 40,
                      ),
                      title: Text('profile.language'.tr),
                      trailing: Obx(
                        () => SegmentedButton<String>(
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
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
                    const Divider(
                      indent: AppSpacing.lg,
                      endIndent: AppSpacing.lg,
                    ),
                    Obx(
                      () => SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        secondary: TintedIcon(
                          icon: Icons.dark_mode_rounded,
                          color: colors.primary,
                          size: 40,
                        ),
                        title: Text('profile.dark_mode'.tr),
                        value: controller.themeMode.value == ThemeMode.dark,
                        onChanged: controller.setDarkMode,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: side,
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  leading: TintedIcon(
                    icon: Icons.logout_rounded,
                    color: colors.error,
                    size: 40,
                  ),
                  title: Text(
                    'profile.logout'.tr,
                    style: TextStyle(color: colors.error),
                  ),
                  onTap: controller.logout,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.student);
  final Student student;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Colors.white.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg + 4),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          InitialsAvatar(name: student.name, size: 64, onImage: true),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: text.titleLarge?.copyWith(color: Colors.white),
                ),
                Text(
                  student.phone,
                  style: text.bodyMedium?.copyWith(color: muted),
                ),
                if (student.parentPhone != null)
                  Text(
                    '${'auth.parent_phone'.tr}: ${student.parentPhone}',
                    style: text.bodySmall?.copyWith(color: muted),
                  ),
                const SizedBox(height: AppSpacing.sm),
                AppBadge(
                  label: student.level.name,
                  icon: Icons.school_rounded,
                  color: Colors.white,
                  onImage: true,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'profile.edit'.tr,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Get.toNamed(AppRoutes.profileEdit),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard(this.subscription);
  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final category = subscription.category;
    final lifetime = subscription.endsAt == null;
    return Card(
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.category, arguments: category.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.of(category.id),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              AppBadge(
                label: ProfileController.endLabel(subscription),
                icon: lifetime
                    ? Icons.all_inclusive_rounded
                    : Icons.event_rounded,
                color: lifetime
                    ? AppColors.success
                    : Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
