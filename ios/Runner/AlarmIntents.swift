import AlarmKit
import AppIntents
import SwiftUI

// MARK: - Open App Intent (secondary button)

@available(iOS 26.0, *)
public struct OpenAlarmAppIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Open App"
    public static var description = IntentDescription("Opens the app")
    public static var openAppWhenRun = true

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) { self.alarmID = alarmID }
    public init() { self.alarmID = "" }

    public func perform() async throws -> some IntentResult { .result() }
}

// MARK: - Stop & Reschedule Intent (stop button)

@available(iOS 26.0, *)
public struct StopAndRescheduleIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Stop"
    public static var description = IntentDescription("Stops the alarm and reschedules it shortly")
    public static var openAppWhenRun = true

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) { self.alarmID = alarmID }
    public init() { self.alarmID = "" }

    public func perform() async throws -> some IntentResult {
        guard let oldUUID = UUID(uuidString: alarmID) else { return .result() }

        let defaults = UserDefaults.standard

        // Resolve the original alarm ID.
        // If alarmID is itself a snooze, follow the link; otherwise alarmID IS the original.
        let originalId = defaults.string(forKey: "levio_snooze_\(alarmID)") ?? alarmID

        // Read stored config so we can rebuild the snooze alarm.
        guard let data = defaults.data(forKey: "levio_config_\(alarmID)"),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            try? AlarmManager.shared.stop(id: oldUUID)
            return .result()
        }

        // Stop the current ringing alarm (recurring original stays scheduled for future occurrences).
        try? AlarmManager.shared.stop(id: oldUUID)

        // Clean up the current snooze link (if this was a snooze).
        defaults.removeObject(forKey: "levio_snooze_\(alarmID)")

        // Schedule a new one-shot snooze alarm 1 second from now.
        let newId = UUID()
        let fireDate = Date().addingTimeInterval(1)

        let title = config["title"] as? String ?? "Alarm"
        let sfSymbol = config["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = config["secondaryLabel"] as? String ?? "Open"

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
        let newConfig = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(fireDate),
            attributes: attributes,
            stopIntent: StopAndRescheduleIntent(alarmID: newId.uuidString),
            secondaryIntent: OpenAlarmAppIntent(alarmID: newId.uuidString)
        )

        try? await AlarmManager.shared.schedule(id: newId, configuration: newConfig)

        // Carry display config to the new snooze UUID.
        defaults.set(data, forKey: "levio_config_\(newId.uuidString)")
        defaults.removeObject(forKey: "levio_config_\(alarmID)")

        // Link new snooze → original so getRingingAlarm can look up mission info.
        defaults.set(originalId, forKey: "levio_snooze_\(newId.uuidString)")

        return .result()
    }
}
