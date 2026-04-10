import Flutter
import AlarmKit
import AppIntents
import SwiftUI

// MARK: - Metadata (no Live Activity, no countdown UI needed)

@available(iOS 26.0, *)
struct LevioAlarmMetadata: AlarmMetadata {}

// MARK: - Stream Handler

@available(iOS 26.0, *)
class LevioAlarmStreamHandler: NSObject, FlutterStreamHandler {
    static weak var shared: LevioAlarmStreamHandler?

    private var streamTask: Task<Void, Never>?
    private var previousAlertingIds: Set<UUID> = []
    private var eventSink: FlutterEventSink?

    private static let alarmTappedName = Notification.Name("levio.alarmNotificationTapped")

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        LevioAlarmStreamHandler.shared = self
        self.eventSink = events

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAlarmTapped(_:)),
            name: LevioAlarmStreamHandler.alarmTappedName,
            object: nil
        )

        streamTask = Task {
            for await alarms in AlarmManager.shared.alarmUpdates {
                let currentAlertingIds = Set(alarms.filter { self.isAlerting($0) }.map { $0.id })

                // New alerting alarms → ring event
                for id in currentAlertingIds.subtracting(previousAlertingIds) {
                    emit(["event": "ring", "id": id.uuidString])
                }

                previousAlertingIds = currentAlertingIds
            }
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self, name: LevioAlarmStreamHandler.alarmTappedName, object: nil)
        streamTask?.cancel()
        streamTask = nil
        eventSink = nil
        return nil
    }

    func emit(_ data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(data)
        }
    }

    // AlarmKit uses @unknown default for the alerting state in iOS 26.
    // Exclude alarms we already stopped/cancelled to prevent spurious ring events on restart.
    private func isAlerting(_ alarm: Alarm) -> Bool {
        if LevioAlarmKit.stoppedIds().contains(alarm.id.uuidString) { return false }
        switch alarm.state {
        case .scheduled:
            return false
        @unknown default:
            return true
        }
    }

    // AppDelegate posts this notification when a notification action or banner is tapped.
    @objc private func handleAlarmTapped(_ notification: Notification) {
        let alarmId = notification.userInfo?["alarmId"] as? String ?? ""
        emit(["event": "intentFired", "id": alarmId])
    }
}

// MARK: - Plugin

@available(iOS 26.0, *)
public class LevioAlarmKit: NSObject, FlutterPlugin {
    private static var registrar: FlutterPluginRegistrar?
    private static let stoppedIdsKey = "levio_stopped_ids"

    // MARK: - Stopped-IDs helpers (shared with stream handler)

