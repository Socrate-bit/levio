import Flutter
import AlarmKit
import ActivityKit
import AppIntents
import SwiftUI

// MARK: - Metadata

@available(iOS 26.0, *)
struct LevioAlarmMetadata: AlarmMetadata {}

// MARK: - Cascade constants

/// Number of bursts per cascade. 24 × 15s = 6 minutes of ringing coverage.
private let kCascadeBurstCount = 24
private let kCascadeIntervalSeconds: TimeInterval = 15

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

                // New alerting alarms → ring event (emit originalId from mapping)
                for burstId in currentAlertingIds.subtracting(previousAlertingIds) {
                    let burstIdString = burstId.uuidString
                    let originalId = UserDefaults.standard.string(
                        forKey: "levio_burst_\(burstIdString)"
                    ) ?? burstIdString
                    emit([
                        "event": "ring",
                        "id": burstIdString,
                        "originalId": originalId,
                    ])
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

    /// Guards `primeCascadeIfNeeded` against overlapping invocations for the
    /// same originalId. Without this, ring-event priming and sync-time priming
    /// could both observe "no .fixed bursts" and each schedule 23 — doubling
    /// the cascade and halving the 15s spacing.
    private static let primingLock = NSLock()
    private static var primingInProgress: Set<String> = []

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
            Task { await scheduleOneShotCascade(call: call, result: result) }
        case "scheduleRepeating":
            Task { await scheduleRepeatingCascade(call: call, result: result) }
        case "cancel":
            Task { await cancelCascade(call: call, result: result) }
        case "cancelBurst":
            Task { await cancelBurst(call: call, result: result) }
        case "rescheduleForNextWeek":
            Task { await rescheduleForNextWeek(call: call, result: result) }
        case "primeCascadeIfNeeded":
            Task { await primeCascadeIfNeeded(call: call, result: result) }
        case "getNextBurst":
            getNextBurst(call: call, result: result)
        case "getAlarmIds":
            getAlarmIds(result: result)
        case "getAlarms":
            getAlarms(result: result)
        case "getRingingId":
            getRingingId(result: result)
        case "cleanupConfig":
            cleanupConfig(call: call, result: result)
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

    // MARK: - Schedule One-Shot Cascade

    /// Schedules `kCascadeBurstCount` one-shot alarms, 15s apart, all sharing
    /// the same logical `originalId`. Returns the `originalId`.
    private func scheduleOneShotCascade(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let timestampMs = args["timestampMs"] as? Double else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing timestampMs", details: nil))
            return
        }

        let title = args["title"] as? String ?? "Alarm"
        let sfSymbol = args["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = args["secondaryLabel"] as? String ?? "Open"
        let soundPath = args["soundPath"] as? String
        let originalId = UUID()
        let baseDate = Date(timeIntervalSince1970: timestampMs / 1000)
        let soundName = prepareSoundFile(soundPath: soundPath)

        // Persist logical config for later reschedule / UI lookup.
        saveConfig(
            originalId: originalId,
            title: title, sfSymbol: sfSymbol, secondaryLabel: secondaryLabel,
            isOneShot: true,
            timestampMs: timestampMs,
            soundPath: soundPath
        )

        let scheduled = await scheduleCascade(
            originalId: originalId,
            baseDate: baseDate,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            soundName: soundName
        )

        if scheduled {
            result(originalId.uuidString)
        } else {
            // Clean up partial state if nothing got scheduled.
            cleanupConfigInternal(originalId: originalId.uuidString)
            result(FlutterError(code: "SCHEDULE_ERROR", message: "Failed to schedule cascade", details: nil))
        }
    }

    // MARK: - Schedule Repeating Cascade

    /// Schedules a 24-burst cascade for the next matching weekday at hour:minute.
    /// Burst 0 uses `.relative(weekly)` as a safety net so the alarm still
    /// fires next matching weekday even if the app never opens to re-prime the
    /// `.fixed` bursts. Bursts 1-23 are `.fixed` one-shots (15s spacing).
    /// Persists weekday/hour/minute config so we can re-schedule after completion.
    private func scheduleRepeatingCascade(call: FlutterMethodCall, result: @escaping FlutterResult) async {
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
        let originalId = UUID()
        let soundName = prepareSoundFile(soundPath: soundPath)

        // Compute the next matching weekday — inclusive of today if hour:minute is still ahead.
        let baseDate = nextMatchingDate(
            mask: mask, hour: hour, minute: minute,
            strictlyAfter: Date().addingTimeInterval(-1)
        )

        saveConfig(
            originalId: originalId,
            title: title, sfSymbol: sfSymbol, secondaryLabel: secondaryLabel,
            isOneShot: false,
            weekdayMask: mask, hour: hour, minute: minute,
            soundPath: soundPath
        )

        let scheduled = await scheduleCascade(
            originalId: originalId,
            baseDate: baseDate,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            soundName: soundName,
            weeklyRecurrence: weekdaysFromMask(mask),
            recurrenceHour: hour,
            recurrenceMinute: minute
        )

        if scheduled {
            result(originalId.uuidString)
        } else {
            cleanupConfigInternal(originalId: originalId.uuidString)
            result(FlutterError(code: "SCHEDULE_ERROR", message: "Failed to schedule cascade", details: nil))
        }
    }

    // MARK: - Cancel Cascade

    /// Cancels every burst of the cascade (including any alerting) and clears
    /// all burst→original mappings. Also removes the saved config — call this
    /// when the alarm itself is deleted/disabled. For mission completion of
    /// a recurrent alarm, use `cancelCascade` followed by `rescheduleForNextWeek`
    /// (which re-primes the cascade under the same originalId).
    private func cancelCascade(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let idString = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing id", details: nil))
            return
        }
        cancelCascadeInternal(originalId: idString)
        result(nil)
    }

    private func cancelCascadeInternal(originalId: String) {
        let defaults = UserDefaults.standard
        let burstIds = loadCascade(originalId: originalId)
        for burstIdString in burstIds {
            if let uuid = UUID(uuidString: burstIdString) {
                try? AlarmManager.shared.cancel(id: uuid)
            }
            defaults.removeObject(forKey: "levio_burst_\(burstIdString)")
        }
        defaults.removeObject(forKey: "levio_cascade_\(originalId)")
        defaults.removeObject(forKey: "levio_relative_burst_\(originalId)")
    }

    // MARK: - Cancel Single Burst

    private func cancelBurst(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["originalId"] as? String,
              let burstIdString = args["burstId"] as? String,
              let uuid = UUID(uuidString: burstIdString) else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing originalId/burstId", details: nil))
            return
        }

        try? AlarmManager.shared.cancel(id: uuid)

        // Drop it from the cascade list.
        var burstIds = loadCascade(originalId: originalId)
        burstIds.removeAll { $0 == burstIdString }
        saveCascade(originalId: originalId, burstIds: burstIds)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "levio_burst_\(burstIdString)")

        // If we just cancelled the `.relative` safety-net burst, schedule a
        // fresh one under a new UUID so weekly recurrence survives app crashes
        // between now and mission completion.
        let relativeBurst = defaults.string(forKey: "levio_relative_burst_\(originalId)")
        if relativeBurst == burstIdString {
            defaults.removeObject(forKey: "levio_relative_burst_\(originalId)")
            await recreateRelativeBurst(originalId: originalId)
        }

        result(nil)
    }

    /// Re-schedules the `.relative(weekly)` safety-net burst for a recurrent
    /// cascade under a new UUID. Called after a `cancelBurst` on the relative
    /// burst so weekly recurrence isn't lost.
    private func recreateRelativeBurst(originalId: String) async {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "levio_config_\(originalId)"),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (config["isOneShot"] as? Bool) == false,
              let mask = config["weekdayMask"] as? Int,
              let hour = config["hour"] as? Int,
              let minute = config["minute"] as? Int,
              let originalUUID = UUID(uuidString: originalId) else {
            return
        }

        let title = config["title"] as? String ?? "Alarm"
        let sfSymbol = config["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = config["secondaryLabel"] as? String ?? "Open"
        let soundPath = config["soundPath"] as? String
        let soundName = prepareSoundFile(soundPath: soundPath)

        let weekdays = weekdaysFromMask(mask)
        guard !weekdays.isEmpty else { return }

        let burstId = UUID()
        let schedule = Alarm.Schedule.relative(
            Alarm.Schedule.Relative(
                time: Alarm.Schedule.Relative.Time(hour: hour, minute: minute),
                repeats: .weekly(weekdays)
            )
        )
        let alarmConfig = makeBurstConfig(
            burstId: burstId,
            originalId: originalUUID,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            schedule: schedule,
            soundName: soundName
        )
        do {
            _ = try await AlarmManager.shared.schedule(id: burstId, configuration: alarmConfig)
            defaults.set(originalId, forKey: "levio_burst_\(burstId.uuidString)")
            defaults.set(burstId.uuidString, forKey: "levio_relative_burst_\(originalId)")
            var burstIds = loadCascade(originalId: originalId)
            burstIds.append(burstId.uuidString)
            saveCascade(originalId: originalId, burstIds: burstIds)
        } catch {
            NSLog("[LevioAlarmKit] recreateRelativeBurst failed: %@", "\(error)")
        }
    }

    // MARK: - Reschedule For Next Week

    /// For recurrent alarms: cancels any remaining bursts and primes a fresh
    /// cascade for the next matching weekday **strictly after today**. No-op
    /// for one-shot alarms.
    private func rescheduleForNextWeek(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing id", details: nil))
            return
        }

        let defaults = UserDefaults.standard
        // One-shot cascades never reschedule; clear their saved config so
        // `levio_config_` / `levio_cascade_meta_` don't accumulate in
        // UserDefaults across one-shot alarms.
        if let data = defaults.data(forKey: "levio_config_\(originalId)"),
           let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           (config["isOneShot"] as? Bool) == true {
            cleanupConfigInternal(originalId: originalId)
            result(nil)
            return
        }

        guard let data = defaults.data(forKey: "levio_config_\(originalId)"),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mask = config["weekdayMask"] as? Int,
              let hour = config["hour"] as? Int,
              let minute = config["minute"] as? Int,
              let originalUUID = UUID(uuidString: originalId) else {
            result(nil) // missing config: nothing to do
            return
        }

        // Cancel any remaining bursts for this cascade (mission completion may
        // still have stragglers scheduled in the coming 6 minutes).
        cancelCascadeInternal(originalId: originalId)

        let title = config["title"] as? String ?? "Alarm"
        let sfSymbol = config["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = config["secondaryLabel"] as? String ?? "Open"
        let soundPath = config["soundPath"] as? String
        let soundName = prepareSoundFile(soundPath: soundPath)

        // "Strictly after today" — start searching from tomorrow midnight.
        let startOfTomorrow = Calendar.current.startOfDay(
            for: Date().addingTimeInterval(24 * 60 * 60)
        )
        let baseDate = nextMatchingDate(
            mask: mask, hour: hour, minute: minute,
            strictlyAfter: startOfTomorrow.addingTimeInterval(-1)
        )

        _ = await scheduleCascade(
            originalId: originalUUID,
            baseDate: baseDate,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            soundName: soundName,
            weeklyRecurrence: weekdaysFromMask(mask),
            recurrenceHour: hour,
            recurrenceMinute: minute
        )

        result(nil)
    }

    // MARK: - Prime Cascade If Needed

    /// For recurrent alarms whose `.relative(weekly)` safety-net burst is still
    /// alive but whose 23 `.fixed` bursts have all fired/expired. Schedules a
    /// fresh set of `.fixed` bursts, preserving the originalId and the existing
    /// `.relative` burst so weekly recurrence continuity is kept.
    ///
    /// BaseDate is adaptive: if the `.relative` burst is **currently alerting**
    /// (the ring just started and there's nothing behind it), bursts chain from
    /// **now + 15s** so the user still gets the 6-min cascade pressure. Otherwise
    /// they're scheduled for the **next matching weekday** at hour:minute.
    ///
    /// No-op if any `.fixed` burst is still alive, if no `.relative` burst is
    /// alive, or if the alarm is one-shot.
    private func primeCascadeIfNeeded(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing id", details: nil))
            return
        }

        // Drop overlapping invocations for the same cascade.
        Self.primingLock.lock()
        if Self.primingInProgress.contains(originalId) {
            Self.primingLock.unlock()
            result(nil)
            return
        }
        Self.primingInProgress.insert(originalId)
        Self.primingLock.unlock()
        defer {
            Self.primingLock.lock()
            Self.primingInProgress.remove(originalId)
            Self.primingLock.unlock()
        }

        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "levio_config_\(originalId)"),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (config["isOneShot"] as? Bool) == false,
              let mask = config["weekdayMask"] as? Int,
              let hour = config["hour"] as? Int,
              let minute = config["minute"] as? Int,
              let originalUUID = UUID(uuidString: originalId) else {
            result(nil)
            return
        }

        // Defensive guard: priming needs at least one weekday for
        // `nextMatchingDate` to land on a real day. An empty mask is already
        // prevented upstream (scheduleCascade only creates a `.relative` burst
        // when weeklyRecurrence is non-empty, so `hasLiveRelative` would be
        // false), but this keeps the contract explicit.
        guard mask != 0 else {
            result(nil)
            return
        }

        let allAlarms = (try? AlarmManager.shared.alarms) ?? []
        let alarmsById: [UUID: Alarm] = Dictionary(uniqueKeysWithValues: allAlarms.map { ($0.id, $0) })
        let cascadeList = loadCascade(originalId: originalId)
        let relativeBurstString = defaults.string(forKey: "levio_relative_burst_\(originalId)")

        var hasLiveRelative = false
        var relativeIsAlerting = false
        var hasLiveFixed = false
        for burstStr in cascadeList {
            guard let uuid = UUID(uuidString: burstStr), let alarm = alarmsById[uuid] else { continue }
            if burstStr == relativeBurstString {
                hasLiveRelative = true
                switch alarm.state { case .scheduled: break; @unknown default: relativeIsAlerting = true }
            } else {
                hasLiveFixed = true
            }
        }

        // Only prime when the safety-net is alive AND all fixed bursts are gone.
        guard hasLiveRelative, !hasLiveFixed else {
            result(nil)
            return
        }

        let title = config["title"] as? String ?? "Alarm"
        let sfSymbol = config["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = config["secondaryLabel"] as? String ?? "Open"
        let soundPath = config["soundPath"] as? String
        let soundName = prepareSoundFile(soundPath: soundPath)

        // `.relative` ringing now → chain immediately from now so the user keeps
        // getting hit every 15s. Otherwise schedule for the next matching weekday.
        let baseDate: Date
        if relativeIsAlerting {
            baseDate = Date()
        } else {
            baseDate = nextMatchingDate(
                mask: mask, hour: hour, minute: minute,
                strictlyAfter: Date().addingTimeInterval(-1)
            )
        }

        // Drop any dead burst references from the cascade list so the final
        // ordering stays [relative, new-fixed-1, … new-fixed-23].
        var alive: [String] = cascadeList.filter { burstStr in
            guard let uuid = UUID(uuidString: burstStr) else { return false }
            return alarmsById[uuid] != nil
        }

        var scheduledCount = 0
        // Schedule bursts 1..<kCascadeBurstCount as `.fixed`. Idx 0 slot stays
        // conceptually owned by the live `.relative` burst.
        for i in 1..<kCascadeBurstCount {
            let fire = baseDate.addingTimeInterval(Double(i) * kCascadeIntervalSeconds)
            let burstId = UUID()
            let alarmConfig = makeBurstConfig(
                burstId: burstId,
                originalId: originalUUID,
                title: title,
                sfSymbol: sfSymbol,
                secondaryLabel: secondaryLabel,
                schedule: .fixed(fire),
                soundName: soundName
            )
            do {
                _ = try await AlarmManager.shared.schedule(id: burstId, configuration: alarmConfig)
                defaults.set(originalId, forKey: "levio_burst_\(burstId.uuidString)")
                alive.append(burstId.uuidString)
                scheduledCount += 1
            } catch {
                NSLog("[LevioAlarmKit] primeCascadeIfNeeded burst %d failed: %@", i, "\(error)")
            }
        }

        saveCascade(originalId: originalId, burstIds: alive)
        saveCascadeMeta(originalId: originalId, baseDate: baseDate)

        NSLog("[LevioAlarmKit] primed %d .fixed bursts for cascade %@ (fromNow=%@)",
              scheduledCount, originalId, relativeIsAlerting ? "true" : "false")
        result(nil)
    }

    // MARK: - Get Next Burst

    /// Returns `{burstId, timestampMs}` for the soonest future burst in this
    /// cascade. Also returns a currently-alerting burst if any (with its
    /// timestamp, which will be in the past). Nil if the cascade is empty.
    private func getNextBurst(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["id"] as? String else {
            result(nil)
            return
        }

        let burstIds = loadCascade(originalId: originalId)
        guard !burstIds.isEmpty,
              let alarms = try? AlarmManager.shared.alarms else {
            result(nil)
            return
        }

        let burstSet = Set(burstIds.compactMap { UUID(uuidString: $0) })
        // Map by id → alarm.
        let byId: [UUID: Alarm] = Dictionary(uniqueKeysWithValues: alarms.compactMap {
            burstSet.contains($0.id) ? ($0.id, $0) : nil
        })

        // Prefer an alerting burst (fire it first so suppression can cancel it).
        let alerting = byId.values.first { alarm in
            switch alarm.state { case .scheduled: return false; @unknown default: return true }
        }
        if let a = alerting {
            result([
                "burstId": a.id.uuidString,
                "timestampMs": Date().timeIntervalSince1970 * 1000,
                "isAlerting": true,
            ])
            return
        }

        // Otherwise pick the earliest scheduled one. AlarmKit doesn't expose
        // the fire time directly via the public API on iOS 26, so we look
        // it up from our saved cascade metadata (stored as ordered UUIDs at
        // known 15s offsets from baseDate).
        guard let data = UserDefaults.standard.data(forKey: "levio_cascade_meta_\(originalId)"),
              let meta = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let baseMs = meta["baseTimestampMs"] as? Double else {
            // Fallback: return the first burst id we still have scheduled.
            if let first = byId.keys.first {
                result([
                    "burstId": first.uuidString,
                    "timestampMs": Date().timeIntervalSince1970 * 1000,
                    "isAlerting": false,
                ])
                return
            }
            result(nil)
            return
        }

        // Walk cascade order, find first burst still scheduled whose offset
        // places it in the future.
        let now = Date().timeIntervalSince1970 * 1000
        for (idx, burstIdString) in burstIds.enumerated() {
            let fireMs = baseMs + Double(idx) * kCascadeIntervalSeconds * 1000
            if fireMs <= now { continue }
            if let uuid = UUID(uuidString: burstIdString), byId[uuid] != nil {
                result([
                    "burstId": burstIdString,
                    "timestampMs": fireMs,
                    "isAlerting": false,
                ])
                return
            }
        }
        result(nil)
    }

    // MARK: - Get Alarm IDs

    /// Returns the `originalId`s of every cascade that still has at least one
    /// live burst in AlarmKit (including the `.relative` safety-net burst).
    /// Cascades with only the `.relative` burst left are kept alive from
    /// Dart's point of view — `primeCascadeIfNeeded` will re-fill the
    /// `.fixed` bursts without touching the `.relative` or the originalId.
    private func getAlarmIds(result: @escaping FlutterResult) {
        let defaults = UserDefaults.standard
        let liveBurstIds: Set<UUID> = Set((try? AlarmManager.shared.alarms)?.map { $0.id } ?? [])
        let prefix = "levio_cascade_"
        var ids: [String] = []
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            if key.hasPrefix("levio_cascade_meta_") { continue }
            let originalId = String(key.dropFirst(prefix.count))
            let hasLiveBurst = loadCascade(originalId: originalId).contains { burstStr in
                guard let uuid = UUID(uuidString: burstStr) else { return false }
                return liveBurstIds.contains(uuid)
            }
            if hasLiveBurst {
                ids.append(originalId)
            }
        }
        result(ids)
    }

    // MARK: - Get Alarms (full info)

    private func getAlarms(result: @escaping FlutterResult) {
        let defaults = UserDefaults.standard
        let prefix = "levio_config_"
        var list: [[String: Any]] = []

        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            let originalId = String(key.dropFirst(prefix.count))
            guard let data = defaults.data(forKey: key),
                  let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            var info: [String: Any] = ["id": originalId]
            info["title"] = config["title"] as? String ?? ""
            info["sfSymbol"] = config["sfSymbol"] as? String ?? ""
            info["secondaryLabel"] = config["secondaryLabel"] as? String ?? ""
            info["isOneShot"] = config["isOneShot"] as? Bool ?? false
            if let ts = config["timestampMs"] as? Double { info["timestampMs"] = ts }
            if let mask = config["weekdayMask"] as? Int { info["weekdayMask"] = mask }
            if let hour = config["hour"] as? Int { info["hour"] = hour }
            if let minute = config["minute"] as? Int { info["minute"] = minute }

            // Derive state from the cascade: alerting if any burst is alerting,
            // scheduled if any bursts remain, else gone (skip).
            let cascade = loadCascade(originalId: originalId)
            if cascade.isEmpty { continue }

            let alarms = (try? AlarmManager.shared.alarms) ?? []
            let burstSet = Set(cascade.compactMap { UUID(uuidString: $0) })
            let cascadeAlarms = alarms.filter { burstSet.contains($0.id) }
            // Stale cascade — all bursts have already fired or been removed.
            if cascadeAlarms.isEmpty { continue }
            let anyAlerting = cascadeAlarms.contains { alarm in
                switch alarm.state { case .scheduled: return false; @unknown default: return true }
            }
            info["state"] = anyAlerting ? "alerting" : "scheduled"
            list.append(info)
        }
        result(list)
    }

    // MARK: - Get Ringing Alarm (as originalId)

    private func getRingingId(result: @escaping FlutterResult) {
        guard let alarms = try? AlarmManager.shared.alarms else {
            result(nil)
            return
        }
        let ringing = alarms.first { alarm in
            switch alarm.state { case .scheduled: return false; @unknown default: return true }
        }
        guard let burstId = ringing?.id.uuidString else {
            result(nil)
            return
        }
        // Map to originalId if possible; fall back to burstId.
        let originalId = UserDefaults.standard.string(
            forKey: "levio_burst_\(burstId)"
        ) ?? burstId
        result(originalId)
    }

    // MARK: - Cleanup Config

    private func cleanupConfig(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let idString = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid alarm ID", details: nil))
            return
        }
        cleanupConfigInternal(originalId: idString)
        result(nil)
    }

    private func cleanupConfigInternal(originalId: String) {
        let defaults = UserDefaults.standard
        // Cancel any remaining bursts first.
        cancelCascadeInternal(originalId: originalId)
        defaults.removeObject(forKey: "levio_config_\(originalId)")
        defaults.removeObject(forKey: "levio_cascade_meta_\(originalId)")
    }

    // MARK: - Cascade helpers

    /// Schedules `kCascadeBurstCount` one-shot alarms for the cascade starting
    /// at `baseDate`. Stores the ordered burst UUIDs under
    /// `levio_cascade_<originalId>` and the base timestamp under
    /// `levio_cascade_meta_<originalId>`. Also writes `levio_burst_<burstId>`
    /// reverse lookups.
    ///
    /// When `weeklyRecurrence` is non-empty, burst 0 is scheduled as
    /// `.relative(weekly(…))` at `recurrenceHour:recurrenceMinute` to act as a
    /// safety net that keeps firing every matching weekday even if the app
    /// never opens to re-prime the cascade. Its UUID is stored under
    /// `levio_relative_burst_<originalId>` so suppression logic can detect it.
    @discardableResult
    private func scheduleCascade(
        originalId: UUID,
        baseDate: Date,
        title: String,
        sfSymbol: String,
        secondaryLabel: String,
        soundName: String?,
        weeklyRecurrence: [Locale.Weekday] = [],
        recurrenceHour: Int = 0,
        recurrenceMinute: Int = 0
    ) async -> Bool {
        let defaults = UserDefaults.standard
        var burstIds: [String] = []
        var relativeBurstIdString: String?

        for i in 0..<kCascadeBurstCount {
            let fire = baseDate.addingTimeInterval(Double(i) * kCascadeIntervalSeconds)
            let burstId = UUID()
            let schedule: Alarm.Schedule
            let isRelative = (i == 0 && !weeklyRecurrence.isEmpty)
            if isRelative {
                schedule = .relative(
                    Alarm.Schedule.Relative(
                        time: Alarm.Schedule.Relative.Time(hour: recurrenceHour, minute: recurrenceMinute),
                        repeats: .weekly(weeklyRecurrence)
                    )
                )
            } else {
                schedule = .fixed(fire)
            }
            let config = makeBurstConfig(
                burstId: burstId,
                originalId: originalId,
                title: title,
                sfSymbol: sfSymbol,
                secondaryLabel: secondaryLabel,
                schedule: schedule,
                soundName: soundName
            )
            do {
                _ = try await AlarmManager.shared.schedule(id: burstId, configuration: config)
                defaults.set(originalId.uuidString, forKey: "levio_burst_\(burstId.uuidString)")
                burstIds.append(burstId.uuidString)
                if isRelative { relativeBurstIdString = burstId.uuidString }
            } catch {
                NSLog("[LevioAlarmKit] cascade burst %d/%d failed: %@", i + 1, kCascadeBurstCount, "\(error)")
                // Continue scheduling the rest — we want as much coverage as we can get.
            }
        }

        saveCascade(originalId: originalId.uuidString, burstIds: burstIds)
        saveCascadeMeta(originalId: originalId.uuidString, baseDate: baseDate)
        if let rel = relativeBurstIdString {
            defaults.set(rel, forKey: "levio_relative_burst_\(originalId.uuidString)")
        } else {
            defaults.removeObject(forKey: "levio_relative_burst_\(originalId.uuidString)")
        }
        return !burstIds.isEmpty
    }

    /// Maps Levio's weekday bitmask (bit 0 = Monday … bit 6 = Sunday) to
    /// AlarmKit's `Locale.Weekday` enum used by `.relative(weekly(…))`.
    private func weekdaysFromMask(_ mask: Int) -> [Locale.Weekday] {
        let bitToWeekday: [Locale.Weekday] = [
            .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
        ]
        var result: [Locale.Weekday] = []
        for bit in 0..<7 where (mask & (1 << bit)) != 0 {
            result.append(bitToWeekday[bit])
        }
        return result
    }

    private func makeBurstConfig(
        burstId: UUID,
        originalId: UUID,
        title: String,
        sfSymbol: String,
        secondaryLabel: String,
        schedule: Alarm.Schedule,
        soundName: String?
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
        let sound: AlertConfiguration.AlertSound = {
            if let name = soundName { return .named(name) }
            return .default
        }()

        // Both stop and secondary now just open the app — no native stop-and-reschedule.
        return AlarmManager.AlarmConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: OpenAppIntent(alarmID: burstId.uuidString),
            secondaryIntent: OpenAlarmAppIntent(alarmID: burstId.uuidString),
            sound: sound
        )
    }

    private func saveConfig(
        originalId: UUID,
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
        if let soundPath = soundPath { config["soundPath"] = soundPath }
        if let data = try? JSONSerialization.data(withJSONObject: config) {
            UserDefaults.standard.set(data, forKey: "levio_config_\(originalId.uuidString)")
        }
    }

    private func saveCascade(originalId: String, burstIds: [String]) {
        let defaults = UserDefaults.standard
        if burstIds.isEmpty {
            defaults.removeObject(forKey: "levio_cascade_\(originalId)")
            return
        }
        if let data = try? JSONSerialization.data(withJSONObject: burstIds) {
            defaults.set(data, forKey: "levio_cascade_\(originalId)")
        }
    }

    private func loadCascade(originalId: String) -> [String] {
        guard let data = UserDefaults.standard.data(forKey: "levio_cascade_\(originalId)"),
              let ids = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return []
        }
        return ids
    }

    private func saveCascadeMeta(originalId: String, baseDate: Date) {
        let meta: [String: Any] = [
            "baseTimestampMs": baseDate.timeIntervalSince1970 * 1000,
        ]
        if let data = try? JSONSerialization.data(withJSONObject: meta) {
            UserDefaults.standard.set(data, forKey: "levio_cascade_meta_\(originalId)")
        }
    }

    /// Returns the next Date matching any weekday in `mask` at hour:minute that
    /// is strictly after `reference`. `mask` uses bit 0 = Monday … bit 6 = Sunday.
    private func nextMatchingDate(mask: Int, hour: Int, minute: Int, strictlyAfter reference: Date) -> Date {
        let cal = Calendar(identifier: .gregorian)
        for dayOffset in 0...8 {
            guard let candidateDay = cal.date(byAdding: .day, value: dayOffset, to: reference) else { continue }
            let weekday = cal.component(.weekday, from: candidateDay) // 1 = Sunday … 7 = Saturday
            let maskBit = (weekday == 1) ? 6 : (weekday - 2) // 0 = Monday … 6 = Sunday
            if (mask & (1 << maskBit)) == 0 { continue }
            guard let fire = cal.date(
                bySettingHour: hour, minute: minute, second: 0, of: candidateDay
            ), fire > reference else { continue }
            return fire
        }
        // Shouldn't happen — fall back to one day from reference.
        return reference.addingTimeInterval(24 * 60 * 60)
    }

    // MARK: - Sound file prep (unchanged)

    private func prepareSoundFile(soundPath: String?) -> String? {
        guard let soundPath = soundPath else { return nil }

        let fileManager = FileManager.default
        let soundsDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds")
        try? fileManager.createDirectory(at: soundsDir, withIntermediateDirectories: true)

        let sourceURL: URL?
        if soundPath.hasPrefix("assets/") {
            let key = FlutterDartProject.lookupKey(forAsset: soundPath)
            if let bundlePath = Bundle.main.path(forResource: key, ofType: nil) {
                sourceURL = URL(fileURLWithPath: bundlePath)
            } else {
                NSLog("[LevioAlarmKit] prepareSoundFile: Flutter asset not found for key '%@'", key)
                return nil
            }
        } else {
            sourceURL = URL(fileURLWithPath: soundPath)
        }

        guard let source = sourceURL else { return nil }

        let filename = source.lastPathComponent
        let destination = soundsDir.appendingPathComponent(filename)

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
}
