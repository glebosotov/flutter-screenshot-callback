import 'dart:async';

import 'package:flutter/services.dart';

import '../screenshot_detect.g.dart';

/// A service to detect when the user takes a screenshot.
///
/// Use [addListener] to register callbacks that are invoked when a screenshot is detected.
class ScreenshotDetect implements ScreenshotDetectApi {
  static final ScreenshotDetect _instance = ScreenshotDetect._internal();
  final List<VoidCallback> _callbacks = <VoidCallback>[];
  factory ScreenshotDetect() => _instance;

  ScreenshotDetect._internal() {
    _initialize();
  }

  /// Adds a [callback] function to be called when the user takes a screenshot.
  void addListener(VoidCallback callback) {
    _callbacks.add(callback);
  }

  @override
  void didTakeScreenshot() {
    for (final callback in List<VoidCallback>.from(_callbacks)) {
      callback();
    }
  }

  /// Stops listening for screenshots and disposes resources.
  Future<void> dispose() async {
    _callbacks.clear();
  }

  /// Removes a previously added [callback].
  void removeListener(VoidCallback callback) {
    _callbacks.remove(callback);
  }

  /// Initializes the screenshot detection by setting up the method call handler
  /// and invoking the native 'initialize' method.
  void _initialize() => ScreenshotDetectApi.setUp(this);
}
