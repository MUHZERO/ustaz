class Paper {
  const Paper({required this.id, required this.title, required this.url});

  final int id;
  final String title;
  final String url;

  factory Paper.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return Paper(
      id: (value['id'] as num).toInt(),
      title: value['title'] as String,
      url: value['url'] as String,
    );
  }
}
