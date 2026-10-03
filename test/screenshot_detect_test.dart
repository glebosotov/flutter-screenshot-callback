import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_detect/screenshot_detect.dart';
import 'package:screenshot_detect/screenshot_detect.g.dart' as pigeon;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(
    'dev.flutter.pigeon.screenshot_detect.ScreenshotDetectApi.screenshotEvents',
    pigeon.pigeonMethodCodec,
  );
  const codec = pigeon.pigeonMethodCodec;
  late ScreenshotDetect detector;
  late List<String> calls;

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  Future<void> emit({Object? error}) async {
    final delivered = Completer<void>();
    binding.channelBuffers.push(
      channel.name,
      error == null
          ? codec.encodeSuccessEnvelope(pigeon.ScreenshotEvent.taken)
          : codec.encodeErrorEnvelope(
              code: 'unsupported_platform',
              message: '$error',
            ),
      (_) => delivered.complete(),
    );
    await delivered.future;
    await flush();
  }

  setUp(() {
    calls = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      return null;
    });
    detector = ScreenshotDetect();
  });

  tearDown(() async {
    await detector.dispose();
    await flush();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('construction is lazy and shares an instance', () async {
    expect(ScreenshotDetect(), same(detector));
    expect(detector.onScreenshot.isBroadcast, isTrue);
    await flush();
    expect(calls, isEmpty);
  });

  test('multiple streams and callbacks share native observation', () async {
    var first = 0;
    var second = 0;
    var callbacks = 0;
    final a = detector.onScreenshot.listen((_) => first++);
    final b = detector.onScreenshot.listen((_) => second++);
    void callback() => callbacks++;
    detector.addListener(callback);
    await flush();
    expect(calls, ['listen']);
    await emit();
    expect([first, second, callbacks], [1, 1, 1]);
    await a.cancel();
    detector.removeListener(callback);
    await flush();
    expect(calls, ['listen']);
    await b.cancel();
    await flush();
    expect(calls, ['listen', 'cancel']);
  });

  test('callback-only observation starts and stops', () async {
    var count = 0;
    void callback() => count++;
    detector.addListener(callback);
    await flush();
    await emit();
    expect(count, 1);
    detector.removeListener(callback);
    await flush();
    expect(calls, ['listen', 'cancel']);
  });

  test('duplicate callbacks are removed one at a time', () async {
    var count = 0;
    void callback() => count++;
    detector.addListener(callback);
    detector.addListener(callback);
    await flush();
    await emit();
    expect(count, 2);
    detector.removeListener(callback);
    await emit();
    expect(count, 3);
    detector.removeListener(callback);
    detector.removeListener(callback);
    await flush();
    expect(calls, ['listen', 'cancel']);
  });

  test('callback mutation uses a snapshot for the current event', () async {
    final received = <String>[];
    void second() => received.add('second');
    void third() => received.add('third');
    void first() {
      received.add('first');
      detector.removeListener(second);
      detector.addListener(third);
    }

    detector.addListener(first);
    detector.addListener(second);
    await flush();
    await emit();
    expect(received, ['first', 'second']);
    received.clear();
    await emit();
    expect(received, ['first', 'third']);
  });

  test('one callback failure does not suppress other consumers', () async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);
    var count = 0;
    detector.addListener(() => throw StateError('broken listener'));
    detector.addListener(() => count++);
    final subscription = detector.onScreenshot.listen((_) => count++);
    await flush();
    await emit();
    expect(count, 2);
    expect(errors.single.exception, isStateError);
    await subscription.cancel();
  });

  test('native errors are delivered to stream subscribers', () async {
    final errors = <Object>[];
    final subscription = detector.onScreenshot.listen(
      (_) {},
      onError: errors.add,
    );
    await flush();
    await emit(error: 'Android 14 required');
    expect(
      errors.single,
      isA<PlatformException>().having(
        (e) => e.code,
        'code',
        'unsupported_platform',
      ),
    );
    await subscription.cancel();
  });

  test('callback-only native errors are reported through Flutter', () async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);
    detector.addListener(() {});
    await flush();
    await emit(error: 'Android 14 required');
    expect(errors.single.exception, isA<PlatformException>());
  });

  test('pause buffers only that subscription', () async {
    var paused = 0;
    var active = 0;
    final a = detector.onScreenshot.listen((_) => paused++);
    final b = detector.onScreenshot.listen((_) => active++);
    await flush();
    a.pause();
    await emit();
    expect([paused, active], [0, 1]);
    a.resume();
    await flush();
    expect([paused, active], [1, 1]);
    await a.cancel();
    await b.cancel();
  });

  test('resubscription restarts observation without replay', () async {
    final first = detector.onScreenshot.listen((_) {});
    await flush();
    await emit();
    await first.cancel();
    await flush();
    var count = 0;
    final second = detector.onScreenshot.listen((_) => count++);
    await flush();
    expect(count, 0);
    expect(calls, ['listen', 'cancel', 'listen']);
    await emit();
    expect(count, 1);
    await second.cancel();
  });

  test('dispose closes streams, clears callbacks and is idempotent', () async {
    var count = 0;
    var done = false;
    detector.addListener(() => count++);
    detector.onScreenshot.listen((_) => count++, onDone: () => done = true);
    await flush();
    await detector.dispose();
    await detector.dispose();
    await flush();
    detector.didTakeScreenshot();
    expect(count, 0);
    expect(done, isTrue);
    expect(calls, ['listen', 'cancel']);
    expect(() => detector.addListener(() {}), throwsStateError);
  });

  test('paused subscription does not block native disposal', () async {
    final subscription = detector.onScreenshot.listen((_) {});
    await flush();
    subscription.pause();
    await detector.dispose();
    expect(calls, ['listen', 'cancel']);
    await subscription.cancel();
  });

  test('immediate recreation waits for old native cancellation', () async {
    detector.addListener(() {});
    await flush();
    final old = detector;
    final disposed = old.dispose();
    detector = ScreenshotDetect();
    expect(detector, isNot(same(old)));
    var count = 0;
    detector.addListener(() => count++);
    await disposed;
    await flush();
    expect(calls, ['listen', 'cancel', 'listen']);
    await old.dispose();
    await emit();
    expect(count, 1);
  });

  test('disposing from callback stops remaining callback dispatch', () async {
    var count = 0;
    detector.addListener(() => unawaited(detector.dispose()));
    detector.addListener(() => count++);
    await flush();
    await emit();
    expect(count, 0);
    expect(calls, ['listen', 'cancel']);
  });
}
