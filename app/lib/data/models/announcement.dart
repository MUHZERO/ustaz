class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    this.body,
    this.imageUrl,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String? body;
  final String? imageUrl;
  final DateTime createdAt;

  factory Announcement.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return Announcement(
      id: (value['id'] as num).toInt(),
      title: value['title'] as String,
      body: value['body'] as String?,
      imageUrl: value['image_url'] as String?,
      createdAt: DateTime.parse(value['created_at'] as String),
    );
  }
}
