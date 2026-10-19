import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdStore {
  DeviceIdStore(this._storage, this._uuid);
  static const _key = 'device_id';
  final GetStorage _storage;
  final Uuid _uuid;
  Future<String> id() async {
    final existing = _storage.read<String>(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final value = _uuid.v4();
    await _storage.write(_key, value);
    return value;
  }
}
