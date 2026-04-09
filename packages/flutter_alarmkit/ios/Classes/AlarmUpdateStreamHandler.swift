import Flutter
import AlarmKit

/// The name used by AppDelegate to signal a notification action tap to the
/// stream handler without requiring a direct import of the plugin module.
let levioAlarmNotificationTappedName = Notification.Name("levio.alarmNotificationTapped")

@available(iOS 26.0, *)
class AlarmUpdateStreamHandler: NSObject, FlutterStreamHandler {
    /// Shared instance so that the plugin can forward events from outside
    /// (e.g. after a UNNotificationResponse is received by AppDelegate).
    static weak var shared: AlarmUpdateStreamHandler?

    private var streamTask: Task<Void, Never>?
    private var previousAlarms: Set<UUID> = []

    /// The active event sink; nil when the Flutter side is not listening.
    private var eventSink: FlutterEventSink?

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        AlarmUpdateStreamHandler.shared = self
        self.eventSink = events

        // Listen for notification-action taps posted by AppDelegate.
        // Using Foundation NotificationCenter avoids any direct import of this
        // module in the host app.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAlarmNotificationTapped(_:)),
            name: levioAlarmNotificationTappedName,
            object: nil
        )

        self.streamTask = Task {
            for await alarms in AlarmManager.shared.alarmUpdates {
                let currentAlarmIds = Set(alarms.map { $0.id })

                // Added
                let addedAlarms = currentAlarmIds.subtracting(previousAlarms)
                for alarmId in addedAlarms {
                    if let alarm = alarms.first(where: { $0.id == alarmId }) {
                        var eventData: [String: Any] = [:]
                        eventData["id"] = alarm.id.uuidString
                        eventData["event"] = "add"
                        eventData["alarm"] = alarm.toDictionary()
                        DispatchQueue.main.async { events(eventData) }
                    }
                }

                // Removed
                let removedAlarmIds = previousAlarms.subtracting(currentAlarmIds)
                for alarmId in removedAlarmIds {
                    var eventData: [String: Any] = [:]
                    eventData["id"] = alarmId.uuidString
                    eventData["event"] = "remove"
                    DispatchQueue.main.async { events(eventData) }
                }

                // Updated
                let existingAlarms = currentAlarmIds.intersection(previousAlarms)
                for alarmId in existingAlarms {
                    if let alarm = alarms.first(where: { $0.id == alarmId }) {
                        var eventData: [String: Any] = [:]
                        eventData["id"] = alarm.id.uuidString
                        eventData["event"] = "update"
                        eventData["alarm"] = alarm.toDictionary()
                        DispatchQueue.main.async { events(eventData) }
                    }
                }

                previousAlarms = currentAlarmIds
            }
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self, name: levioAlarmNotificationTappedName, object: nil)
        streamTask?.cancel()
        streamTask = nil
        eventSink = nil
        return nil
    }

    // MARK: - External event injection

    /// Emit an arbitrary event payload to the Flutter stream.
    func emit(_ data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(data)
        }
    }

    /// Handles the Foundation notification posted by AppDelegate when the user
    /// taps a notification action (including the "Do push-up" banner button).
    @objc private func handleAlarmNotificationTapped(_ notification: Notification) {
        let alarmId = notification.userInfo?["alarmId"] as? String ?? ""
        emit([
            "event": "secondaryButtonTapped",
            "id": alarmId,
        ])
    }
}
