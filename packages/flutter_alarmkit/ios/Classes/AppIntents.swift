import AlarmKit
import AppIntents

@available(iOS 26.0, *)
public struct PauseIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        try AlarmManager.shared.pause(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    public static var title: LocalizedStringResource = "Pause"
    public static var description = IntentDescription("Pause a countdown")

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) { self.alarmID = alarmID }
    public init() { self.alarmID = "" }
}

@available(iOS 26.0, *)
public struct StopIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        try AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    public static var title: LocalizedStringResource = "Stop"
    public static var description = IntentDescription("Stop an alert")

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) { self.alarmID = alarmID }
    public init() { self.alarmID = "" }
}

@available(iOS 26.0, *)
public struct RepeatIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        try AlarmManager.shared.countdown(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    public static var title: LocalizedStringResource = "Repeat"
    public static var description = IntentDescription("Repeat a countdown")

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) { self.alarmID = alarmID }
    public init() { self.alarmID = "" }
}

@available(iOS 26.0, *)
public struct ResumeIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        try AlarmManager.shared.resume(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    public static var title: LocalizedStringResource = "Resume"
    public static var description = IntentDescription("Resume a countdown")

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) { self.alarmID = alarmID }
    public init() { self.alarmID = "" }
}

@available(iOS 26.0, *)
public struct OpenAlarmAppIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        let key = "levio_debug_intent_fired_count"
        let prev = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(prev + 1, forKey: key)
        NSLog("[OpenAlarmAppIntent] perform #%d alarmID=%@", prev + 1, alarmID)

        // Set the pending flag so AlarmService navigates on app open.
        UserDefaults.standard.set(true, forKey: "levio_pending_alarm_dismiss")

        // Emit directly to the Flutter stream — visible in `flutter run` output.
        // If Dart sees "intentFired" → intent runs in the main app process.
        // If Dart never sees it → intent runs in a separate process (or never fires).
        AlarmUpdateStreamHandler.shared?.emit([
            "event": "intentFired",
            "alarmID": alarmID,
        ])

        return .result()
    }

    public static var title: LocalizedStringResource = "Open App"
    public static var description = IntentDescription("Opens the app for the alarm challenge")
    public static var openAppWhenRun = true

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) { self.alarmID = alarmID }
    public init() { self.alarmID = "" }
}
