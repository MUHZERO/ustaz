import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/category.dart';
import '../formatters.dart';
import '../i18n/plural.dart';
import '../routes/app_routes.dart';
import '../theme/app_tokens.dart';
import 'app_badge.dart';

/// "6 lectures · 1 exam": lectures always, exams and papers when present.
String categoryCounts(Category category) => [
  'count.lectures'.plural(category.lecturesCount),
  if (category.examsCount > 0) 'count.exams'.plural(category.examsCount),
  if (category.papersCount > 0) 'count.papers'.plural(category.papersCount),
].join(' · ');

bool isCategoryLocked(Category category) =>
    !category.isFree && !category.isSubscribed;

class CategoryTile extends StatelessWidget {
  const CategoryTile({required this.category, this.onTap, super.key});
  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final locked = isCategoryLocked(category);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(gradient: AppGradients.of(category.id)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    if (locked)
                      Icon(
                        Icons.lock_outline,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                Text(
                  categoryCounts(category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                locked
                    ? _ActivateButton(category)
                    : CategoryStatusBadge(category: category, onImage: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Free, or subscribed with its end date (lifetime when it has none).
class CategoryStatusBadge extends StatelessWidget {
  const CategoryStatusBadge({
    required this.category,
    this.onImage = false,
    super.key,
  });
  final Category category;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    if (category.isFree) {
      return AppBadge(
        label: 'category.free'.tr,
        icon: Icons.card_giftcard_rounded,
        color: AppColors.success,
        onImage: onImage,
      );
    }
    if (!category.isSubscribed) return const SizedBox.shrink();
    final endsAt = category.endsAt;
    return AppBadge(
      label: endsAt == null
          ? 'category.subscribed_lifetime'.tr
          : 'category.subscribed_until'.trParams({
              'date': Formatters.date(endsAt),
            }),
      icon: Icons.verified_rounded,
      color: Theme.of(context).colorScheme.primary,
      onImage: onImage,
    );
  }
}

class _ActivateButton extends StatelessWidget {
  const _ActivateButton(this.category);
  final Category category;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppRadii.sm),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      onTap: () => Get.toNamed(AppRoutes.redeem),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.vpn_key_rounded,
              size: 14,
              color: AppGradients.base(category.id),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'category.activate'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppGradients.base(category.id),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
