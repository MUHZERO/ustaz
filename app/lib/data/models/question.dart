class QuestionOption {
  const QuestionOption({required this.id, this.text, this.imageUrl});

  final int id;
  final String? text;
  final String? imageUrl;

  factory QuestionOption.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return QuestionOption(
      id: (value['id'] as num).toInt(),
      text: value['text'] as String?,
      imageUrl: value['image_url'] as String?,
    );
  }
}

class Question {
  const Question({
    required this.id,
    required this.options,
    this.text,
    this.imageUrl,
  });

  final int id;
  final String? text;
  final String? imageUrl;
  final List<QuestionOption> options;

  factory Question.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return Question(
      id: (value['id'] as num).toInt(),
      text: value['text'] as String?,
      imageUrl: value['image_url'] as String?,
      options: (value['options'] as List)
          .map(QuestionOption.fromJson)
          .toList(growable: false),
    );
  }
}
