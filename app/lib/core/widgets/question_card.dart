import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/question.dart';
import '../theme/app_tokens.dart';
import 'network_image.dart';

/// Renders a question with its options; used by the player (selectable) and
/// the review screen (shows the correct option).
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.question,
    this.selectedOptionId,
    this.correctOptionId,
    this.onSelect,
    super.key,
  });

  final Question question;
  final int? selectedOptionId;
  final int? correctOptionId;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final letters = 'assessment.option_letters'.tr.characters.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question.text != null || question.imageUrl != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (question.text != null)
                    Text(
                      question.text!,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(height: 1.6),
                    ),
                  if (question.imageUrl != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: SizedBox(
                        height: 200,
                        child: NetworkImageView(
                          url: question.imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        for (final (index, option) in question.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
            child: _OptionCard(
              key: Key('option-${option.id}'),
              option: option,
              letter: index < letters.length ? letters[index] : '${index + 1}',
              selected: option.id == selectedOptionId,
              correct: correctOptionId == null
                  ? null
                  : option.id == correctOptionId,
              onTap: onSelect == null ? null : () => onSelect!(option.id),
            ),
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.letter,
    required this.selected,
    required this.correct,
    required this.onTap,
    super.key,
  });
  final QuestionOption option;
  final String letter;
  final bool selected;

  /// Null while answering; in review, whether this is the right option.
  final bool? correct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reviewing = correct != null;
    final accent = switch (correct) {
      true => AppColors.success,
      false when selected => colors.error,
      _ => selected ? colors.primary : null,
    };
    final trailing = reviewing
        ? switch (correct) {
            true => const Icon(Icons.check_circle, color: AppColors.success),
            _ when selected => Icon(Icons.cancel, color: colors.error),
            _ => null,
          }
        : Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? colors.primary : colors.outline,
          );
    final radius = BorderRadius.circular(AppRadii.md + 2);
    return Material(
      color: accent?.withValues(alpha: 0.08) ?? colors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: accent ?? colors.outlineVariant,
              width: accent == null ? 1 : 1.6,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent ?? colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  letter,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: accent == null
                        ? colors.onSurfaceVariant
                        : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (option.text != null)
                      Text(
                        option.text!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    if (option.imageUrl != null)
                      SizedBox(
                        height: 120,
                        child: NetworkImageView(
                          url: option.imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
