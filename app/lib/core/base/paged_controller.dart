import 'package:get/get.dart';
import '../../data/models/paged.dart';
import 'base_controller.dart';

/// Loads a list page by page; [PagedList] renders it.
abstract class PagedController<T> extends BaseController {
  final items = <T>[].obs;
  final loadMoreFailed = false.obs;
  int _page = 0;
  int _lastPage = 1;
  bool _loadingMore = false;

  bool get hasMore => _page < _lastPage;

  Future<Paged<T>> fetch(int page);

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    await run(() async {
      final first = await fetch(1);
      _keep(first);
      items.assignAll(first.items);
    });
    if (status.value == ViewStatus.success && items.isEmpty) {
      status.value = ViewStatus.empty;
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore) return;
    _loadingMore = true;
    loadMoreFailed.value = false;
    try {
      final next = await fetch(_page + 1);
      _keep(next);
      items.addAll(next.items);
    } catch (_) {
      loadMoreFailed.value = true;
    } finally {
      _loadingMore = false;
    }
  }

  /// Before touching [items], so the list rebuild sees the new [hasMore].
  void _keep(Paged<T> page) {
    _page = page.page;
    _lastPage = page.lastPage;
  }
}
