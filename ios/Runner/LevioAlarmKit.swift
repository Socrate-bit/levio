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
    private func isAlerting(_ alarm: Alarm) -> Bool {
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
        case "getAlarms":
            Task { await getAlarms(result: result) }
        case "getRingingId":
            Task { await getRingingId(result: result) }
        case "getPendingReschedules":
            getPendingReschedules(result: result)
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
            saveConfig(id: alarmId, title: title, sfSymbol: sfSymbol, secondaryLabel: secondaryLabel,
                       isOneShot: false, weekdayMask: mask, hour: hour, minute: minute)
            result(alarm.id.uuidString)
        } catch {
            result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Cancel

    private func cancelAlarm(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let idString = call.arguments as? String,
              let uuid = UUID(uuidString: idString) else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid alarm ID", details: nil))
            return
        }
        do {
            try AlarmManager.shared.cancel(id: uuid)
            UserDefaults.standard.removeObject(forKey: "levio_config_\(idString)")
            result(nil)
        } catch {
            result(FlutterError(code: "CANCEL_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Stop (called from Dart after challenge completion)

    private func stopAlarm(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let idString = call.arguments as? String,
              let uuid = UUID(uuidString: idString) else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid alarm ID", details: nil))
            return
        }
        do {
            // Log alarm state before stopping to diagnose intermittent STOP_ERROR
            if let alarms = try? AlarmManager.shared.alarms,
               let alarm = alarms.first(where: { $0.id == uuid }) {
                NSLog("[LevioAlarmKit] stopAlarm: id=%@ state=%@", idString, "\(alarm.state)")
            } else {
                NSLog("[LevioAlarmKit] stopAlarm: id=%@ — alarm not found in AlarmManager", idString)
            }
            try AlarmManager.shared.stop(id: uuid)
            result(nil)
        } catch {
            NSLog("[LevioAlarmKit] stopAlarm FAILED: id=%@ error=%@", idString, "\(error)")
            result(FlutterError(
                code: "STOP_ERROR",
                message: error.localizedDescription,
                details: "\(error)"
            ))
        }
    }

    // MARK: - Mark Completed (prevents StopAndRescheduleIntent from rescheduling)

    private func markCompleted(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let idString = call.arguments as? String else {
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
            result(alarms.map { $0.id.uuidString })
        } catch {
            result([String]())
        }
    }

    // MARK: - Get Alarms (full info)

    private func getAlarms(result: @escaping FlutterResult) async {
        do {
            let alarms = try AlarmManager.shared.alarms
            let list: [[String: Any]] = alarms.map { alarm in
                let idString = alarm.id.uuidString
                var info: [String: Any] = ["id": idString]

                // Alarm state
                switch alarm.state {
                case .scheduled:
                    info["state"] = "scheduled"
                @unknown default:
                    info["state"] = "alerting"
                }

                // Merge saved config from UserDefaults
                if let data = UserDefaults.standard.data(forKey: "levio_config_\(idString)"),
                   let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    info["title"] = config["title"] as? String ?? ""
                    info["sfSymbol"] = config["sfSymbol"] as? String ?? ""
                    info["secondaryLabel"] = config["secondaryLabel"] as? String ?? ""
                    info["isOneShot"] = config["isOneShot"] as? Bool ?? false
                    if let ts = config["timestampMs"] as? Double {
                        info["timestampMs"] = ts
                    }
                    if let mask = config["weekdayMask"] as? Int {
                        info["weekdayMask"] = mask
                    }
                    if let hour = config["hour"] as? Int {
                        info["hour"] = hour
                    }
                    if let minute = config["minute"] as? Int {
                        info["minute"] = minute
                    }
                }

                return info
            }
            result(list)
        } catch {
            result([[String: Any]]())
        }
    }

    // MARK: - Get Ringing ID

    private func getRingingId(result: @escaping FlutterResult) async {
        do {
            let alarms = try AlarmManager.shared.alarms
            let ringing = alarms.first { alarm in
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
            textColor: Color(red: 1.0, green: 107.0 / 255.0, blue: 0.0),
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
