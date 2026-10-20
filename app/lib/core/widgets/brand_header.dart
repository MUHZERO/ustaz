import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_tokens.dart';

/// The logo mark: the app name's first letter in a rounded gradient square.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 72, super.key});
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = 'app_name'.tr;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, Colors.black, .35)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        name.isEmpty ? '' : name.characters.first,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.48,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Logo, app name, a title and one line under it: the top of auth screens.
class BrandHeader extends StatelessWidget {
  const BrandHeader({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        const BrandMark(),
        const SizedBox(height: AppSpacing.md),
        Text(
          'app_name'.tr,
          style: text.titleMedium?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
