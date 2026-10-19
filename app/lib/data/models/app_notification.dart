class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  AppNotification markedRead(DateTime at) => AppNotification(
    id: id,
    title: title,
    body: body,
    data: data,
    readAt: at,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return AppNotification(
      id: '${value['id']}',
      title: value['title'] as String? ?? '',
      body: value['body'] as String? ?? '',
      data: value['data'] is Map
          ? Map<String, dynamic>.from(value['data'] as Map)
          : const {},
      readAt: value['read_at'] == null
          ? null
          : DateTime.parse(value['read_at'] as String),
      createdAt: DateTime.parse(value['created_at'] as String),
    );
  }
}
