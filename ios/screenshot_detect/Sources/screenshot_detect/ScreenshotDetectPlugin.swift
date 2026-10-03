import Flutter
import UIKit

public final class ScreenshotDetectPlugin: NSObject, FlutterPlugin {
    private let screenshots = ScreenshotObserver()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ScreenshotDetectPlugin()
        ScreenshotEventsStreamHandler.register(
            with: registrar.messenger(), streamHandler: instance.screenshots
        )
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        screenshots.onCancel(withArguments: nil)
    }
}

private final class ScreenshotObserver: ScreenshotEventsStreamHandler {
    private var observer: NSObjectProtocol?

    override func onListen(
        withArguments arguments: Any?, sink: PigeonEventSink<ScreenshotEvent>
    ) {
        stopObserving()
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            sink.success(.taken)
        }
    }

    override func onCancel(withArguments arguments: Any?) {
        stopObserving()
    }

    private func stopObserving() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    deinit {
        stopObserving()
    }
}
