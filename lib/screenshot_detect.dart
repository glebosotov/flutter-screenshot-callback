import 'dart:async';

import 'package:flutter/foundation.dart';

import 'screenshot_detect.g.dart' as pigeon;

/// Detects screenshots using the operating system's screenshot notifications.
///
/// Instances share one service. Use [onScreenshot] for stream subscriptions.
/// Native observation runs only while needed.
class ScreenshotDetect {
  static ScreenshotDetect? _instance;
  static final _screenshots = pigeon.screenshotEvents().map<void>((_) {});

  /// Returns the shared service, creating a new one after [dispose].
  factory ScreenshotDetect() => _instance ??= ScreenshotDetect._();

  ScreenshotDetect._();

  final _callbacks =
      <({VoidCallback callback, StreamSubscription<void> subscription})>[];
  bool _disposed = false;

  /// A broadcast stream emitting one void event after each screenshot.
  ///
  /// Multiple subscriptions and callbacks can coexist. Events are not replayed.
  /// Cancel your subscription when its owner is disposed. Native errors are
  /// forwarded to stream listeners; callbacks report them through FlutterError.
  /// Calling [dispose] does not cancel these subscriptions.
  Stream<void> get onScreenshot => _screenshots;

  /// Registers [callback]. Registering it twice produces two invocations.
  ///
  /// Throws a [StateError] if this service has been disposed.
  @Deprecated('Use onScreenshot.listen instead.')
  void addListener(VoidCallback callback) {
    if (_disposed) {
      throw StateError('This ScreenshotDetect has been disposed.');
    }
    final subscription = onScreenshot.listen((_) {
      try {
        callback();
      } catch (error, stack) {
        _reportError(error, stack);
      }
    }, onError: _reportError);
    _callbacks.add((callback: callback, subscription: subscription));
  }

  /// Removes one registration of [callback]. Missing callbacks are ignored.
  @Deprecated(
    'Cancel the subscription returned by onScreenshot.listen instead.',
  )
  void removeListener(VoidCallback callback) {
    final index = _callbacks.indexWhere((entry) => entry.callback == callback);
    if (index != -1) {
      unawaited(_callbacks.removeAt(index).subscription.cancel());
    }
  }

  /// Removes all callbacks from the shared service. Safe to call twice.
  ///
  /// Stream consumers must cancel their own subscriptions. In a widget, prefer
  /// removing its callback. Calling the factory again returns a fresh service.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (identical(_instance, this)) _instance = null;
    final cancellations = _callbacks
        .map((entry) => entry.subscription.cancel())
        .toList();
    _callbacks.clear();
    await Future.wait(cancellations);
  }

  static void _reportError(Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'screenshot_detect',
        context: ErrorDescription('while delivering a screenshot notification'),
      ),
    );
  }
}
