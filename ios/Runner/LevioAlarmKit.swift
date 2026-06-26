import Flutter
import AlarmKit
import ActivityKit
import AppIntents
import SwiftUI

// MARK: - Metadata

@available(iOS 26.0, *)
struct LevioAlarmMetadata: AlarmMetadata {}

// MARK: - Cascade constants

/// Each Levio alarm is 1 master + 40 .fixed bursts with escalating spacing
/// (10s for bursts 1–10, 20s for 11–20, 30s for 21–30, then a supplementary
/// 1m for 31–40 = ~20m of coverage).
/// The master fires on the scheduled hour:minute (weekly for recurrent,
/// one-shot fixed for one-time) and its Stop button re-adds a +5s nudge burst
/// so the cascade only intensifies when the user actively hits Stop.
private let kBurstCount = 40
private let kBurstIntervalSeconds: TimeInterval = 10
/// Delay of the extra nudge burst scheduled when the user taps Stop on the
/// master's lock-screen button.
private let kMasterStopNudgeDelaySeconds: TimeInterval = 3

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

                // New alerting alarms → ring event. Resolve originalId by
                // checking both the burst reverse lookup and the master
                // reverse lookup (masters ring too).
                for firedId in currentAlertingIds.subtracting(previousAlertingIds) {
                    let firedIdString = firedId.uuidString
                    let defaults = UserDefaults.standard
                    let originalId = defaults.string(forKey: "levio_burst_\(firedIdString)")
                        ?? defaults.string(forKey: "levio_master_owner_\(firedIdString)")
                        ?? firedIdString
                    let isMaster = defaults.string(forKey: "levio_master_owner_\(firedIdString)") != nil
                    emit([
                        "event": "ring",
                        "id": firedIdString,
                        "originalId": originalId,
                        "isMaster": isMaster,
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

    /// Guards `primeCascadeIfNeeded` and `scheduleNudgeBurstForMasterStop`
    /// against overlapping invocations for the same originalId. Without this,
    /// parallel priming passes could each observe "queue is short" and each
    /// top up, doubling the cascade.
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
        case "getAuthorizationStatus":
            getAuthorizationStatus(result: result)
        case "openAppSettings":
            openAppSettings(result: result)
        case "scheduleOneShot":
            Task { await scheduleOneShotCascade(call: call, result: result) }
        case "scheduleRepeating":
            Task { await scheduleRepeatingCascade(call: call, result: result) }
        case "cancel":
            Task { await cancelCascade(call: call, result: result) }
        case "cancelBurst":
            Task { await cancelBurst(call: call, result: result) }
        case "cancelBurstsKeepMaster":
            Task { await cancelBurstsKeepMaster(call: call, result: result) }
        case "dismissMasterRingIfAlerting":
            Task { await dismissMasterRingIfAlerting(call: call, result: result) }
        case "rescheduleForNextFire":
            Task { await rescheduleForNextFire(call: call, result: result) }
        case "primeCascadeIfNeeded":
            Task { await primeCascadeIfNeeded(call: call, result: result) }
        case "getNextBurst":
            getNextBurst(call: call, result: result)
        case "getBurstsInWindow":
            getBurstsInWindow(call: call, result: result)
        case "getAlarmIds":
            getAlarmIds(result: result)
        case "getAlarms":
            getAlarms(result: result)
        case "getRawAlarms":
            getRawAlarms(result: result)
        case "getRingingId":
            getRingingId(result: result)
        case "getRingingAlarms":
            getRingingAlarms(result: result)
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

    /// Returns the current authorization state without prompting:
    /// "authorized" / "denied" / "notDetermined".
    private func getAuthorizationStatus(result: @escaping FlutterResult) {
        switch AlarmManager.shared.authorizationState {
        case .authorized: result("authorized")
        case .denied: result("denied")
        case .notDetermined: result("notDetermined")
        @unknown default: result("notDetermined")
        }
    }

    /// Opens the system Settings page for this app (used when authorization was
    /// previously denied and the system prompt won't reappear).
    private func openAppSettings(result: @escaping FlutterResult) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            result(false)
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url) { success in result(success) }
        }
    }

    // MARK: - Schedule One-Shot Cascade

    /// Schedules a one-shot master (.fixed) + 20 .fixed bursts at 20s spacing.
    /// All share the same logical `originalId`, which is returned.
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
        // Gentle alarms pass 0 → master alert only, no burst cascade.
        let burstCount = args["burstCount"] as? Int ?? kBurstCount
        let originalId = UUID()
        let masterDate = Date(timeIntervalSince1970: timestampMs / 1000)
        let soundName = prepareSoundFile(soundPath: soundPath)

        saveConfig(
            originalId: originalId,
            title: title, sfSymbol: sfSymbol, secondaryLabel: secondaryLabel,
            isOneShot: true,
            timestampMs: timestampMs,
            soundPath: soundPath,
            burstCount: burstCount
        )

        let scheduled = await scheduleMasterAndBursts(
            originalId: originalId,
            masterDate: masterDate,
            isOneShot: true,
            weeklyRecurrence: [],
            recurrenceHour: 0,
            recurrenceMinute: 0,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            soundName: soundName,
            burstCount: burstCount
        )

        if scheduled {
            result(originalId.uuidString)
        } else {
            cleanupConfigInternal(originalId: originalId.uuidString)
            result(FlutterError(code: "SCHEDULE_ERROR", message: "Failed to schedule cascade", details: nil))
        }
    }

    // MARK: - Schedule Repeating Cascade

    /// Schedules a recurrent master (.relative weekly) + 20 .fixed bursts at
    /// 20s spacing from the next matching weekday at hour:minute.
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
        // Gentle alarms pass 0 → master alert only, no burst cascade.
        let burstCount = args["burstCount"] as? Int ?? kBurstCount
        let originalId = UUID()
        let soundName = prepareSoundFile(soundPath: soundPath)

        let masterDate = nextMatchingDate(
            mask: mask, hour: hour, minute: minute,
            strictlyAfter: Date().addingTimeInterval(-1)
        )

        saveConfig(
            originalId: originalId,
            title: title, sfSymbol: sfSymbol, secondaryLabel: secondaryLabel,
            isOneShot: false,
            weekdayMask: mask, hour: hour, minute: minute,
            soundPath: soundPath,
            burstCount: burstCount
        )

        let scheduled = await scheduleMasterAndBursts(
            originalId: originalId,
            masterDate: masterDate,
            isOneShot: false,
            weeklyRecurrence: weekdaysFromMask(mask),
            recurrenceHour: hour,
            recurrenceMinute: minute,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            soundName: soundName,
            burstCount: burstCount
        )

        if scheduled {
            result(originalId.uuidString)
        } else {
            cleanupConfigInternal(originalId: originalId.uuidString)
            result(FlutterError(code: "SCHEDULE_ERROR", message: "Failed to schedule cascade", details: nil))
        }
    }

    // MARK: - Cancel Cascade (full)

    /// Full cancel: master + all 20 bursts + storage. Use on alarm delete or
    /// disable. For mission completion, use `cancelBurstsKeepMaster` so the
    /// weekly master stays alive for next week.
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

        // Cancel all bursts.
        for entry in loadCascade(originalId: originalId) {
            if let uuid = UUID(uuidString: entry.id) {
                try? AlarmManager.shared.cancel(id: uuid)
            }
            defaults.removeObject(forKey: "levio_burst_\(entry.id)")
        }
        defaults.removeObject(forKey: "levio_cascade_\(originalId)")

        // Cancel the master.
        if let masterIdString = defaults.string(forKey: "levio_master_\(originalId)"),
           let masterUUID = UUID(uuidString: masterIdString) {
            try? AlarmManager.shared.cancel(id: masterUUID)
            defaults.removeObject(forKey: "levio_master_owner_\(masterIdString)")
        }
        defaults.removeObject(forKey: "levio_master_\(originalId)")
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

        var cascade = loadCascade(originalId: originalId)
        cascade.removeAll { $0.id == burstIdString }
        saveCascade(originalId: originalId, cascade: cascade)
        UserDefaults.standard.removeObject(forKey: "levio_burst_\(burstIdString)")

        result(nil)
    }

    // MARK: - Cancel Bursts Keep Master

    /// Mission success path: silences a currently-alerting master (via
    /// `AlarmManager.stop` — preserves weekly schedule for `.relative`, deletes
    /// for `.fixed` one-shot), cancels every remaining burst, and leaves the
    /// master alive so next week's fire is still armed for recurrent alarms.
    private func cancelBurstsKeepMaster(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing id", details: nil))
            return
        }

        let defaults = UserDefaults.standard

        // Silence master if alerting.
        if let masterIdString = defaults.string(forKey: "levio_master_\(originalId)"),
           let masterUUID = UUID(uuidString: masterIdString),
           masterIsAlerting(masterUUID: masterUUID) {
            try? AlarmManager.shared.stop(id: masterUUID)
        }

        // Cancel all bursts.
        for entry in loadCascade(originalId: originalId) {
            if let uuid = UUID(uuidString: entry.id) {
                try? AlarmManager.shared.cancel(id: uuid)
            }
            defaults.removeObject(forKey: "levio_burst_\(entry.id)")
        }
        defaults.removeObject(forKey: "levio_cascade_\(originalId)")

        result(nil)
    }

    // MARK: - Dismiss Master Ring (if alerting)

    /// Silences only the master if it's currently ringing. Used on mission
    /// mount to immediately stop the master's ring without cancelling the
    /// weekly schedule or the 20 queued bursts.
    private func dismissMasterRingIfAlerting(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing id", details: nil))
            return
        }

        if let masterIdString = UserDefaults.standard.string(forKey: "levio_master_\(originalId)"),
           let masterUUID = UUID(uuidString: masterIdString),
           masterIsAlerting(masterUUID: masterUUID) {
            try? AlarmManager.shared.stop(id: masterUUID)
        }
        result(nil)
    }

    private func masterIsAlerting(masterUUID: UUID) -> Bool {
        guard let alarms = try? AlarmManager.shared.alarms,
              let alarm = alarms.first(where: { $0.id == masterUUID }) else {
            return false
        }
        switch alarm.state { case .scheduled: return false; @unknown default: return true }
    }

    // MARK: - Reschedule For Next Fire

    /// Mission success: schedules a fresh set of 20 bursts for the next
    /// matching weekday strictly after today (for recurrent). No-op for one-
    /// shot, whose master self-cancels after firing — we just scrub its
    /// storage so it doesn't linger in UserDefaults.
    ///
    /// Caller should have already run `cancelBurstsKeepMaster` to silence
    /// the current ring and cancel leftover bursts.
    private func rescheduleForNextFire(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing id", details: nil))
            return
        }

        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "levio_config_\(originalId)"),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            result(nil)
            return
        }

        // One-shot: purge config. Master was already deleted by stop().
        if (config["isOneShot"] as? Bool) == true {
            cleanupConfigInternal(originalId: originalId)
            result(nil)
            return
        }

        guard let mask = config["weekdayMask"] as? Int,
              let hour = config["hour"] as? Int,
              let minute = config["minute"] as? Int,
              let originalUUID = UUID(uuidString: originalId),
              mask != 0 else {
            result(nil)
            return
        }

        let title = config["title"] as? String ?? "Alarm"
        let sfSymbol = config["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = config["secondaryLabel"] as? String ?? "Open"
        let soundPath = config["soundPath"] as? String
        let soundName = prepareSoundFile(soundPath: soundPath)
        // Honor the per-cascade burst count (gentle alarms store 0).
        let burstCount = config["burstCount"] as? Int ?? kBurstCount

        // "Strictly after today" so we never double-fire on the same day.
        let startOfTomorrow = Calendar.current.startOfDay(
            for: Date().addingTimeInterval(24 * 60 * 60)
        )
        let masterDate = nextMatchingDate(
            mask: mask, hour: hour, minute: minute,
            strictlyAfter: startOfTomorrow.addingTimeInterval(-1)
        )

        await scheduleBurstsOnly(
            originalId: originalUUID,
            masterDate: masterDate,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            soundName: soundName,
            burstCount: burstCount,
            replaceCascade: true
        )

        result(nil)
    }

    // MARK: - Prime Cascade If Needed

    /// Tops up the burst queue to `kBurstCount`. Invoked on sync, on app open
    /// over an alerting cascade, and on ring. No-op if the queue is already
    /// full. Base date is adaptive:
    ///   - master alerting OR master scheduled within the cascade window →
    ///     chain bursts from now+20s (the user is in the cascade window now)
    ///   - otherwise → chain bursts from the next matching weekday (recurrent)
    ///     or the master's scheduled fire time (one-shot fallback)
    ///
    /// Lock-guarded against overlapping invocations for the same originalId.
    private func primeCascadeIfNeeded(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["id"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing id", details: nil))
            return
        }

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
              let originalUUID = UUID(uuidString: originalId) else {
            result(nil)
            return
        }

        // Only prime if the master is still alive (otherwise the cascade is
        // fully dead — let the alarm delete/cleanup path handle it).
        guard let masterIdString = defaults.string(forKey: "levio_master_\(originalId)"),
              let masterUUID = UUID(uuidString: masterIdString),
              let alarms = try? AlarmManager.shared.alarms else {
            result(nil)
            return
        }
        let masterAlarm = alarms.first(where: { $0.id == masterUUID })
        guard masterAlarm != nil else {
            result(nil)
            return
        }
        let masterAlerting: Bool = {
            guard let m = masterAlarm else { return false }
            switch m.state { case .scheduled: return false; @unknown default: return true }
        }()

        // TZ-drift repair. `.relative(weekly)` masters adapt to local tz
        // automatically (per Apple docs); `.fixed` does not. So on tz shift:
        //   - recurrent: master is fine, wipe the .fixed bursts and let
        //     priming below regenerate a coherent set from the master's new
        //     local fire time.
        //   - one-shot: master is .fixed and anchored to an absolute moment
        //     that drifts away from the user's intended wall-clock time.
        //     Reschedule the master at (intendedY/M/D + hh:mm) interpreted in
        //     the new tz (advancing by a day if that moment is already past),
        //     then wipe bursts so priming regenerates them at master+20s,+40s…
        var cascade = loadCascade(originalId: originalId)
        var workingConfig = config
        var masterDateForBase: Date? = nil
        let isOneShot = (workingConfig["isOneShot"] as? Bool) ?? false
        let currentTzOffset = TimeZone.current.secondsFromGMT()
        let savedTzOffset = workingConfig["tzOffsetSeconds"] as? Int
        let drifted = savedTzOffset != nil && savedTzOffset != currentTzOffset

        if drifted {
            NSLog("[LevioAlarmKit] tz drift for %@ (saved=%d current=%d) — repairing",
                  originalId, savedTzOffset ?? 0, currentTzOffset)
            // Wipe bursts in every case.
            for entry in cascade {
                if let uuid = UUID(uuidString: entry.id) {
                    try? AlarmManager.shared.cancel(id: uuid)
                }
                defaults.removeObject(forKey: "levio_burst_\(entry.id)")
            }
            saveCascade(originalId: originalId, cascade: [])
            cascade = []

            if isOneShot,
               let y = workingConfig["intendedYear"] as? Int,
               let m = workingConfig["intendedMonth"] as? Int,
               let d = workingConfig["intendedDay"] as? Int,
               let h = workingConfig["intendedHour"] as? Int,
               let mi = workingConfig["intendedMinute"] as? Int {
                var comps = DateComponents()
                comps.year = y; comps.month = m; comps.day = d
                comps.hour = h; comps.minute = mi; comps.second = 0
                var newDate = Calendar.current.date(from: comps) ?? Date().addingTimeInterval(60)
                while newDate <= Date() {
                    guard let next = Calendar.current.date(byAdding: .day, value: 1, to: newDate) else { break }
                    newDate = next
                }

                // Cancel old master and its reverse-lookup mapping.
                try? AlarmManager.shared.cancel(id: masterUUID)
                defaults.removeObject(forKey: "levio_master_owner_\(masterUUID.uuidString)")

                // Reschedule new master.
                let newMasterId = UUID()
                let title = workingConfig["title"] as? String ?? "Alarm"
                let sfSymbol = workingConfig["sfSymbol"] as? String ?? "alarm"
                let secondaryLabel = workingConfig["secondaryLabel"] as? String ?? "Open"
                let soundName = prepareSoundFile(soundPath: workingConfig["soundPath"] as? String)
                let masterCfg = makeBurstConfig(
                    burstId: newMasterId,
                    originalId: originalUUID,
                    title: title,
                    sfSymbol: sfSymbol,
                    secondaryLabel: secondaryLabel,
                    schedule: .fixed(newDate),
                    soundName: soundName,
                    stopReschedules: true
                )
                do {
                    _ = try await AlarmManager.shared.schedule(id: newMasterId, configuration: masterCfg)
                    defaults.set(newMasterId.uuidString, forKey: "levio_master_\(originalId)")
                    defaults.set(originalId, forKey: "levio_master_owner_\(newMasterId.uuidString)")
                    masterDateForBase = newDate
                    workingConfig["timestampMs"] = newDate.timeIntervalSince1970 * 1000
                } catch {
                    NSLog("[LevioAlarmKit] tz-repair one-shot master reschedule failed: %@", "\(error)")
                }
            }
        }
        if savedTzOffset != currentTzOffset {
            workingConfig["tzOffsetSeconds"] = currentTzOffset
            if let data = try? JSONSerialization.data(withJSONObject: workingConfig) {
                defaults.set(data, forKey: "levio_config_\(originalId)")
            }
        }
        let activeConfig = workingConfig

        // Count live bursts (cascade was already wiped if we repaired tz).
        let refreshedAlarms = (try? AlarmManager.shared.alarms) ?? alarms
        let liveIds = Set(refreshedAlarms.map { $0.id })
        let liveBursts = cascade.filter { entry in
            guard let uuid = UUID(uuidString: entry.id) else { return false }
            return liveIds.contains(uuid)
        }
        // Honor the per-cascade burst count — gentle alarms store 0, so this
        // yields needed <= 0 and priming never refills a cascade for them.
        let targetBurstCount = activeConfig["burstCount"] as? Int ?? kBurstCount
        let needed = targetBurstCount - liveBursts.count
        guard needed > 0 else {
            result(nil)
            return
        }

        let title = activeConfig["title"] as? String ?? "Alarm"
        let sfSymbol = activeConfig["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = activeConfig["secondaryLabel"] as? String ?? "Open"
        let soundPath = activeConfig["soundPath"] as? String
        let soundName = prepareSoundFile(soundPath: soundPath)

        // After a one-shot tz repair, the freshly-scheduled master is not
        // alerting. Otherwise keep the pre-repair alerting state.
        let effectiveMasterAlerting = (masterDateForBase != nil) ? false : masterAlerting

        // Determine where to chain new bursts from. If the master is alerting
        // we're in the cascade window now — chain from now. Otherwise chain
        // from the master's next fire time.
        let baseDate: Date
        if effectiveMasterAlerting {
            baseDate = Date()
        } else if let rescheduled = masterDateForBase {
            baseDate = rescheduled
        } else if isOneShot {
            if let ts = activeConfig["timestampMs"] as? Double, ts > 0 {
                baseDate = Date(timeIntervalSince1970: ts / 1000)
            } else {
                baseDate = Date()
            }
        } else if let mask = activeConfig["weekdayMask"] as? Int,
                  let hour = activeConfig["hour"] as? Int,
                  let minute = activeConfig["minute"] as? Int,
                  mask != 0 {
            baseDate = nextMatchingDate(
                mask: mask, hour: hour, minute: minute,
                strictlyAfter: Date().addingTimeInterval(-1)
            )
        } else {
            result(nil)
            return
        }

        // Chain new bursts strictly after the last live burst (to avoid
        // double-firing at the same second) and always in the future.
        let nowMs = Date().timeIntervalSince1970 * 1000
        let lastLiveTs = liveBursts.map { $0.ts }.max()
        let baseMs = baseDate.timeIntervalSince1970 * 1000
        var prevFireMs = max(lastLiveTs ?? baseMs, nowMs)
        var alive = liveBursts
        var scheduledCount = 0
        for i in 0..<needed {
            let cascadeIndex = liveBursts.count + i + 1
            prevFireMs += intervalForBurst(at: cascadeIndex) * 1000
            let fire = Date(timeIntervalSince1970: prevFireMs / 1000)
            let burstId = UUID()
            let cfg = makeBurstConfig(
                burstId: burstId,
                originalId: originalUUID,
                title: title,
                sfSymbol: sfSymbol,
                secondaryLabel: secondaryLabel,
                schedule: .fixed(fire),
                soundName: soundName,
                stopReschedules: true
            )
            do {
                _ = try await AlarmManager.shared.schedule(id: burstId, configuration: cfg)
                defaults.set(originalId, forKey: "levio_burst_\(burstId.uuidString)")
                alive.append(CascadeEntry(id: burstId.uuidString, ts: fire.timeIntervalSince1970 * 1000))
                scheduledCount += 1
            } catch {
                NSLog("[LevioAlarmKit] primeCascadeIfNeeded burst %d/%d failed: %@", i + 1, needed, "\(error)")
            }
        }

        saveCascade(originalId: originalId, cascade: alive)
        NSLog("[LevioAlarmKit] primed %d bursts for %@ (masterAlerting=%@)",
              scheduledCount, originalId, masterAlerting ? "true" : "false")
        result(nil)
    }

    // MARK: - Get Next Burst / Get Bursts In Window

    /// Returns `{burstId, timestampMs, isAlerting}` for the soonest burst.
    /// Alerting bursts win over future ones. Returns nil if no bursts remain.
    /// Never returns the master — suppression should never cancel it.
    private func getNextBurst(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["id"] as? String else {
            result(nil)
            return
        }

        let cascade = loadCascade(originalId: originalId)
        guard !cascade.isEmpty,
              let alarms = try? AlarmManager.shared.alarms else {
            result(nil)
            return
        }

        let alarmsById: [UUID: Alarm] = Dictionary(uniqueKeysWithValues: alarms.map { ($0.id, $0) })
        let now = Date().timeIntervalSince1970 * 1000

        // Alerting burst wins.
        if let alerting = cascade.first(where: { entry in
            guard let uuid = UUID(uuidString: entry.id), let a = alarmsById[uuid] else { return false }
            switch a.state { case .scheduled: return false; @unknown default: return true }
        }) {
            result([
                "burstId": alerting.id,
                "timestampMs": now,
                "isAlerting": true,
            ])
            return
        }

        // Earliest scheduled future burst.
        let future = cascade
            .filter { entry in
                guard let uuid = UUID(uuidString: entry.id), alarmsById[uuid] != nil else { return false }
                return entry.ts > now
            }
            .min(by: { $0.ts < $1.ts })
        guard let f = future else {
            result(nil)
            return
        }
        result([
            "burstId": f.id,
            "timestampMs": f.ts,
            "isAlerting": false,
        ])
    }

    /// Returns every burst id scheduled to fire within `windowMs` (including
    /// currently-alerting bursts). Used by the suppression timer to cancel
    /// all bursts in a 10s window in one pass rather than just the next one.
    private func getBurstsInWindow(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let originalId = args["id"] as? String else {
            result([])
            return
        }
        let windowMs = (args["windowMs"] as? Int) ?? 10000

        let cascade = loadCascade(originalId: originalId)
        guard !cascade.isEmpty,
              let alarms = try? AlarmManager.shared.alarms else {
            result([])
            return
        }
        let alarmsById: [UUID: Alarm] = Dictionary(uniqueKeysWithValues: alarms.map { ($0.id, $0) })
        let now = Date().timeIntervalSince1970 * 1000
        let ceiling = now + Double(windowMs)

        var ids: [String] = []
        for entry in cascade {
            guard let uuid = UUID(uuidString: entry.id), let alarm = alarmsById[uuid] else { continue }
            let isAlerting: Bool = {
                switch alarm.state { case .scheduled: return false; @unknown default: return true }
            }()
            if isAlerting || (entry.ts > now && entry.ts <= ceiling) {
                ids.append(entry.id)
            }
        }
        result(ids)
    }

    // MARK: - Get Alarm IDs / Get Alarms

    /// Returns the `originalId`s of every cascade that still has a live master
    /// or a live burst in AlarmKit.
    private func getAlarmIds(result: @escaping FlutterResult) {
        let defaults = UserDefaults.standard
        let liveIds: Set<UUID> = Set((try? AlarmManager.shared.alarms)?.map { $0.id } ?? [])
        let prefix = "levio_config_"
        var ids: [String] = []
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            let originalId = String(key.dropFirst(prefix.count))
            var hasLive = false
            if let masterIdString = defaults.string(forKey: "levio_master_\(originalId)"),
               let masterUUID = UUID(uuidString: masterIdString),
               liveIds.contains(masterUUID) {
                hasLive = true
            }
            if !hasLive {
                hasLive = loadCascade(originalId: originalId).contains { entry in
                    guard let uuid = UUID(uuidString: entry.id) else { return false }
                    return liveIds.contains(uuid)
                }
            }
            if hasLive { ids.append(originalId) }
        }
        result(ids)
    }

    private func getAlarms(result: @escaping FlutterResult) {
        let defaults = UserDefaults.standard
        let prefix = "levio_config_"
        var list: [[String: Any]] = []
        let liveAlarms = (try? AlarmManager.shared.alarms) ?? []
        let liveById: [UUID: Alarm] = Dictionary(uniqueKeysWithValues: liveAlarms.map { ($0.id, $0) })

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

            // Master state.
            var masterAlarm: Alarm?
            var masterIdOut: String?
            if let masterIdString = defaults.string(forKey: "levio_master_\(originalId)"),
               let masterUUID = UUID(uuidString: masterIdString) {
                masterAlarm = liveById[masterUUID]
                masterIdOut = masterIdString
            }

            // Cascade state.
            let cascade = loadCascade(originalId: originalId)
            let cascadeAlarms: [Alarm] = cascade.compactMap { entry in
                guard let uuid = UUID(uuidString: entry.id) else { return nil }
                return liveById[uuid]
            }

            // Stale — no master, no bursts left. Skip.
            if masterAlarm == nil && cascadeAlarms.isEmpty { continue }

            let anyAlerting = (masterAlarm.map { alarm in
                switch alarm.state { case .scheduled: return false; @unknown default: return true }
            } ?? false) || cascadeAlarms.contains { alarm in
                switch alarm.state { case .scheduled: return false; @unknown default: return true }
            }
            info["state"] = anyAlerting ? "alerting" : "scheduled"
            if let masterIdOut = masterIdOut { info["masterId"] = masterIdOut }
            info["masterAlive"] = masterAlarm != nil
            info["cascadeSize"] = cascade.count
            info["liveCascadeSize"] = cascadeAlarms.count

            // Soonest next-burst fire time (alerting wins, else earliest future
            // scheduled). Mirrors getNextBurst so a single getAlarms round-trip
            // is enough for debug dumps.
            let nowMs = Date().timeIntervalSince1970 * 1000
            if let alerting = cascade.first(where: { entry in
                guard let uuid = UUID(uuidString: entry.id), let a = liveById[uuid] else { return false }
                switch a.state { case .scheduled: return false; @unknown default: return true }
            }) {
                info["nextBurstId"] = alerting.id
                info["nextBurstTimestampMs"] = nowMs
                info["nextBurstIsAlerting"] = true
            } else if let future = cascade
                .filter({ entry in
                    guard let uuid = UUID(uuidString: entry.id), liveById[uuid] != nil else { return false }
                    return entry.ts > nowMs
                })
                .min(by: { $0.ts < $1.ts }) {
                info["nextBurstId"] = future.id
                info["nextBurstTimestampMs"] = future.ts
                info["nextBurstIsAlerting"] = false
            }

            list.append(info)
        }
        result(list)
    }

    /// Debug dump of every native AlarmKit alarm (unfiltered by cascade
    /// grouping), enriched with its role (master/burst/unknown) and the
    /// originalId it belongs to via reverse lookup. Used by the admin
    /// "Print raw AlarmKit alarms" button.
    private func getRawAlarms(result: @escaping FlutterResult) {
        guard let alarms = try? AlarmManager.shared.alarms else {
            result([])
            return
        }
        let defaults = UserDefaults.standard
        var list: [[String: Any]] = []
        for alarm in alarms {
            let idString = alarm.id.uuidString
            var info: [String: Any] = ["id": idString]

            let isAlerting: Bool = {
                switch alarm.state { case .scheduled: return false; @unknown default: return true }
            }()
            info["state"] = isAlerting ? "alerting" : "scheduled"

            // Role + originalId via reverse lookups.
            if let ownerId = defaults.string(forKey: "levio_master_owner_\(idString)") {
                info["role"] = "master"
                info["originalId"] = ownerId
            } else if let ownerId = defaults.string(forKey: "levio_burst_\(idString)") {
                info["role"] = "burst"
                info["originalId"] = ownerId
            } else {
                info["role"] = "unknown"
            }

            // Schedule kind + details (alarm.schedule is Alarm.Schedule?).
            if let schedule = alarm.schedule {
                switch schedule {
                case .fixed(let date):
                    info["scheduleKind"] = "fixed"
                    info["fixedTimestampMs"] = date.timeIntervalSince1970 * 1000
                case .relative(let relative):
                    info["scheduleKind"] = "relative"
                    info["relativeHour"] = relative.time.hour
                    info["relativeMinute"] = relative.time.minute
                    info["relativeRepeats"] = "\(relative.repeats)"
                @unknown default:
                    info["scheduleKind"] = "unknown"
                }
            } else {
                info["scheduleKind"] = "countdown-only"
            }

            list.append(info)
        }
        result(list)
    }

    // MARK: - Get Ringing (as originalId)

    private func getRingingId(result: @escaping FlutterResult) {
        guard let alarms = try? AlarmManager.shared.alarms else {
            result(nil)
            return
        }
        let ringing = alarms.first { alarm in
            switch alarm.state { case .scheduled: return false; @unknown default: return true }
        }
        guard let firedId = ringing?.id.uuidString else {
            result(nil)
            return
        }
        let defaults = UserDefaults.standard
        let originalId = defaults.string(forKey: "levio_burst_\(firedId)")
            ?? defaults.string(forKey: "levio_master_owner_\(firedId)")
            ?? firedId
        result(originalId)
    }

    // MARK: - Get Ringing Alarms (native id + originalId)

    /// Returns every currently-alerting alarm as `{id, originalId}` where `id`
    /// is the native AlarmKit UUID of the alarm that's physically ringing and
    /// `originalId` is the cascade it belongs to. Suppression uses `id` to
    /// spare the burst that's actually ringing and `originalId` to cancel the
    /// rest of that cascade. Unlike `getRingingId`, this exposes the native id
    /// so the ringing burst can be matched against `getBurstsInWindow` output.
    private func getRingingAlarms(result: @escaping FlutterResult) {
        guard let alarms = try? AlarmManager.shared.alarms else {
            result([])
            return
        }
        let defaults = UserDefaults.standard
        var list: [[String: Any]] = []
        for alarm in alarms {
            let isAlerting: Bool = {
                switch alarm.state { case .scheduled: return false; @unknown default: return true }
            }()
            guard isAlerting else { continue }
            let idString = alarm.id.uuidString
            let originalId = defaults.string(forKey: "levio_burst_\(idString)")
                ?? defaults.string(forKey: "levio_master_owner_\(idString)")
                ?? idString
            // Fire time so the caller can keep the alarm that rang most
            // recently. Bursts are `.fixed`; a `.relative` master has no fixed
            // date, so fall back to 0 (a fresh burst always outranks it).
            var firedAtMs = 0.0
            if let schedule = alarm.schedule, case .fixed(let date) = schedule {
                firedAtMs = date.timeIntervalSince1970 * 1000
            }
            list.append([
                "id": idString,
                "originalId": originalId,
                "firedAtMs": firedAtMs,
            ])
        }
        result(list)
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
        cancelCascadeInternal(originalId: originalId)
        defaults.removeObject(forKey: "levio_config_\(originalId)")
    }

    // MARK: - Scheduling helpers

    /// Schedules the master alarm + 20 .fixed bursts. Master is `.relative`
    /// weekly for recurrent or `.fixed` for one-shot; bursts are always
    /// `.fixed` at masterDate + i*20s for i in 1...20.
    @discardableResult
    private func scheduleMasterAndBursts(
        originalId: UUID,
        masterDate: Date,
        isOneShot: Bool,
        weeklyRecurrence: [Locale.Weekday],
        recurrenceHour: Int,
        recurrenceMinute: Int,
        title: String,
        sfSymbol: String,
        secondaryLabel: String,
        soundName: String?,
        burstCount: Int = kBurstCount
    ) async -> Bool {
        let defaults = UserDefaults.standard
        let masterId = UUID()
        let masterSchedule: Alarm.Schedule
        if isOneShot {
            masterSchedule = .fixed(masterDate)
        } else {
            masterSchedule = .relative(
                Alarm.Schedule.Relative(
                    time: Alarm.Schedule.Relative.Time(hour: recurrenceHour, minute: recurrenceMinute),
                    repeats: weeklyRecurrence.isEmpty ? .never : .weekly(weeklyRecurrence)
                )
            )
        }
        let masterConfig = makeBurstConfig(
            burstId: masterId,
            originalId: originalId,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            schedule: masterSchedule,
            soundName: soundName,
            stopReschedules: true
        )

        var masterOK = false
        do {
            _ = try await AlarmManager.shared.schedule(id: masterId, configuration: masterConfig)
            defaults.set(masterId.uuidString, forKey: "levio_master_\(originalId.uuidString)")
            defaults.set(originalId.uuidString, forKey: "levio_master_owner_\(masterId.uuidString)")
            masterOK = true
        } catch {
            NSLog("[LevioAlarmKit] schedule master failed: %@", "\(error)")
            return false
        }

        await scheduleBurstsOnly(
            originalId: originalId,
            masterDate: masterDate,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            soundName: soundName,
            burstCount: burstCount,
            replaceCascade: true
        )
        return masterOK
    }

    /// Schedules `burstCount` .fixed bursts at masterDate + i*20s for i in
    /// 1...burstCount. If `replaceCascade` is true, wipes the existing cascade
    /// list first. Called both at initial schedule time and on
    /// `rescheduleForNextFire` after a mission completes.
    private func scheduleBurstsOnly(
        originalId: UUID,
        masterDate: Date,
        title: String,
        sfSymbol: String,
        secondaryLabel: String,
        soundName: String?,
        burstCount: Int,
        replaceCascade: Bool
    ) async {
        let defaults = UserDefaults.standard
        var cascade: [CascadeEntry] = replaceCascade ? [] : loadCascade(originalId: originalId.uuidString)
        if replaceCascade {
            // Cancel any still-scheduled prior bursts and wipe their reverse
            // lookups so we don't leak orphaned AlarmKit alarms.
            for entry in loadCascade(originalId: originalId.uuidString) {
                if let uuid = UUID(uuidString: entry.id) {
                    try? AlarmManager.shared.cancel(id: uuid)
                }
                defaults.removeObject(forKey: "levio_burst_\(entry.id)")
            }
        }

        // Gentle alarms request 0 bursts — persist the (now empty) cascade and
        // skip the loop entirely (a `1...0` range would trap at runtime).
        guard burstCount >= 1 else {
            saveCascade(originalId: originalId.uuidString, cascade: cascade)
            return
        }

        var cumulativeOffset: TimeInterval = 0
        for i in 1...burstCount {
            cumulativeOffset += intervalForBurst(at: i)
            let fire = masterDate.addingTimeInterval(cumulativeOffset)
            if fire <= Date() { continue } // skip past slots (e.g., priming from history)
            let burstId = UUID()
            let cfg = makeBurstConfig(
                burstId: burstId,
                originalId: originalId,
                title: title,
                sfSymbol: sfSymbol,
                secondaryLabel: secondaryLabel,
                schedule: .fixed(fire),
                soundName: soundName,
                stopReschedules: true
            )
            do {
                _ = try await AlarmManager.shared.schedule(id: burstId, configuration: cfg)
                defaults.set(originalId.uuidString, forKey: "levio_burst_\(burstId.uuidString)")
                cascade.append(CascadeEntry(id: burstId.uuidString, ts: fire.timeIntervalSince1970 * 1000))
            } catch {
                NSLog("[LevioAlarmKit] burst %d/%d failed: %@", i, burstCount, "\(error)")
            }
        }
        saveCascade(originalId: originalId.uuidString, cascade: cascade)
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

    /// Spacing for burst at 1-indexed `index`: increases by `kBurstIntervalSeconds`
    /// every 10 bursts (10s for 1–10, 20s for 11–20, 30s for 21–30). Bursts
    /// 31–40 are a supplementary band spaced 1m apart, extending coverage to
    /// ~20m without flattening the dense early escalation.
    private func intervalForBurst(at index: Int) -> TimeInterval {
        if index > 30 { return 60 }
        let group = (index - 1) / 10
        return Double(group + 1) * kBurstIntervalSeconds
    }

    /// Builds the AlarmKit configuration. When `stopReschedules` is true the
    /// Stop button (including the lock-screen slide) runs
    /// StopRescheduleOpenAppIntent, which silences the current alarm AND
    /// schedules a +5s nudge burst. All alarms (master and cascade bursts) use
    /// `stopReschedules: true` so sliding Stop on any ring always re-arms a
    /// nudge immediately.
    fileprivate func makeBurstConfig(
        burstId: UUID,
        originalId: UUID,
        title: String,
        sfSymbol: String,
        secondaryLabel: String,
        schedule: Alarm.Schedule,
        soundName: String?,
        stopReschedules: Bool
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

        if stopReschedules {
            return AlarmManager.AlarmConfiguration.alarm(
                schedule: schedule,
                attributes: attributes,
                stopIntent: StopRescheduleOpenAppIntent(alarmID: originalId.uuidString),
                secondaryIntent: OpenAlarmAppIntent(alarmID: originalId.uuidString),
                sound: sound
            )
        }
        return AlarmManager.AlarmConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: OpenAppIntent(alarmID: originalId.uuidString),
            secondaryIntent: OpenAlarmAppIntent(alarmID: originalId.uuidString),
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
        soundPath: String? = nil,
        burstCount: Int = kBurstCount
    ) {
        var config: [String: Any] = [
            "title": title,
            "sfSymbol": sfSymbol,
            "secondaryLabel": secondaryLabel,
            "isOneShot": isOneShot,
            // Per-cascade burst count. Gentle alarms store 0 so priming and
            // rescheduling never refill a burst cascade for them.
            "burstCount": burstCount,
            // Recorded at schedule time so priming can detect a tz shift and
            // regenerate the .fixed bursts (which are absolute and don't adapt
            // to timezone changes like the .relative weekly master does).
            "tzOffsetSeconds": TimeZone.current.secondsFromGMT(),
        ]
        if isOneShot {
            config["timestampMs"] = timestampMs
            // Persist the intended local (year, month, day, hour, minute) so a
            // later tz shift can reschedule the .fixed master at the same
            // wall-clock moment in the new timezone.
            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: Date(timeIntervalSince1970: timestampMs / 1000)
            )
            if let y = comps.year { config["intendedYear"] = y }
            if let m = comps.month { config["intendedMonth"] = m }
            if let d = comps.day { config["intendedDay"] = d }
            if let h = comps.hour { config["intendedHour"] = h }
            if let mi = comps.minute { config["intendedMinute"] = mi }
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

    // MARK: - Cascade storage

    fileprivate struct CascadeEntry {
        let id: String
        let ts: Double
    }

    fileprivate func saveCascade(originalId: String, cascade: [CascadeEntry]) {
        let defaults = UserDefaults.standard
        if cascade.isEmpty {
            defaults.removeObject(forKey: "levio_cascade_\(originalId)")
            return
        }
        let raw: [[String: Any]] = cascade.map { ["id": $0.id, "ts": $0.ts] }
        if let data = try? JSONSerialization.data(withJSONObject: raw) {
            defaults.set(data, forKey: "levio_cascade_\(originalId)")
        }
    }

    fileprivate func loadCascade(originalId: String) -> [CascadeEntry] {
        guard let data = UserDefaults.standard.data(forKey: "levio_cascade_\(originalId)"),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return raw.compactMap { dict in
            guard let id = dict["id"] as? String, let ts = dict["ts"] as? Double else { return nil }
            return CascadeEntry(id: id, ts: ts)
        }
    }

    /// Returns the next Date matching any weekday in `mask` at hour:minute
    /// strictly after `reference`. `mask` uses bit 0 = Monday … bit 6 = Sunday.
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
        return reference.addingTimeInterval(24 * 60 * 60)
    }

    // MARK: - Sound file prep (unchanged)

    fileprivate func prepareSoundFile(soundPath: String?) -> String? {
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

// MARK: - Nudge scheduler (called from StopRescheduleOpenAppIntent)

@available(iOS 26.0, *)
extension LevioAlarmKit {
    /// Schedules a single `.fixed` nudge burst +5s from now for the given
    /// originalId, preserving the cascade list. Used by
    /// `StopRescheduleOpenAppIntent` when the user taps Stop on the master
    /// or on a prior nudge burst. The nudge burst itself uses
    /// StopRescheduleOpenAppIntent so repeated Stop taps keep chaining +5s
    /// nudges, but is stored under `levio_burst_` like any cascade burst so
    /// counting / cancellation / suppression treat it uniformly.
    static func scheduleNudgeBurst(originalId: String) async {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "levio_config_\(originalId)"),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let originalUUID = UUID(uuidString: originalId) else {
            return
        }

        // Lock-guard against duplicates if user double-taps Stop.
        Self.primingLock.lock()
        if Self.primingInProgress.contains("nudge:\(originalId)") {
            Self.primingLock.unlock()
            return
        }
        Self.primingInProgress.insert("nudge:\(originalId)")
        Self.primingLock.unlock()
        defer {
            Self.primingLock.lock()
            Self.primingInProgress.remove("nudge:\(originalId)")
            Self.primingLock.unlock()
        }

        let title = config["title"] as? String ?? "Alarm"
        let sfSymbol = config["sfSymbol"] as? String ?? "alarm"
        let secondaryLabel = config["secondaryLabel"] as? String ?? "Open"
        let soundPath = config["soundPath"] as? String
        let helper = LevioAlarmKit()
        let soundName = helper.prepareSoundFile(soundPath: soundPath)

        let fire = Date().addingTimeInterval(kMasterStopNudgeDelaySeconds)
        let burstId = UUID()
        let cfg = helper.makeBurstConfig(
            burstId: burstId,
            originalId: originalUUID,
            title: title,
            sfSymbol: sfSymbol,
            secondaryLabel: secondaryLabel,
            schedule: .fixed(fire),
            soundName: soundName,
            stopReschedules: true
        )
        do {
            _ = try await AlarmManager.shared.schedule(id: burstId, configuration: cfg)
            defaults.set(originalId, forKey: "levio_burst_\(burstId.uuidString)")
            var cascade = helper.loadCascade(originalId: originalId)
            cascade.append(CascadeEntry(id: burstId.uuidString, ts: fire.timeIntervalSince1970 * 1000))
            helper.saveCascade(originalId: originalId, cascade: cascade)
        } catch {
            NSLog("[LevioAlarmKit] scheduleNudgeBurst failed: %@", "\(error)")
        }
    }
}
