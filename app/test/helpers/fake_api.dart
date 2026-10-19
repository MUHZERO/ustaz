import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ustaz/core/network/api_client.dart';
import 'package:ustaz/core/network/device_id_store.dart';
import 'package:ustaz/core/network/token_store.dart';
import 'package:uuid/uuid.dart';

/// Builds an [ApiClient] answering from [handler] (`(status, json body)`),
/// recording every request into [requests] when given.
ApiClient fakeApi(
  GetStorage storage,
  (int, Object?) Function(http.Request request) handler, {
  List<http.Request>? requests,
}) => ApiClient(
  MockClient((request) async {
    requests?.add(request);
    final (status, body) = handler(request);
    return http.Response(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
  TokenStore(storage),
  DeviceIdStore(storage, const Uuid()),
  'https://api.test',
);

Map<String, Object?> categoryJson({String name = 'Physics'}) => {
  'id': 7,
  'name': name,
  'position': 1,
  'is_free': false,
  'is_subscribed': true,
  'ends_at': null,
  'lectures_count': 1,
  'exams_count': 0,
  'papers_count': 0,
};
