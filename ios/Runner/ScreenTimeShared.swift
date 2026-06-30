import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

// Shared between the Runner app and the DeviceActivityMonitor / Shield
// extensions. Add this file to all three targets in Xcode (Target Membership).
//
// State that must cross the process boundary (the blocked-app selection, the
// schedule list, the master enabled flag) lives in the shared App Group's
// UserDefaults. The actual blocking is applied to a named ManagedSettingsStore
// which iOS shares between the app and its extensions.

@available(iOS 16.0, *)
extension ManagedSettingsStore.Name {
    /// Named store shared by the app + its extensions.
    static let levio = ManagedSettingsStore.Name("levio.screentime")
}

/// A single blocking window, mirroring the Dart `ScreenTimeSchedule` JSON.
struct STSchedule: Codable {
    let id: String
    let enabled: Bool
    /// Length 7, index 0 = Sunday … 6 = Saturday (matches the Dart/alarm side).
    let repeatDays: [Bool]
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int

    private var startMinutes: Int { startHour * 60 + startMinute }
    private var endMinutes: Int { endHour * 60 + endMinute }

    /// Whether `date` falls inside this window, respecting repeat days and the
    /// overnight wrap (the window belongs to the day it starts on).
    func isActive(at date: Date, calendar: Calendar) -> Bool {
        guard enabled, repeatDays.count == 7 else { return false }
        let comps = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        let nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let todayIndex = ((comps.weekday ?? 1) - 1) % 7 // weekday: 1=Sun
        let start = startMinutes
        let end = endMinutes

        if start <= end {
            return repeatDays[todayIndex] && nowMinutes >= start && nowMinutes < end
        }
        // Overnight window.
        if nowMinutes >= start { return repeatDays[todayIndex] }
        if nowMinutes < end {
            let yesterdayIndex = (todayIndex + 6) % 7
            return repeatDays[yesterdayIndex]
        }
        return false
    }
}

@available(iOS 16.0, *)
enum ScreenTimeStore {
    static let appGroup = "group.com.example.levio.screentime"
    static let activityPrefix = "levio.screentime."

    private static let selectionKey = "fa_selection"
    private static let schedulesKey = "schedules"
    private static let enabledKey = "enabled"

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    // MARK: - Selection (opaque FamilyControls tokens)

    static func saveSelection(_ selection: FamilyActivitySelection) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        defaults?.set(data, forKey: selectionKey)
    }

    static func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults?.data(forKey: selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return selection
    }

    static func selectionCount() -> Int {
        let s = loadSelection()
        return s.applicationTokens.count + s.categoryTokens.count + s.webDomainTokens.count
    }

    // MARK: - Config

    static func saveConfig(enabled: Bool, schedules: [STSchedule]) {
        defaults?.set(enabled, forKey: enabledKey)
        if let data = try? JSONEncoder().encode(schedules) {
            defaults?.set(data, forKey: schedulesKey)
        }
    }

    static func loadEnabled() -> Bool { defaults?.bool(forKey: enabledKey) ?? false }

    static func loadSchedules() -> [STSchedule] {
        guard let data = defaults?.data(forKey: schedulesKey),
              let schedules = try? JSONDecoder().decode([STSchedule].self, from: data)
        else { return [] }
        return schedules
    }

    // MARK: - Shield

    /// Recomputes whether blocking should currently be on from the stored
    /// config, and applies or clears the shield accordingly. Safe to call from
    /// the app or from the monitor extension at any interval boundary.
    static func reconcile(now: Date = Date()) {
        let calendar = Calendar.current
        var shouldBlock = false
        if loadEnabled() {
            for schedule in loadSchedules() where schedule.isActive(at: now, calendar: calendar) {
                shouldBlock = true
                break
            }
        }
        if shouldBlock {
            applyShield()
        } else {
            clearShield()
        }
    }

    static func applyShield() {
        let selection = loadSelection()
        let store = ManagedSettingsStore(named: .levio)
        let apps = selection.applicationTokens
        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        // Prevent deleting apps (device-wide) while a window is open. (req #4)
        // The app-removal restriction is only honored on the *default* store, so
        // apply it there rather than on the named `.levio` store.
        ManagedSettingsStore().application.denyAppRemoval = true
    }

    static func clearShield() {
        let store = ManagedSettingsStore(named: .levio)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.application.denyAppRemoval = false
        ManagedSettingsStore().application.denyAppRemoval = false
    }
}
