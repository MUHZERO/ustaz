import 'package:flutter/material.dart';
import '../../data/models/attempt.dart';
import '../theme/app_tokens.dart';
import 'tinted_icon.dart';

/// One assessment row: title, a status line and the percent once graded.
class ResultTile extends StatelessWidget {
  const ResultTile({
    required this.title,
    required this.subtitle,
    this.icon = Icons.assignment_outlined,
    this.percent,
    this.onTap,
    super.key,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final num? percent;
  final VoidCallback? onTap;

  static IconData iconFor(AssessmentKind kind) => switch (kind) {
    AssessmentKind.quiz => Icons.quiz_outlined,
    AssessmentKind.homework => Icons.edit_note_rounded,
    AssessmentKind.exam => Icons.timer_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final grade = percent == null ? null : AppColors.forPercent(percent!);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs + 2,
      ),
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                TintedIcon(icon: icon, color: colors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                      Text(
                        subtitle,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (grade != null)
                  Container(
                    constraints: const BoxConstraints(minWidth: 58),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: grade.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      '$percent%',
                      textAlign: TextAlign.center,
                      style: text.titleSmall?.copyWith(
                        color: grade,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                    textDirection: Directionality.of(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
