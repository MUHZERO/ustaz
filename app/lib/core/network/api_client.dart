import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'device_id_store.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient(this._http, this._tokens, this._deviceIds, this._baseUrl);
  final http.Client _http;
  final TokenStore _tokens;
  final DeviceIdStore _deviceIds;
  final String _baseUrl;
  static const _timeout = Duration(seconds: 20);
  final _unauthorized = StreamController<String?>.broadcast();
  final Set<String?> _reportedUnauthorizedTokens = {};
  Stream<String?> get onUnauthorized => _unauthorized.stream;
  Future<T> get<T>(
    String path,
    T Function(Object? json) parse, {
    Map<String, String>? query,
  }) => _request('GET', path, parse, query: query);
  Future<T> post<T>(
    String path,
    Object? body,
    T Function(Object? json) parse, {
    Map<String, String>? query,
  }) => _request('POST', path, parse, body: body, query: query);
  Future<T> put<T>(
    String path,
    Object? body,
    T Function(Object? json) parse, {
    Map<String, String>? query,
  }) => _request('PUT', path, parse, body: body, query: query);
  Future<T> delete<T>(
    String path,
    T Function(Object? json) parse, {
    Object? body,
    Map<String, String>? query,
  }) => _request('DELETE', path, parse, body: body, query: query);
  Future<T> _request<T>(
    String method,
    String path,
    T Function(Object? json) parse, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final token = _tokens.token;
    final request = http.Request(method, _uri(path, query))
      ..headers.addAll({
        'Accept': 'application/json',
        'Accept-Language': Get.locale?.languageCode == 'en' ? 'en' : 'ar',
        'X-Device-Id': await _deviceIds.id(),
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(_timeout),
      );
    } on Exception {
      throw ApiException(
        statusCode: 0,
        code: 'network',
        message: 'errors.network'.tr,
      );
    }
    final json = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parse(json is Map<String, dynamic> ? json['data'] : null);
    }
    final exception = _exception(response.statusCode, json);
    if (response.statusCode == 401 && _reportedUnauthorizedTokens.add(token)) {
      _unauthorized.add(token);
    }
    throw exception;
  }

  Uri _uri(String path, Map<String, String>? query) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return Uri.parse(
      '$base${path.startsWith('/') ? path : '/$path'}',
    ).replace(queryParameters: query);
  }

  Object? _decode(String body) {
    try {
      return body.isEmpty ? null : jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  ApiException _exception(int statusCode, Object? json) {
    final values = json is Map ? json : const <Object?, Object?>{};
    final errors = <String, List<String>>{};
    if (values['errors'] case final Map rawErrors) {
      for (final entry in rawErrors.entries) {
        if (entry.value is List) {
          errors['${entry.key}'] = (entry.value as List)
              .map((value) => '$value')
              .toList();
        }
      }
    }
    return ApiException(
      statusCode: statusCode,
      code: values['code'] as String? ?? 'http_$statusCode',
      message: values['message'] as String? ?? 'errors.generic'.tr,
      fieldErrors: errors,
    );
  }

  void dispose() => _unauthorized.close();
}
