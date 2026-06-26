import Flutter
import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

// Native bridge for the Screen Time feature. Mirrors LevioAlarmKit's plugin
// shape. Channel: `levio/screentime`. Uses the Screen Time frameworks:
//   - FamilyControls   → authorization + the app picker
//   - ManagedSettings  → the shield + denyAppRemoval (see ScreenTimeShared)
//   - DeviceActivity   → daily monitoring windows that flip the shield at the
//                        start/end boundaries (handled in the monitor extension)
//
// The blocked-app selection is opaque; it never crosses to Dart. Schedules +
// the enabled flag are pushed down via `applySchedules` and persisted in the
// shared App Group so the monitor extension can read them.

@available(iOS 16.0, *)
public class LevioScreenTime: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "levio/screentime",
            binaryMessenger: registrar.messenger()
        )
        let instance = LevioScreenTime()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(
            name: "levio/screentime/events",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(LevioScreenTimeStreamHandler())
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "authorizationStatus":
            result(authorizationStatusString())
        case "requestAuthorization":
            Task { await requestAuthorization(result: result) }
        case "pickApps":
            pickApps(result: result)
        case "selectedAppCount":
            result(ScreenTimeStore.selectionCount())
        case "applySchedules":
            applySchedules(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Authorization

    private func authorizationStatusString() -> String {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved: return "approved"
        case .denied: return "denied"
        case .notDetermined: return "notDetermined"
        @unknown default: return "notDetermined"
        }
    }

    private func requestAuthorization(result: @escaping FlutterResult) async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            result(AuthorizationCenter.shared.authorizationStatus == .approved)
        } catch {
            NSLog("[LevioScreenTime] requestAuthorization failed: \(error)")
            result(false)
        }
    }

    // MARK: - App picker

    private func pickApps(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            guard let root = Self.topViewController() else {
                result(ScreenTimeStore.selectionCount())
                return
            }
            let initial = ScreenTimeStore.loadSelection()
            let picker = FamilyActivityPickerHost(initialSelection: initial) { selection in
                ScreenTimeStore.saveSelection(selection)
                // Reflect the new selection immediately if a window is open.
                ScreenTimeStore.reconcile()
                root.dismiss(animated: true) {
                    let count = selection.applicationTokens.count
                        + selection.categoryTokens.count
                        + selection.webDomainTokens.count
                    result(count)
                }
            } onCancel: {
                root.dismiss(animated: true) {
                    result(ScreenTimeStore.selectionCount())
                }
            }
            let host = UIHostingController(rootView: picker)
            host.modalPresentationStyle = .pageSheet
            root.present(host, animated: true)
        }
    }

    // MARK: - Schedules

    private func applySchedules(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "bad_args", message: "applySchedules expects a map", details: nil))
            return
        }
        let enabled = args["enabled"] as? Bool ?? false
        let rawSchedules = args["schedules"] as? [[String: Any]] ?? []
        let schedules = rawSchedules.compactMap(Self.parseSchedule)

        ScreenTimeStore.saveConfig(enabled: enabled, schedules: schedules)

        let center = DeviceActivityCenter()
        center.stopMonitoring()

        if enabled {
            for schedule in schedules where schedule.enabled {
                let name = DeviceActivityName(ScreenTimeStore.activityPrefix + schedule.id)
                // Daily window; repeat-day filtering happens in reconcile().
                let activitySchedule = DeviceActivitySchedule(
                    intervalStart: DateComponents(hour: schedule.startHour, minute: schedule.startMinute),
                    intervalEnd: DateComponents(hour: schedule.endHour, minute: schedule.endMinute),
                    repeats: true
                )
                do {
                    try center.startMonitoring(name, during: activitySchedule)
                } catch {
                    NSLog("[LevioScreenTime] startMonitoring failed for \(schedule.id): \(error)")
                }
            }
        }

        // Apply/clear the shield right now so the UI and reality match without
        // waiting for the next interval boundary.
        ScreenTimeStore.reconcile()
        result(nil)
    }

    private static func parseSchedule(_ map: [String: Any]) -> STSchedule? {
        guard let id = map["id"] as? String else { return nil }
        return STSchedule(
            id: id,
            enabled: map["enabled"] as? Bool ?? true,
            repeatDays: (map["repeatDays"] as? [Bool]) ?? Array(repeating: true, count: 7),
            startHour: map["startHour"] as? Int ?? 22,
            startMinute: map["startMinute"] as? Int ?? 0,
            endHour: map["endHour"] as? Int ?? 7,
            endMinute: map["endMinute"] as? Int ?? 0
        )
    }

    // MARK: - Helpers

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scene?.windows.first?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - SwiftUI host for FamilyActivityPicker

@available(iOS 16.0, *)
private struct FamilyActivityPickerHost: View {
    @State var selection: FamilyActivitySelection
    let onDone: (FamilyActivitySelection) -> Void
    let onCancel: () -> Void

    init(
        initialSelection: FamilyActivitySelection,
        onDone: @escaping (FamilyActivitySelection) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _selection = State(initialValue: initialSelection)
        self.onDone = onDone
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Apps to block")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { onCancel() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { onDone(selection) }
                    }
                }
        }
    }
}

// MARK: - Event channel (reserved for future status events)

@available(iOS 16.0, *)
class LevioScreenTimeStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
