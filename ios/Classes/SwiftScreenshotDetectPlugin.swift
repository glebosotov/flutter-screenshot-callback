import Flutter
import UIKit

public class SwiftScreenshotDetectPlugin: NSObject, FlutterPlugin {

    static var channel: FlutterMethodChannel?
    static var observer: NSObjectProtocol?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "screenshot_detect", binaryMessenger: registrar.messenger())
        observer = nil
        let instance = SwiftScreenshotDetectPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel!)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "initialize" {
            
            if SwiftScreenshotDetectPlugin.observer != nil {
                NotificationCenter.default.removeObserver(SwiftScreenshotDetectPlugin.observer!)
                SwiftScreenshotDetectPlugin.observer = nil
            }
            
            SwiftScreenshotDetectPlugin.observer = NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: OperationQueue.main)
            { notification in
                if let channel = SwiftScreenshotDetectPlugin.channel {
                    channel.invokeMethod("onCallback", arguments: nil)
                }
                result("Caallback invoked")
            }
            result("Initialized")
            
        } else if call.method == "dispose" {
            if SwiftScreenshotDetectPlugin.observer != nil {
                NotificationCenter.default.removeObserver(SwiftScreenshotDetectPlugin.observer!)
                SwiftScreenshotDetectPlugin.observer = nil
            }
            result("Disposed")
            
        } else {
            result("Unknown function")
        }
        
        
    }
    
    deinit {
        if SwiftScreenshotDetectPlugin.observer != nil {
            NotificationCenter.default.removeObserver(SwiftScreenshotDetectPlugin.observer!);
            SwiftScreenshotDetectPlugin.observer = nil;
        }
    }
}
