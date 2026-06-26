import DeviceActivity
import Foundation

// DeviceActivityMonitor extension target. This is the source of truth for the
// shield: iOS calls these callbacks at each schedule's start/end boundary even
// when Levio itself is not running. Both callbacks delegate to the shared
// reconcile(), which recomputes from all stored schedules whether blocking
// should currently be on — this keeps overlapping windows correct.
//
// NOTE: add ScreenTimeShared.swift to this target's membership in Xcode.
@available(iOS 16.0, *)
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        ScreenTimeStore.reconcile()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        ScreenTimeStore.reconcile()
    }
}
