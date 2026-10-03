import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_detect/screenshot_detect.dart';
import 'package:screenshot_detect_example/main.dart';

void main() {
  testWidgets('shows stream and callback events and resets both', (
    tester,
  ) async {
    const channel = MethodChannel('screenshot_detect/events');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => null,
    );
    await tester.pumpWidget(const ScreenshotApp());
    await tester.pump();
    expect(find.text('Stream events: 0'), findsOneWidget);
    ScreenshotDetect().didTakeScreenshot();
    await tester.pump();
    expect(find.text('Stream events: 1'), findsOneWidget);
    expect(find.text('Callback events: 1'), findsOneWidget);
    await tester.tap(find.text('Reset counters'));
    await tester.pump();
    expect(find.text('Stream events: 0'), findsOneWidget);
    expect(find.text('Callback events: 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    unawaited(ScreenshotDetect().dispose());
    await tester.pump();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });
}
