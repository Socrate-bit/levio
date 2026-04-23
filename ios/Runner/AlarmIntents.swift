import AlarmKit
import AppIntents
import SwiftUI

// MARK: - Open App Intent (secondary button — unchanged behavior)

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

// MARK: - Open-App "Stop" Intent (bursts only)
//
// Used for burst .fixed alarms' Stop button. Silencing the whole cascade is
// expressed app-side via `cancelBurstsKeepMaster` — individual bursts ring to
// their natural end; the 20s spacing is what controls cadence.

@available(iOS 26.0, *)
public struct OpenAppIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Stop"
    public static var description = IntentDescription("Opens the app")
    public static var openAppWhenRun = true

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) { self.alarmID = alarmID }
    public init() { self.alarmID = "" }

    public func perform() async throws -> some IntentResult { .result() }
}

// MARK: - Master Stop + Reschedule Intent
//
// Wired to the MASTER alarm's Stop button. Stops the master ring (which
// preserves the weekly schedule for .relative and deletes the .fixed one-
// shot), schedules a single +5s nudge burst so the cascade intensity stays
// honest if the user taps Stop just to get the master off-screen, and
// opens the app so the mission can begin.

@available(iOS 26.0, *)
public struct StopRescheduleOpenAppIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Stop"
    public static var description = IntentDescription("Stops the alarm and opens the app")
    public static var openAppWhenRun = true

    @Parameter(title: "alarmID")
    public var alarmID: String

    public init(alarmID: String) { self.alarmID = alarmID }
    public init() { self.alarmID = "" }

    public func perform() async throws -> some IntentResult {
        let originalId = alarmID
        let defaults = UserDefaults.standard

        // Stop the master ring if alerting. stop() preserves the weekly
        // schedule for .relative and deletes the .fixed one-shot.
        if let masterIdString = defaults.string(forKey: "levio_master_\(originalId)"),
           let masterUUID = UUID(uuidString: masterIdString) {
            try? AlarmManager.shared.stop(id: masterUUID)
        }

        // Add a +5s nudge burst behind the master.
        await LevioAlarmKit.scheduleNudgeBurst(originalId: originalId)

        return .result()
    }
}
