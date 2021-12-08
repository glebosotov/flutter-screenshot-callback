import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class ScreenshotDetect {
  static const MethodChannel _channel = MethodChannel('screenshot_detect');

  List<VoidCallback> callbacks = <VoidCallback>[];

  ScreenshotDetect() {
    initialize();
  }

  Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethod);
    await _channel.invokeMethod('initialize');
  }

  void addListener(VoidCallback callback) {
    callbacks.add(callback);
  }

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

  Future<void> dispose() async => await _channel.invokeMethod('dispose');
}
