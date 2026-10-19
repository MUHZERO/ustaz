import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';
import '../../services/push_service.dart';

class NotificationsController extends BaseController {
  NotificationsController(this._repository);
  final NotificationRepository _repository;
  final items = <AppNotification>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    await run(() async => items.assignAll(await _repository.latest()));
    if (status.value == ViewStatus.success && items.isEmpty) {
      status.value = ViewStatus.empty;
    }
  }

  Future<void> open(AppNotification item) async {
    if (!item.isRead) {
      final index = items.indexWhere((value) => value.id == item.id);
      if (index >= 0) items[index] = item.markedRead(DateTime.now());
      try {
        await _repository.markRead(item.id);
      } catch (_) {
        // Best effort: the server marks it read on the next successful open.
      }
    }
    if (item.data['route'] != 'notifications') {
      await PushService.openRoute(item.data);
    }
  }
}
