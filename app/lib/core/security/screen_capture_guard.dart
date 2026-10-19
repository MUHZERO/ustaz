import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Reports iOS screen recording/mirroring. Android needs no stream: the whole
/// app is `FLAG_SECURE`, and it registers no channel for this.
class ScreenCaptureGuard {
  ScreenCaptureGuard({EventChannel? channel, this.capturedStream})
    : _channel = channel ?? const EventChannel('ustaz/screen_capture');

  final EventChannel _channel;
  final Stream<bool>? capturedStream;

  Stream<bool> get isCaptured =>
      capturedStream ??
      (Platform.isIOS
          ? _channel
                .receiveBroadcastStream()
                .map((event) => event == true)
                .handleError((_) => false)
                .distinct()
          : const Stream<bool>.empty());
}
