import '../../core/network/api_client.dart';
import '../../core/network/device_id_store.dart';
import '../../core/network/token_store.dart';
import '../models/level.dart';
import '../models/student.dart';

class RegisterForm {
  const RegisterForm({
    required this.name,
    required this.phone,
    this.parentPhone,
    required this.password,
    required this.passwordConfirmation,
    required this.levelId,
  });
  final String name;
  final String phone;
  final String? parentPhone;
  final String password;
  final String passwordConfirmation;
  final int levelId;

  Map<String, Object?> toJson(String deviceId) => {
    'name': name,
    'phone': phone,
    if (parentPhone != null && parentPhone!.isNotEmpty)
      'parent_phone': parentPhone,
    'password': password,
    'password_confirmation': passwordConfirmation,
    'level_id': levelId,
    'device_id': deviceId,
  };
}

class AuthRepository {
  AuthRepository(this._api, this._tokens, this._deviceIds);
  final ApiClient _api;
  final TokenStore _tokens;
  final DeviceIdStore _deviceIds;

  Future<List<Level>> levels() => _api.get(
    '/levels',
    (json) => (json as List).map(Level.fromJson).toList(growable: false),
  );

  Future<Student> register(RegisterForm form) async =>
      _authenticate('/auth/register', form.toJson(await _deviceIds.id()));

  Future<Student> login(String phone, String password) async => _authenticate(
    '/auth/login',
    {'phone': phone, 'password': password, 'device_id': await _deviceIds.id()},
  );

  Future<Student> _authenticate(String path, Map<String, Object?> body) async {
    final result = await _api.post(
      path,
      body,
      (json) => json as Map<String, dynamic>,
    );
    await _tokens.save(result['token'] as String);
    return Student.fromJson(result['student']);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', null, (_) {});
    } finally {
      await _tokens.clear();
    }
  }

  Future<Student> me() => _api.get('/me', Student.fromJson);

  Future<Student> updateProfile({
    required String name,
    required String parentPhone,
  }) => _api.put('/me', {
    'name': name,
    'parent_phone': parentPhone.isEmpty ? null : parentPhone,
  }, Student.fromJson);
}
