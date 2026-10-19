import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var captureEventSink: FlutterEventSink?
  private var captureObserver: NSObjectProtocol?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Registered here, not via window.rootViewController: with the implicit engine
    // the root view controller may not exist yet when the app finishes launching.
    FlutterEventChannel(
      name: "ustaz/screen_capture",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
      .setStreamHandler(self)
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    captureEventSink = events
    events(UIScreen.main.isCaptured)
    captureObserver = NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.captureEventSink?(UIScreen.main.isCaptured)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let observer = captureObserver { NotificationCenter.default.removeObserver(observer) }
    captureObserver = nil
    captureEventSink = nil
    return nil
  }
}
