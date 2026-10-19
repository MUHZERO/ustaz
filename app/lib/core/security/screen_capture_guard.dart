import 'package:flutter/services.dart';

class ScreenCaptureGuard {
  ScreenCaptureGuard({EventChannel? channel, this.capturedStream})
    : _channel = channel ?? const EventChannel('ustaz/screen_capture');

  final EventChannel _channel;
  final Stream<bool>? capturedStream;

  Stream<bool> get isCaptured =>
      capturedStream ??
      _channel
          .receiveBroadcastStream()
          .map((event) => event == true)
          .handleError((_) => false)
          .distinct();
}
