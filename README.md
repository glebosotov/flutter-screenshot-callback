# screenshot_detect

This is an iOS-only plugin for detecting when user takes a screenshot through `UIApplication.userDidTakeScreenshotNotification`. It was heavily inspired by [this package](https://github.com/flutter-moum/flutter_screenshot_callback).

## Getting Started



- Import the package

  ```dart
  import 'package:screenshot_callback/screenshot_callback.dart';
  ```

- Create an `ScreenshotCallback` instance 

  ```dart
   final ScreenshotCallback screenshotCallback = ScreenshotCallback();
  ```

- Add an observer

  ```dart
   screenshotCallback.addListener(() {
     		print('Taken screenshot')
        exampleFunction();
      });
  ```

- Dispose when done

  ```dart
    @override
    void dispose() {
      screenshotCallback.dispose();
      super.dispose();
    }
  ```

  

## Author

- glebosotov - gleb.osotov@gmail.com
