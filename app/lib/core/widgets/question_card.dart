import 'package:flutter/material.dart';

import '../../data/models/question.dart';
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
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question.text != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              question.text!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        if (question.imageUrl != null)
          SizedBox(
            height: 200,
            child: NetworkImageView(
              url: question.imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ...question.options.map((option) {
          final selected = option.id == selectedOptionId;
          final correct = correctOptionId == null
              ? null
              : option.id == correctOptionId;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: switch (correct) {
              true => Colors.green.withValues(alpha: 0.15),
              false when selected => colors.errorContainer,
              _ => selected ? colors.primaryContainer : null,
            },
            child: ListTile(
              key: Key('option-${option.id}'),
              leading: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
              ),
              title: option.text == null ? null : Text(option.text!),
              subtitle: option.imageUrl == null
                  ? null
                  : SizedBox(
                      height: 120,
                      child: NetworkImageView(
                        url: option.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
              onTap: onSelect == null ? null : () => onSelect!(option.id),
            ),
          );
        }),
      ],
    );
  }
}
