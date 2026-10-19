import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../core/config/firebase_config.dart';
import '../core/routes/app_routes.dart';
import '../data/repositories/notification_repository.dart';

/// FCM wiring. A no-op until [FirebaseConfig] provides options, and it never
/// throws: a push failure must not break the app.
class PushService extends GetxService {
  PushService(this._repository, [this._options = FirebaseConfig.options]);
  final NotificationRepository _repository;
  final FirebaseOptions? Function() _options;
  bool _listening = false;

  bool get enabled => _listening;

  /// Called once a student is signed in, so the token reaches their account.
  Future<void> init() async {
    final options = _options();
    if (options == null) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      // The backend's FCM v1 driver sends to registration tokens; the newer
      // register()/onRegistered pair yields installation ids instead.
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await _repository.registerToken(token);
      if (_listening) return;
      _listening = true;
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen(
        (token) => _repository.registerToken(token).catchError((_) {}),
      );
      FirebaseMessaging.onMessage.listen(_showBanner);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => openRoute(message.data),
      );
      final initial = await messaging.getInitialMessage();
      if (initial != null) openRoute(initial.data);
    } catch (_) {
      // Push stays off; everything else keeps working.
    }
  }

  void _showBanner(RemoteMessage message) => Get.snackbar(
    message.notification?.title ?? '',
    message.notification?.body ?? '',
    onTap: (_) => openRoute(message.data),
  );

  /// Opens the screen named by a notification's `data.route`; unknown routes
  /// do nothing. FCM data values arrive as strings, inbox data as JSON.
  static Future<void>? openRoute(Map<String, dynamic> data) {
    int? id(String key) => int.tryParse('${data[key] ?? data['id']}');
    return switch (data['route']) {
      'lecture' when id('lecture_id') != null => Get.toNamed(
        AppRoutes.lecture,
        arguments: id('lecture_id'),
      ),
      'category' when id('category_id') != null => Get.toNamed(
        AppRoutes.category,
        arguments: id('category_id'),
      ),
      'notifications' => Get.toNamed(AppRoutes.notifications),
      _ => null,
    };
  }
}
