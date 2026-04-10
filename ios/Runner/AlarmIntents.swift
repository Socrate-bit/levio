import AlarmKit
import AppIntents

// MARK: - Open App Intent (secondary button)

@available(iOS 26.0, *)
public struct OpenAlarmAppIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Open App"
    public static var description = IntentDescription("Opens the app on the challenge page")
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
    public static var openAppWhenRun = false

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) { self.alarmID = alarmID }
    public init() { self.alarmID = "" }

    public func perform() async throws -> some IntentResult {
        guard let oldUUID = UUID(uuidString: alarmID) else { return .result() }

        let defaults = UserDefaults.standard

        // If challenge was already completed via the app, just stop — don't reschedule.
        let completedKey = "levio_completed_\(alarmID)"
        if defaults.bool(forKey: completedKey) {
            defaults.removeObject(forKey: completedKey)
            try? AlarmManager.shared.stop(id: oldUUID)
            return .result()
        }

        // Read stored config so we can rebuild the alarm.
        guard let data = defaults.data(forKey: "levio_config_\(alarmID)"),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            try? AlarmManager.shared.stop(id: oldUUID)
            return .result()
        }

        try? AlarmManager.shared.stop(id: oldUUID)

        // Schedule a new one-shot alarm 5 minutes from now.
        let newId = UUID()
        let fireDate = Date().addingTimeInterval(5 * 60)

        let title = config["title"] as? String ?? "Alarm"
        let sfSymbol = config["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = config["secondaryLabel"] as? String ?? "Open"
        let soundFileName = config["soundFileName"] as? String

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
        let sound: AlertConfiguration.AlertSound = soundFileName.map { .named($0) } ?? .default
        let newConfig = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(fireDate),
            attributes: attributes,
            stopIntent: StopAndRescheduleIntent(alarmID: newId.uuidString),
            secondaryIntent: OpenAlarmAppIntent(alarmID: newId.uuidString),
            sound: sound
        )

        try? await AlarmManager.shared.schedule(id: newId, configuration: newConfig)

        // Carry config to the new UUID.
        defaults.set(data, forKey: "levio_config_\(newId.uuidString)")
        defaults.removeObject(forKey: "levio_config_\(alarmID)")

        // Signal to the main app (read in _syncAlarms) so Firestore can be updated.
        defaults.set(newId.uuidString, forKey: "levio_rescheduled_\(alarmID)")

        return .result()
    }
}
