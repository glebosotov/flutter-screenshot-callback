import 'dart:async';

import 'package:flutter/foundation.dart';

import 'screenshot_detect.g.dart' as pigeon;

/// Detects screenshots using the operating system's screenshot notifications.
///
/// Instances share one service. Use [onScreenshot] for stream subscriptions or
/// [addListener] for callbacks. Native observation runs only while needed.
class ScreenshotDetect {
  static ScreenshotDetect? _instance;
  static final _nativeEvents = pigeon.screenshotEvents();

  /// Returns the shared service, creating a new one after [dispose].
  factory ScreenshotDetect() => _instance ??= ScreenshotDetect._();

  ScreenshotDetect._() {
    _events = StreamController<void>.broadcast(
      onListen: _updateSubscription,
      onCancel: _updateSubscription,
    );
  }

  final List<VoidCallback> _callbacks = <VoidCallback>[];
  late final StreamController<void> _events;
  StreamSubscription<pigeon.ScreenshotEvent>? _subscription;
  bool _disposed = false;

  /// A broadcast stream emitting one void event after each screenshot.
  ///
  /// Multiple subscriptions and callbacks can coexist. Events are not replayed.
  /// Cancel your subscription when its owner is disposed. Native errors are
  /// forwarded to stream listeners; callback-only users receive Flutter errors.
  Stream<void> get onScreenshot => _events.stream;

  /// Registers [callback]. Registering it twice produces two invocations.
  ///
  /// Throws a [StateError] if this service has been disposed.
  void addListener(VoidCallback callback) {
    if (_disposed) {
      throw StateError('This ScreenshotDetect has been disposed.');
    }
    _callbacks.add(callback);
    _updateSubscription();
  }

  /// Removes one registration of [callback]. Missing callbacks are ignored.
  void removeListener(VoidCallback callback) {
    _callbacks.remove(callback);
    _updateSubscription();
  }

  /// Dispatches a screenshot notification to current listeners.
  ///
  /// Kept for compatibility. Applications normally receive native events.
  void didTakeScreenshot() {
    if (_disposed) return;
    _events.add(null);
    for (final callback in List<VoidCallback>.of(_callbacks)) {
      if (_disposed) break;
      try {
        callback();
      } catch (error, stack) {
        _reportError(error, stack);
      }
    }
  }

  /// Releases the shared service and closes its stream. Safe to call twice.
  ///
  /// This affects all users of the shared instance. In a widget, prefer
  /// cancelling its subscription or removing its callback. Calling the factory
  /// again returns a fresh service. Paused listeners do not delay cleanup.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _callbacks.clear();
    if (identical(_instance, this)) _instance = null;
    await _updateSubscription();
    unawaited(_events.close());
  }

  Future<void> _updateSubscription() async {
    if (_disposed || (!_events.hasListener && _callbacks.isEmpty)) {
      final subscription = _subscription;
      _subscription = null;
      await subscription?.cancel();
      return;
    }

    _subscription ??= _nativeEvents.listen(
      (_) => didTakeScreenshot(),
      onError: _onError,
    );
  }

  void _onError(Object error, StackTrace stack) {
    if (_disposed) return;
    if (_events.hasListener) {
      _events.addError(error, stack);
    } else {
      _reportError(error, stack);
    }
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
