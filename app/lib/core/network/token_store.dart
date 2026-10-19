import 'package:get_storage/get_storage.dart';

class TokenStore {
  TokenStore(this._storage);
  static const _key = 'auth_token';
  final GetStorage _storage;
  String? get token => _storage.read<String>(_key);
  Future<void> save(String value) => _storage.write(_key, value);
  Future<void> clear() => _storage.remove(_key);
}
