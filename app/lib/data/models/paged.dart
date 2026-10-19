/// One page of a paginated API list.
class Paged<T> {
  const Paged({
    required this.items,
    required this.page,
    required this.lastPage,
  });

  /// A plain list served as its only page.
  const Paged.single(this.items) : page = 1, lastPage = 1;

  final List<T> items;
  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;

  /// Parses the whole envelope: `{data: [...], meta: {current_page, last_page}}`.
  factory Paged.fromJson(Object? json, T Function(Object? json) parseItem) {
    final value = json as Map<String, dynamic>;
    final meta = value['meta'] as Map<String, dynamic>;
    return Paged(
      items: (value['data'] as List).map(parseItem).toList(growable: false),
      page: (meta['current_page'] as num).toInt(),
      lastPage: (meta['last_page'] as num).toInt(),
    );
  }
}
