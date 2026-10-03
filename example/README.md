# Screenshot detection example

Demonstrates screenshot stream events, native error handling, and subscription
cleanup. Take a screenshot with the device buttons to increment the counter;
use **Reset counter** to clear it.

```sh
flutter pub get
flutter run
```

Requires Flutter 3.44+. iOS uses Swift Package Manager only. Android detection
requires Android 14+ and shows the system screenshot-detection notice. Older
Android versions display the plugin's unsupported-platform error.

No screenshot image is read or captured by this example.

The Xcode project includes the plugin's `Package.swift` as a source reference,
while Flutter's generated package supplies the dependency. This avoids creating a
second local-package identity when the checkout directory differs from the Dart
package name.
