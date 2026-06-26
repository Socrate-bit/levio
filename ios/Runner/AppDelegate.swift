import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required by flutter_local_notifications so iOS routes notification
    // delivery and taps through the plugin (otherwise reminders never appear).
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Lets flutter_local_notifications register plugins in its background isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
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
