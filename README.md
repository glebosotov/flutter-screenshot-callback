# screenshot_detect

Native screenshot detection for Flutter, with a broadcast stream and callbacks.
Supports iOS and Android 14+ without reading the photo library or screenshot files.

## Requirements

- Flutter 3.44+ and Dart 3.8.1+.
- iOS 15+, Xcode with Swift 5.9+, and **Swift Package Manager enabled**.
  CocoaPods is no longer supported.
- Android: compile SDK 36 and Java 17. Apps can run on API 24+, but screenshot
  detection requires Android 14 (API 34) or later.

## Install

```sh
flutter pub add screenshot_detect
```

For iOS, Flutter integrates the Swift package during the app build. If your app
previously disabled Swift Package Manager, enable it with
`flutter config --enable-swift-package-manager` and remove any app-level override
that disables it. See [Flutter's migration guide](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers).

On Android, the plugin manifest adds `android.permission.DETECT_SCREEN_CAPTURE`.
This is an install-time permission; no runtime permission dialog or storage access
is needed. Android displays a system notice when your app detects a screenshot.

## Streams

```dart
import 'dart:async';
import 'package:screenshot_detect/screenshot_detect.dart';

final detector = ScreenshotDetect();
final StreamSubscription<void> subscription = detector.onScreenshot.listen(
  (_) {
    // React to a screenshot. The event does not contain an image or file path.
  },
  onError: (Object error) {
    // For example, PlatformException with code `unsupported_platform`
    // on Android versions below 14.
  },
);

// When this consumer is finished:
await subscription.cancel();
```

`onScreenshot` is a broadcast `Stream<void>`. Multiple subscriptions and callbacks
share one native observer. Events are delivered asynchronously to stream listeners
and are not replayed to new listeners. Pausing a subscription buffers its events;
use cancellation to stop consuming events and release observation when no other
listeners remain.

## Callbacks

The existing callback API remains available:

```dart
final detector = ScreenshotDetect();
void onScreenshot() {
  // React to a screenshot.
}

detector.addListener(onScreenshot);

// In your widget/controller's dispose method:
detector.removeListener(onScreenshot);
```

Keep the callback reference so it can be removed. Duplicate registrations are
allowed; each `removeListener` removes one registration. Callback exceptions are
reported through `FlutterError` without suppressing other listeners. Native errors
also go to `FlutterError` when only callbacks are registered; stream subscribers
can handle them through `onError`.

## Lifecycle

`ScreenshotDetect()` returns a shared service. Observation starts with the first
stream listener or callback and stops after the last one is removed. Cancelling
one subscription does not affect other consumers.

Use `await detector.dispose()` only when intentionally releasing the **whole
shared service**. It removes callbacks, stops native observation, and closes the
stream. Disposal is idempotent and does not wait for paused subscriptions to resume.
A subsequent `ScreenshotDetect()` returns a fresh service; old instances stay
disposed and reject new callbacks. For widget cleanup, cancel the widget's stream
subscription and/or remove its callback instead.

On Android, observation stops when the activity stops and resumes when it starts.
Activity recreation and engine detach release the old registration. On iOS,
observers are scoped to each Flutter engine and removed on cancellation or detach.

## Platform behavior and limits

| Platform | Behavior |
| --- | --- |
| iOS 15+ | Uses `UIApplication.userDidTakeScreenshotNotification`. |
| Android 14+ | Uses `Activity.ScreenCaptureCallback` while the activity is visible. |
| Android 7–13 | Emits `PlatformException(code: 'unsupported_platform')` when observation starts. |
| Other platforms | No native implementation. |

Notifications arrive **after** a screenshot. This plugin does not prevent capture,
provide the captured image, or detect screen recording. Apple documents the
notification timing in [UIKit's screenshot notification](https://developer.apple.com/documentation/uikit/uiapplication/userdidtakescreenshotnotification).

Android's documented detection covers hardware-button screenshots. ADB and
instrumentation screenshots do not trigger it; test with device screenshot
buttons. See [Android screenshot detection](https://developer.android.com/about/versions/14/features/screenshot-detection).

## Migrating from 1.x

- Move iOS builds to Swift Package Manager; the podspec and CocoaPods bridge were
  removed. Update Flutter and the iOS deployment target to the requirements above.
- Existing `addListener` / `removeListener` calls continue to work. Streams are
  optional and can coexist with callbacks.
- `dispose()` now releases native resources and closes streams. Obtain a fresh
  instance before registering new listeners after disposal.
- Pigeon now generates event channels for Dart, Swift, and Kotlin. Continue
  importing `screenshot_detect.dart`; generated bridge types are internal.

## Example and development

The [example](example) displays stream and callback event counts side by side,
including error handling and per-widget cleanup.

```sh
flutter pub get
flutter analyze
flutter test
cd example
flutter run
```

The native bridge is defined in `pigeon_config.dart`. After changing it, regenerate
all three checked-in outputs with the pinned Pigeon version:

```sh
dart run pigeon --input pigeon_config.dart
dart format lib/screenshot_detect.g.dart
```

Native build checks:

```sh
cd example
flutter build ios --simulator --debug --no-codesign
flutter build apk --debug
cd android
./gradlew :screenshot_detect:testDebugUnitTest
```

Verify real screenshot delivery, background/foreground transitions, rotation, and
multiple listeners on physical iOS and Android 14+ devices before release.

## Author

Gleb Osotov — gleb.osotov@gmail.com
