import Flutter
import AlarmKit
import ActivityKit
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

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        LevioAlarmStreamHandler.shared = self
        self.eventSink = events

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
        case "getAlarmIds":
            Task { await getAlarmIds(result: result) }
        case "getAlarms":
            Task { await getAlarms(result: result) }
        case "getRingingId":
            Task { await getRingingId(result: result) }
        case "getSnoozeMap":
            getSnoozeMap(result: result)
        case "scheduleMissionSnooze":
            Task { await scheduleMissionSnooze(call: call, result: result) }
        case "cleanupConfig":
            cleanupConfig(call: call, result: result)
        case "cleanupSnoozeLink":
            cleanupSnoozeLink(call: call, result: result)
        case "cancelSnoozesForAlarm":
            Task { await cancelSnoozesForAlarm(call: call, result: result) }
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
        let soundPath = args["soundPath"] as? String
        let alarmId = UUID()
        let date = Date(timeIntervalSince1970: timestampMs / 1000)

        let soundName = prepareSoundFile(soundPath: soundPath)

        let config = makeAlarmConfig(
            id: alarmId,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            schedule: .fixed(date),
            soundName: soundName
        )

        do {
            let alarm = try await AlarmManager.shared.schedule(id: alarmId, configuration: config)
            saveConfig(id: alarmId, title: title, sfSymbol: sfSymbol, secondaryLabel: secondaryLabel,
                       isOneShot: true, timestampMs: timestampMs, soundPath: soundPath)
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
        let soundPath = args["soundPath"] as? String
        let alarmId = UUID()
        let weekdays = decodeWeekdays(from: mask)
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
        let schedule = Alarm.Schedule.Relative(time: time, repeats: recurrence)

        let soundName = prepareSoundFile(soundPath: soundPath)

        let config = makeAlarmConfig(
            id: alarmId,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            schedule: .relative(schedule),
            soundName: soundName
        )

        do {
            let alarm = try await AlarmManager.shared.schedule(id: alarmId, configuration: config)
            saveConfig(id: alarmId, title: title, sfSymbol: sfSymbol, secondaryLabel: secondaryLabel,
                       isOneShot: false, weekdayMask: mask, hour: hour, minute: minute, soundPath: soundPath)
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
            // Cancel all snoozes first
            await cancelSnoozesForAlarm(call: FlutterMethodCall(methodName: "cancelSnoozesForAlarm", arguments: ["originalAlarmId": idString]), result: { _ in })

            // Cancel the alarm itself
            try AlarmManager.shared.cancel(id: uuid)
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

    // MARK: - Get Alarm IDs

    private func getAlarmIds(result: @escaping FlutterResult) async {
        do {
            let alarms = try AlarmManager.shared.alarms
            let nativeIds = Set(alarms.map { $0.id.uuidString })
            result(Array(nativeIds))
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

    // MARK: - Get Snooze Map (read-only: {snoozeId → originalId})

    private func getSnoozeMap(result: @escaping FlutterResult) {
        let defaults = UserDefaults.standard
        var map: [String: String] = [:]
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("levio_snooze_") {
                let snoozeId = String(key.dropFirst("levio_snooze_".count))
                if let originalId = defaults.string(forKey: key) {
                    map[snoozeId] = originalId
                }
            }
        }
        result(map)
    }

    // MARK: - Schedule Mission Snooze
    // Schedules a one-shot snooze alarm using the config of an existing alarm.
    // Links the snooze to the original via UserDefaults so _resolveEntry works.

    private func scheduleMissionSnooze(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let nativeId = args["nativeAlarmId"] as? String,
              let originalId = args["originalAlarmId"] as? String,
              let delaySeconds = args["delaySeconds"] as? Int else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing nativeAlarmId/originalAlarmId/delaySeconds", details: nil))
            return
        }

        let defaults = UserDefaults.standard

        // Read config from the currently ringing alarm (or original).
        let configKey = defaults.data(forKey: "levio_config_\(nativeId)") != nil
            ? "levio_config_\(nativeId)"
            : "levio_config_\(originalId)"
        guard let data = defaults.data(forKey: configKey),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            result(FlutterError(code: "BAD_ARGS", message: "No config found for alarm", details: nil))
            return
        }

        let title = config["title"] as? String ?? "Alarm"
        let sfSymbol = config["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = config["secondaryLabel"] as? String ?? "Open"
        let soundPath = config["soundPath"] as? String

        let newId = UUID()
        let fireDate = Date().addingTimeInterval(Double(delaySeconds))

        let soundName = prepareSoundFile(soundPath: soundPath)

        let alarmConfig = makeAlarmConfig(
            id: newId,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            schedule: .fixed(fireDate),
            soundName: soundName
        )

        do {
            try await AlarmManager.shared.schedule(id: newId, configuration: alarmConfig)
            // Link snooze → original so _resolveEntry can look up mission info.
            // Don't save config for snoozes; they use the original's config.
            defaults.set(originalId, forKey: "levio_snooze_\(newId.uuidString)")
            result(newId.uuidString)
        } catch {
            result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
        }
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
        defaults.removeObject(forKey: "levio_snooze_\(idString)")
        // Remove orphaned snooze links where this alarm was the original.
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("levio_snooze_"),
               defaults.string(forKey: key) == idString {
                defaults.removeObject(forKey: key)
            }
        }
        result(nil)
    }

    private func cleanupSnoozeLink(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let idString = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid alarm ID", details: nil))
            return
        }
        let defaults = UserDefaults.standard
        // Remove snooze link for this ID (if it's a snooze).
        defaults.removeObject(forKey: "levio_snooze_\(idString)")
        // Remove snooze links where this ID is the original alarm.
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("levio_snooze_"),
               defaults.string(forKey: key) == idString {
                defaults.removeObject(forKey: key)
            }
        }
        result(nil)
    }

    private func cancelSnoozesForAlarm(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["originalAlarmId"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing originalAlarmId", details: nil))
            return
        }

        let defaults = UserDefaults.standard
        var snoozeIdsToCancel: [String] = []

        // Find all snoozes pointing to this original alarm
        for (key, value) in defaults.dictionaryRepresentation() {
            if key.hasPrefix("levio_snooze_"),
               let snoozeOriginalId = value as? String,
               snoozeOriginalId == originalId {
                // Extract snooze UUID from key (format: "levio_snooze_{uuid}")
                let snoozeId = String(key.dropFirst("levio_snooze_".count))
                snoozeIdsToCancel.append(snoozeId)
            }
        }

        // Cancel all snoozes
        do {
            let alarms = try AlarmManager.shared.alarms
            for snoozeIdString in snoozeIdsToCancel {
                if let snoozeUUID = UUID(uuidString: snoozeIdString),
                   alarms.contains(where: { $0.id == snoozeUUID }) {
                    try AlarmManager.shared.cancel(id: snoozeUUID)
                    defaults.removeObject(forKey: "levio_snooze_\(snoozeIdString)")
                }
            }
            result(nil)
        } catch {
            result(FlutterError(code: "CANCEL_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Helpers

    private func makeAlarmConfig(
        id: UUID,
        title: String,
        sfSymbol: String,
        secondaryLabel: String,
        schedule: Alarm.Schedule,
        soundName: String? = nil
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

        // Use custom sound if provided, otherwise system default
        let sound: AlertConfiguration.AlertSound = {
            if let name = soundName {
                return .named(name)
            }
            return .default
        }()

        return AlarmManager.AlarmConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopAndRescheduleIntent(alarmID: id.uuidString),
            secondaryIntent: OpenAlarmAppIntent(alarmID: id.uuidString),
            sound: sound
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
        minute: Int = 0,
        soundPath: String? = nil
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
        if let soundPath = soundPath {
            config["soundPath"] = soundPath
        }
        if let data = try? JSONSerialization.data(withJSONObject: config) {
            UserDefaults.standard.set(data, forKey: "levio_config_\(id.uuidString)")
        }
    }



    /// Copies the sound file to Library/Sounds so AlarmKit can find it via .named().
    /// Returns the filename to pass to AlertConfiguration.AlertSound.named(), or nil for default.
    private func prepareSoundFile(soundPath: String?) -> String? {
        guard let soundPath = soundPath else { return nil }

        let fileManager = FileManager.default
        let soundsDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds")
        try? fileManager.createDirectory(at: soundsDir, withIntermediateDirectories: true)

        let sourceURL: URL?
        if soundPath.hasPrefix("assets/") {
            // Flutter asset — look up the real bundle path
            let key = FlutterDartProject.lookupKey(forAsset: soundPath)
            if let bundlePath = Bundle.main.path(forResource: key, ofType: nil) {
                sourceURL = URL(fileURLWithPath: bundlePath)
            } else {
                NSLog("[LevioAlarmKit] prepareSoundFile: Flutter asset not found for key '%@'", key)
                return nil
            }
        } else {
            // Custom sound — absolute file path
            sourceURL = URL(fileURLWithPath: soundPath)
        }

        guard let source = sourceURL else { return nil }

        let filename = source.lastPathComponent
        let destination = soundsDir.appendingPathComponent(filename)

        // Copy if not already present (or replace if source is newer)
        if !fileManager.fileExists(atPath: destination.path) {
            do {
                try fileManager.copyItem(at: source, to: destination)
            } catch {
                NSLog("[LevioAlarmKit] prepareSoundFile: copy failed — %@", error.localizedDescription)
                return nil
            }
        }

        return filename
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
