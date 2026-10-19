import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

/// Opens a GetStorage box for tests.
///
/// Call it from `setUpAll`/`setUp`, never inside `testWidgets`: GetStorage does
/// real file IO, which never completes inside the widget tester's fake async zone.
Future<GetStorage> openTestStorage(String name) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => '/tmp',
      );
  await GetStorage.init(name);
  final storage = GetStorage(name);
  await storage.erase();
  return storage;
}
