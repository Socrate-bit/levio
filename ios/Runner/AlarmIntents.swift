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

// MARK: - Open-App "Stop" Intent (replaces StopAndRescheduleIntent)
//
// Both buttons now simply launch the app; Dart handles all silencing via the
// cascade-cancel API. Every ringing burst will naturally finish on its own or
// be cancelled by the Dart suppression timer.

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
