# screenshot_detect

This is an iOS-only plugin for detecting when user takes a screenshot through `UIApplication.userDidTakeScreenshotNotification`. It was heavily inspired by [this package](https://github.com/flutter-moum/flutter_screenshot_callback).

## Getting Started



- Import the package

  ```dart
  import 'package:screenshot_detect/screenshot_detect.dart';
  ```

- Create a `ScreenshotDetect` instance 

  ```dart
   final ScreenshotDetect screenshotDetect = ScreenshotDetect();
  ```

- Add an observer

  ```dart
   screenshotDetect.addListener(() {
     		print('Taken screenshot')
        exampleFunction();
      });
  ```

- Dispose when done

  ```dart
    @override
    void dispose() {
      screenshotDetect.dispose();
      super.dispose();
    }
  ```

  

## Author

- glebosotov - gleb.osotov@gmail.com
