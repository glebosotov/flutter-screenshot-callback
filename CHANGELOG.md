## 2.0.0

* Add broadcast `Stream<void> onScreenshot` alongside existing callbacks.
* Add Android 14+ screenshot detection with activity lifecycle management and
  explicit errors on older Android versions.
* Keep Pigeon and generate demand-driven event channels for Dart, Swift, and Kotlin.
* Fix iOS observer ownership, engine detach cleanup, and Dart listener disposal.
* Isolate callback failures so other listeners still receive events.
* **Breaking:** remove CocoaPods; iOS now uses Swift Package Manager only.
* **Breaking:** require Flutter 3.44+ and iOS 15+. Disposed service instances are
  terminal; calling `ScreenshotDetect()` again creates a fresh shared service.
* Refresh the example, documentation, tests, Android host, and CI build checks.

## 1.0.4

* Up dependencies
* Move to `pigeon`

## 1.0.3

* Add documentation and clean up the code

## 1.0.2

* Fix naming issues

## 1.0.1

* Add README.md

## 1.0.0

* Initial release, with iOS-only support
