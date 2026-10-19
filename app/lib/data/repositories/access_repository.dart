import '../../core/network/api_client.dart';
import '../models/category.dart';
import '../models/subscription.dart';

class AccessRepository {
  AccessRepository(this._api);
  final ApiClient _api;

  Future<Category> redeem(String code) => _api.post(
    '/codes/redeem',
    {'code': code},
    (json) => Category.fromJson((json as Map<String, dynamic>)['category']),
  );

  Future<List<Subscription>> subscriptions() => _api.get(
    '/subscriptions',
    (json) => (json as List).map(Subscription.fromJson).toList(growable: false),
  );
}
