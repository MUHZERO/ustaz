class Level {
  const Level({required this.id, required this.name});
  final int id;
  final String name;

  factory Level.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    return Level(
      id: (value['id'] as num).toInt(),
      name: value['name'] as String,
    );
  }
}
