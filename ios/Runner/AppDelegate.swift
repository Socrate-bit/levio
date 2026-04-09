import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  /// UserDefaults key written when the user taps a notification action while
  /// the app is killed (cold-start path — Flutter stream is not yet active).
  private static let pendingDismissKey = "levio_pending_alarm_dismiss"
  private static let intentFiredCountKey = "levio_debug_intent_fired_count"
  private static let delegateFiredCountKey = "levio_debug_delegate_fired_count"

  /// Foundation notification name shared with the plugin's stream handler.
  private static let alarmTappedName = Notification.Name("levio.alarmNotificationTapped")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Method channel so Dart can check / clear the cold-start pending flag.
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LevioAlarmActionPlugin") else { return }
    let channel = FlutterMethodChannel(
      name: "levio/alarm-action",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "hasPendingDismiss":
        let pending = UserDefaults.standard.bool(forKey: AppDelegate.pendingDismissKey)
        result(pending)
      case "clearPendingDismiss":
        UserDefaults.standard.removeObject(forKey: AppDelegate.pendingDismissKey)
        result(nil)
      case "getDebugLog":
        let pending = UserDefaults.standard.bool(forKey: AppDelegate.pendingDismissKey)
        let intentCount = UserDefaults.standard.integer(forKey: AppDelegate.intentFiredCountKey)
        let delegateCount = UserDefaults.standard.integer(forKey: AppDelegate.delegateFiredCountKey)
        result([
          "pendingDismiss": pending,
          "intentFiredCount": intentCount,
          "delegateFiredCount": delegateCount,
        ])
      case "clearDebugLog":
        UserDefaults.standard.removeObject(forKey: AppDelegate.intentFiredCountKey)
        UserDefaults.standard.removeObject(forKey: AppDelegate.delegateFiredCountKey)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - UNUserNotificationCenterDelegate

  /// Called when the user taps any notification action (including AlarmKit
  /// banner buttons like "Do push-up") while the app is in the background.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let alarmId = response.notification.request.identifier
    let actionId = response.actionIdentifier
    NSLog("[AppDelegate] didReceive notification response: alarmId=%@ actionId=%@", alarmId, actionId)

    let prevCount = UserDefaults.standard.integer(forKey: AppDelegate.delegateFiredCountKey)
    UserDefaults.standard.set(prevCount + 1, forKey: AppDelegate.delegateFiredCountKey)

    // ① Warm path — Flutter engine is already running, plugin stream is active.
    //   Post to the Foundation NotificationCenter that AlarmUpdateStreamHandler
    //   is observing; it will emit a "secondaryButtonTapped" event to Dart.
    NotificationCenter.default.post(
      name: AppDelegate.alarmTappedName,
      object: nil,
      userInfo: ["alarmId": alarmId]
    )

    // ② Cold-start fallback — if the app was killed the stream isn't listening
    //   yet. AlarmService reads this flag on first frame and navigates.
    UserDefaults.standard.set(true, forKey: AppDelegate.pendingDismissKey)

    completionHandler()
  }
}