    static func stoppedIds() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: stoppedIdsKey) ?? [])
    }

    private func addStoppedId(_ id: String) {
        let defaults = UserDefaults.standard
        var ids = defaults.stringArray(forKey: LevioAlarmKit.stoppedIdsKey) ?? []
        if !ids.contains(id) { ids.append(id) }
        defaults.set(ids, forKey: LevioAlarmKit.stoppedIdsKey)
    }

    private func removeStoppedId(_ id: String) {
        let defaults = UserDefaults.standard
        var ids = defaults.stringArray(forKey: LevioAlarmKit.stoppedIdsKey) ?? []
        ids.removeAll { $0 == id }
        defaults.set(ids, forKey: LevioAlarmKit.stoppedIdsKey)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        self.registrar = registrar

        let channel = FlutterMethodChannel(
            name: "levio/alarmkit",
            binaryMessenger: registrar.messenger()
        )
        let instance = LevioAlarmKit()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(
            name: "levio/alarmkit/events",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(LevioAlarmStreamHandler())
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization":
            Task { await requestAuthorization(result: result) }
        case "scheduleOneShot":
            Task { await scheduleOneShot(call: call, result: result) }
        case "scheduleRepeating":
            Task { await scheduleRepeating(call: call, result: result) }
        case "cancel":
            Task { await cancelAlarm(call: call, result: result) }
        case "stop":
            Task { await stopAlarm(call: call, result: result) }
        case "markCompleted":
            markCompleted(call: call, result: result)
        case "getAlarmIds":
            Task { await getAlarmIds(result: result) }
        case "getRingingId":
            Task { await getRingingId(result: result) }
        case "getPendingReschedules":
            getPendingReschedules(result: result)
        case "peekPendingReschedules":
            peekPendingReschedules(result: result)
        case "cleanupConfig":
            cleanupConfig(call: call, result: result)
        case "getPendingRecurringRestores":
            getPendingRecurringRestores(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Authorization

    private func requestAuthorization(result: @escaping FlutterResult) async {
        do {
            let status = try await AlarmManager.shared.requestAuthorization()
            result(status == .authorized)
        } catch {
            result(false)
        }
    }

    // MARK: - Schedule One-Shot

    private func scheduleOneShot(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let timestampMs = args["timestampMs"] as? Double else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing timestampMs", details: nil))
            return
        }

        let title = args["title"] as? String ?? "Alarm"
        let sfSymbol = args["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = args["secondaryLabel"] as? String ?? "Open"
        let alarmId = UUID()
        let date = Date(timeIntervalSince1970: timestampMs / 1000)

        let config = makeAlarmConfig(
            id: alarmId,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            schedule: .fixed(date)
        )

        do {
            let alarm = try await AlarmManager.shared.schedule(id: alarmId, configuration: config)
            removeStoppedId(alarm.id.uuidString)
            saveConfig(id: alarmId, title: title, sfSymbol: sfSymbol, secondaryLabel: secondaryLabel,
                       isOneShot: true, timestampMs: timestampMs)
            result(alarm.id.uuidString)
        } catch {
            result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Schedule Repeating

    private func scheduleRepeating(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let mask = args["weekdayMask"] as? Int,
              let hour = args["hour"] as? Int,
              let minute = args["minute"] as? Int else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing weekdayMask/hour/minute", details: nil))
            return
        }

        let title = args["title"] as? String ?? "Alarm"
        let sfSymbol = args["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = args["secondaryLabel"] as? String ?? "Open"
        let alarmId = UUID()
        let weekdays = decodeWeekdays(from: mask)
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
        let schedule = Alarm.Schedule.Relative(time: time, repeats: recurrence)

        let config = makeAlarmConfig(
            id: alarmId,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            schedule: .relative(schedule)
        )

        do {
            let alarm = try await AlarmManager.shared.schedule(id: alarmId, configuration: config)
            removeStoppedId(alarm.id.uuidString)
            saveConfig(id: alarmId, title: title, sfSymbol: sfSymbol, secondaryLabel: secondaryLabel,
                       isOneShot: false, weekdayMask: mask, hour: hour, minute: minute)
            result(alarm.id.uuidString)
        } catch {
            result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Cancel

    private func cancelAlarm(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let idString = args["id"] as? String,
              let uuid = UUID(uuidString: idString) else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid alarm ID", details: nil))
            return
        }
        do {
            try AlarmManager.shared.cancel(id: uuid)
            addStoppedId(idString)
            UserDefaults.standard.removeObject(forKey: "levio_config_\(idString)")
            result(nil)
        } catch {
            result(FlutterError(code: "CANCEL_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Stop (called from Dart after challenge completion)

    private func stopAlarm(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let idString = args["id"] as? String,
              let uuid = UUID(uuidString: idString) else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid alarm ID", details: nil))
            return
        }
        do {
            try AlarmManager.shared.stop(id: uuid)
            addStoppedId(idString)
            // Clear completed flag so recurring alarms don't carry stale state to next occurrence
            UserDefaults.standard.removeObject(forKey: "levio_completed_\(idString)")
            result(nil)
        } catch {
            result(FlutterError(code: "STOP_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Mark Completed (prevents StopAndRescheduleIntent from rescheduling)

    private func markCompleted(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let idString = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid alarm ID", details: nil))
            return
        }
        UserDefaults.standard.set(true, forKey: "levio_completed_\(idString)")
        result(nil)
    }

    // MARK: - Get Alarm IDs

    private func getAlarmIds(result: @escaping FlutterResult) async {
        do {
            let alarms = try AlarmManager.shared.alarms
            let nativeIds = Set(alarms.map { $0.id.uuidString })
            // Prune stopped-IDs set to only contain IDs still in native system
            let defaults = UserDefaults.standard
            let stopped = defaults.stringArray(forKey: LevioAlarmKit.stoppedIdsKey) ?? []
            let pruned = stopped.filter { nativeIds.contains($0) }
            defaults.set(pruned, forKey: LevioAlarmKit.stoppedIdsKey)
            result(Array(nativeIds))
        } catch {
            result([String]())
        }
    }

    // MARK: - Get Ringing ID

    private func getRingingId(result: @escaping FlutterResult) async {
        do {
            let alarms = try AlarmManager.shared.alarms
            let stopped = LevioAlarmKit.stoppedIds()
            let ringing = alarms.first { alarm in
                if stopped.contains(alarm.id.uuidString) { return false }
                switch alarm.state {
                case .scheduled: return false
                @unknown default: return true
                }
            }
            result(ringing?.id.uuidString)
        } catch {
            result(nil)
        }
    }

    // MARK: - Get Pending Reschedules

    private func getPendingReschedules(result: @escaping FlutterResult) {
        let defaults = UserDefaults.standard
        var map: [String: String] = [:]
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("levio_rescheduled_") {
                let oldId = String(key.dropFirst("levio_rescheduled_".count))
                if let newId = defaults.string(forKey: key) {
                    map[oldId] = newId
                    defaults.removeObject(forKey: key)
                }
            }
        }
        result(map)
    }

    // MARK: - Peek Pending Reschedules (read-only, does NOT clear keys)

    private func peekPendingReschedules(result: @escaping FlutterResult) {
        let defaults = UserDefaults.standard
        var map: [String: String] = [:]
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("levio_rescheduled_") {
                let oldId = String(key.dropFirst("levio_rescheduled_".count))
                if let newId = defaults.string(forKey: key) {
                    map[oldId] = newId
                }
            }
        }
        result(map)
    }

    // MARK: - Cleanup Config (removes UserDefaults entries for a dismissed alarm)

    private func cleanupConfig(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let idString = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid alarm ID", details: nil))
            return
        }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "levio_config_\(idString)")
        defaults.removeObject(forKey: "levio_completed_\(idString)")
        // Remove from stopped set
        var ids = defaults.stringArray(forKey: LevioAlarmKit.stoppedIdsKey) ?? []
        ids.removeAll { $0 == idString }
        defaults.set(ids, forKey: LevioAlarmKit.stoppedIdsKey)
        result(nil)
    }

    // MARK: - Get Pending Recurring Restores (reads + clears levio_recurring_restore_* keys)

    private func getPendingRecurringRestores(result: @escaping FlutterResult) {
        let defaults = UserDefaults.standard
        var list: [[String: Any]] = []
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("levio_recurring_restore_") {
                let oldId = String(key.dropFirst("levio_recurring_restore_".count))
                if let data = defaults.data(forKey: key),
                   let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var entry = config
                    entry["originalId"] = oldId
                    list.append(entry)
                    defaults.removeObject(forKey: key)
                }
            }
        }
        result(list)
    }

    // MARK: - Helpers

    private func makeAlarmConfig(
        id: UUID,
        title: String,
        sfSymbol: String,
        secondaryLabel: String,
        schedule: Alarm.Schedule
    ) -> AlarmManager.AlarmConfiguration<LevioAlarmMetadata> {
        let stopButton = AlarmButton(
            text: "Stop",
            textColor: .white,
            systemImageName: "xmark.circle"
        )
        let secondaryButton = AlarmButton(
            text: LocalizedStringResource(stringLiteral: secondaryLabel),
            textColor: .white,
            systemImageName: sfSymbol
        )
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: stopButton,
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<LevioAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            tintColor: .white
        )
        return AlarmManager.AlarmConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopAndRescheduleIntent(alarmID: id.uuidString),
            secondaryIntent: OpenAlarmAppIntent(alarmID: id.uuidString)
        )
    }

    private func saveConfig(
        id: UUID,
        title: String,
        sfSymbol: String,
        secondaryLabel: String,
        isOneShot: Bool,
        timestampMs: Double = 0,
        weekdayMask: Int = 0,
        hour: Int = 0,
        minute: Int = 0
    ) {
        var config: [String: Any] = [
            "title": title,
            "sfSymbol": sfSymbol,
            "secondaryLabel": secondaryLabel,
            "isOneShot": isOneShot,
        ]
        if isOneShot {
            config["timestampMs"] = timestampMs
        } else {
            config["weekdayMask"] = weekdayMask
            config["hour"] = hour
            config["minute"] = minute
        }
        if let data = try? JSONSerialization.data(withJSONObject: config) {
            UserDefaults.standard.set(data, forKey: "levio_config_\(id.uuidString)")
        }
    }



    private func decodeWeekdays(from mask: Int) -> [Locale.Weekday] {
        var weekdays: [Locale.Weekday] = []
        if mask & (1 << 0) != 0 { weekdays.append(.monday) }
        if mask & (1 << 1) != 0 { weekdays.append(.tuesday) }
        if mask & (1 << 2) != 0 { weekdays.append(.wednesday) }
        if mask & (1 << 3) != 0 { weekdays.append(.thursday) }
        if mask & (1 << 4) != 0 { weekdays.append(.friday) }
        if mask & (1 << 5) != 0 { weekdays.append(.saturday) }
        if mask & (1 << 6) != 0 { weekdays.append(.sunday) }
        return weekdays
    }

}
