import 'question.dart';

class ReviewItem {
  const ReviewItem({
    required this.question,
    required this.correctOptionId,
    required this.isCorrect,
    this.chosenOptionId,
    this.explanation,
  });

  final Question question;
  final int? chosenOptionId;
  final int correctOptionId;
  final bool isCorrect;
  final String? explanation;

  factory ReviewItem.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return ReviewItem(
      question: Question.fromJson(value['question']),
      chosenOptionId: (value['chosen_option_id'] as num?)?.toInt(),
      correctOptionId: (value['correct_option_id'] as num).toInt(),
      isCorrect: value['is_correct'] as bool,
      explanation: value['explanation'] as String?,
    );
  }
}
