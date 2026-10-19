import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ustaz/core/base/base_controller.dart';
import 'package:ustaz/core/network/api_exception.dart';

void main() {
  test('run sets loading then success', () async {
    final controller = _TestController();
    final seen = <ViewStatus>[];
    ever<ViewStatus>(controller.status, seen.add);

    await controller.run(() async {});

    expect(seen, [ViewStatus.loading, ViewStatus.success]);
    expect(controller.error, isNull);
  });

  test('run captures ApiException message', () async {
    final controller = _TestController();

    await controller.run(
      () async => throw const ApiException(
        statusCode: 422,
        code: 'validation_failed',
        message: 'Invalid input',
      ),
    );

    expect(controller.status.value, ViewStatus.error);
    expect(controller.error, 'Invalid input');
  });
}

class _TestController extends BaseController {}
