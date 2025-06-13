import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/screenshot_detect.g.dart',
    dartOptions: DartOptions(),
    objcHeaderOut: 'ios/Classes/messages.g.h',
    objcSourceOut: 'ios/Classes/messages.g.m',
    dartPackageName: 'screenshot_detect',
  ),
)
@FlutterApi()
abstract class ScreenshotDetectApi {
  /// Called when the user takes a screenshot
  void didTakeScreenshot();
}
