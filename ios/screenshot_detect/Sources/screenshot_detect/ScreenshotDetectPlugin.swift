import Flutter
import UIKit

public final class ScreenshotDetectPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var observer: NSObjectProtocol?
    private var channel: FlutterEventChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ScreenshotDetectPlugin()
        let channel = FlutterEventChannel(
            name: "screenshot_detect/events",
            binaryMessenger: registrar.messenger()
        )
        instance.channel = channel
        channel.setStreamHandler(instance)
        registrar.publish(instance)
    }

    public func onListen(
        withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        stopObserving()
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            events(nil)
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopObserving()
        return nil
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        stopObserving()
        channel?.setStreamHandler(nil)
        channel = nil
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
