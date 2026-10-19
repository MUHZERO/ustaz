import '../../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._api);
  final ApiClient _api;

  // ponytail: first page (20 latest) only; add paging when the inbox needs history.
  Future<List<AppNotification>> latest() => _api.get(
    '/notifications',
    (json) =>
        (json as List).map(AppNotification.fromJson).toList(growable: false),
  );

  Future<void> markRead(String id) =>
      _api.post('/notifications/$id/read', null, (_) {});

  Future<void> registerToken(String token) =>
      _api.post('/me/fcm-token', {'token': token}, (_) {});
}
