import '../../core/network/api_client.dart';
import '../models/announcement.dart';
import '../models/category.dart';
import '../models/lecture_card.dart';

class HomeData {
  const HomeData({
    required this.announcements,
    required this.continueWatching,
    required this.categories,
    required this.free,
  });

  final List<Announcement> announcements;
  final List<LectureCard> continueWatching;
  final List<Category> categories;
  final List<LectureCard> free;

  factory HomeData.fromJson(Object? json) {
    final value = json as Map<String, dynamic>;
    List<T> list<T>(String key, T Function(Object?) fromJson) =>
        (value[key] as List? ?? const []).map(fromJson).toList(growable: false);
    return HomeData(
      announcements: list('announcements', Announcement.fromJson),
      continueWatching: list('continue_watching', LectureCard.fromJson),
      categories: list('categories', Category.fromJson),
      free: list('free', LectureCard.fromJson),
    );
  }
}

class ContentRepository {
  ContentRepository(this._api);
  final ApiClient _api;

  Future<HomeData> home() => _api.get('/home', HomeData.fromJson);

  Future<List<Category>> categories() => _api.get(
    '/categories',
    (json) => (json as List).map(Category.fromJson).toList(growable: false),
  );
}
