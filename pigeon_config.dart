import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/screenshot_detect.g.dart',
    kotlinOut:
        'android/src/main/kotlin/dev/glebosotov/screenshot_detect/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'dev.glebosotov.screenshot_detect'),
    swiftOut:
        'ios/screenshot_detect/Sources/screenshot_detect/Messages.g.swift',
    dartPackageName: 'screenshot_detect',
  ),
)
enum ScreenshotEvent { taken }

@EventChannelApi()
abstract class ScreenshotDetectApi {
  /// Emits after the operating system reports a screenshot.
  ScreenshotEvent screenshotEvents();
}
