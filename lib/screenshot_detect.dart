import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class ScreenshotDetect {
  static const MethodChannel _channel = MethodChannel('screenshot_detect');

  List<VoidCallback> callbacks = <VoidCallback>[];

  /// Calls the initializer function which adds `UIApplication.userDidTakeScreenshotNotification` observer (use `addListener(VoidCallback callback)` to run actions when user screenshots)
  ScreenshotDetect() {
    initialize();
  }

  /// Starts listening to screenshots (use `addListener(VoidCallback callback)` to run actions when user screenshots)
  Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethod);
    await _channel.invokeMethod('initialize');
  }

  /// Adds a [callback] function to be called when user screenshots
  void addListener(VoidCallback callback) {
    callbacks.add(callback);
  }

  /// Calls every method in [callbacks] when user screenshots
  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onCallback':
        for (final callback in callbacks) {
          callback();
        }
        break;
      default:
        throw ('Undefined method ${call.method}');
    }
  }

  /// Stops listening for screenshots
  Future<void> dispose() async => await _channel.invokeMethod('dispose');
}
