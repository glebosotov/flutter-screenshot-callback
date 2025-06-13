import Flutter
import UIKit

public class SwiftScreenshotDetectPlugin: NSObject, FlutterPlugin {
    static var observer: NSObjectProtocol?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let flutterAPI = ScreenshotDetectApi(binaryMessenger: messenger)
        
        if let observer = SwiftScreenshotDetectPlugin.observer {
            NotificationCenter.default.removeObserver(observer)
            SwiftScreenshotDetectPlugin.observer = nil
        }
        
        SwiftScreenshotDetectPlugin.observer = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main) { [flutterAPI] _ in
                Task {
                    await flutterAPI.didTakeScreenshot()
                }
            }
    }
    
    deinit {
        if let observer = SwiftScreenshotDetectPlugin.observer {
            NotificationCenter.default.removeObserver(observer);
            SwiftScreenshotDetectPlugin.observer = nil;
        }
    }
}
