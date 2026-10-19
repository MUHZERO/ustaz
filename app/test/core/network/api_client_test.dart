import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ustaz/core/network/api_client.dart';
import 'package:ustaz/core/network/api_exception.dart';
import 'package:ustaz/core/network/device_id_store.dart';
import 'package:ustaz/core/network/token_store.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetStorage storage;
  late TokenStore tokenStore;
  late DeviceIdStore deviceIdStore;

  setUp(() async {
    storage = await openTestStorage('api-client-test');
    tokenStore = TokenStore(storage);
    deviceIdStore = DeviceIdStore(storage, const Uuid());
  });

  test('adds auth device and language headers', () async {
    await tokenStore.save('token-1');
    late http.Request request;
    final client = ApiClient(
      MockClient((received) async {
        request = received;
        return http.Response(jsonEncode({'data': true}), 200);
      }),
      tokenStore,
      deviceIdStore,
      'https://api.test/v1',
    );

    await client.get('/levels', (json) => json as bool);

    expect(request.headers['authorization'], 'Bearer token-1');
    expect(request.headers['x-device-id'], isNotEmpty);
    expect(request.headers['accept-language'], 'ar');
  });

  test('unwraps data envelope', () async {
    final client = ApiClient(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {'id': 7},
          }),
          200,
        ),
      ),
      tokenStore,
      deviceIdStore,
      'https://api.test/v1',
    );

    final id = await client.get('/levels', (json) => (json! as Map)['id']);

    expect(id, 7);
  });

  test('maps 403 device_pending to ApiException code', () async {
    final client = ApiClient(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Pending', 'code': 'device_pending'}),
          403,
        ),
      ),
      tokenStore,
      deviceIdStore,
      'https://api.test/v1',
    );

    await expectLater(
      client.get('/me', (json) => json),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having((error) => error.code, 'code', 'device_pending'),
      ),
    );
  });

  test('401 logs out once', () async {
    await tokenStore.save('token-1');
    final client = ApiClient(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Unauthenticated', 'code': 'unauthenticated'}),
          401,
        ),
      ),
      tokenStore,
      deviceIdStore,
      'https://api.test/v1',
    );
    final events = <String?>[];
    final subscription = client.onUnauthorized.listen(events.add);

    await Future.wait<void>([
      expectLater(
        client.get('/me', (json) => json),
        throwsA(isA<ApiException>()),
      ),
      expectLater(
        client.get('/me', (json) => json),
        throwsA(isA<ApiException>()),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(events, ['token-1']);
    await subscription.cancel();
    client.dispose();
  });

  test('device id is stable across calls', () async {
    final first = await deviceIdStore.id();
    final second = await deviceIdStore.id();

    expect(first, second);
    expect(Uuid.isValidUUID(fromString: first), isTrue);
  });

  test('maps network failure to network ApiException', () async {
    final client = ApiClient(
      MockClient((_) async => throw http.ClientException('offline')),
      tokenStore,
      deviceIdStore,
      'https://api.test/api/v1',
    );

    await expectLater(
      client.get('/home', (json) => json),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'network')
            .having((e) => e.statusCode, 'statusCode', 0),
      ),
    );
  });
}
