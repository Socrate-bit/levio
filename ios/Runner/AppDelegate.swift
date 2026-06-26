import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if #available(iOS 26.0, *) {
      if let alarmRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "LevioAlarmKit") {
        LevioAlarmKit.register(with: alarmRegistrar)
      }
    }

    if #available(iOS 16.0, *) {
      if let screenTimeRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "LevioScreenTime") {
        LevioScreenTime.register(with: screenTimeRegistrar)
      }
    }
  }
}
