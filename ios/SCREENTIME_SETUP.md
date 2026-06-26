# Screen Time feature — Xcode setup

All Swift + Dart code is written. The steps below are the manual Xcode /
Developer-portal work that cannot be done from code edits. App Group used
throughout: **`group.com.example.levio.screentime`**.

## 0. Family Controls entitlement (lead time!)
`com.apple.developer.family-controls` is a **special-access** entitlement.
- Development: works with a provisioning profile that includes the capability.
- **Distribution**: requires Apple approval — request it at
  https://developer.apple.com/contact/request/family-controls-distribution
  Do this early; approval is not instant.

## 1. App Group
In the Developer portal create App Group `group.com.example.levio.screentime`
and enable it (Signing & Capabilities) on **Runner + all three extensions**.
The `.entitlements` files already declare it; just make sure the group exists
and each target's profile includes it.

## 2. Runner target
- Already done in code: `Runner.entitlements` / `RunnerDebug.entitlements` now
  declare `family-controls` + the app group.
- `LevioScreenTime.swift` and `ScreenTimeShared.swift` are in `ios/Runner/` and
  build with the Runner target automatically (folder is in the target).
- The `levio://` URL scheme is already in `Info.plist`.
- In Signing & Capabilities add: **Family Controls** and **App Groups**.

## 3. Three new app-extension targets
File ▸ New ▸ Target. For each: set Team `DP23ZJCRBU`, deployment target ≥ 16.0,
add **Family Controls** + **App Groups** capabilities, and add
`ScreenTimeShared.swift` to the target's membership (Target Membership checkbox).

| Folder | Template | Bundle id | Principal class | Entitlements |
|---|---|---|---|---|
| `ScreenTimeMonitor/` | Device Activity Monitor Extension | `com.example.levio.monitor` | `DeviceActivityMonitorExtension` | `ScreenTimeMonitor.entitlements` |
| `ScreenTimeShield/` | Shield Configuration Extension | `com.example.levio.shield` | `ShieldConfigurationExtension` | `ShieldConfiguration.entitlements` |
| `ScreenTimeShieldAction/` | Shield Action Extension | `com.example.levio.shieldaction` | `ShieldActionExtension` | `ShieldAction.entitlements` |

For each new target:
1. Delete the auto-generated `.swift` / `Info.plist` and instead add the files
   already present in the matching folder here (the provided `Info.plist`
   already points `NSExtensionPrincipalClass` at the right class).
2. Set the target's `CODE_SIGN_ENTITLEMENTS` build setting to the provided
   `.entitlements` file in that folder.
3. Add `ScreenTimeShared.swift` (currently in `ios/Runner/`) to the target via
   Target Membership so `ScreenTimeStore` / `STSchedule` are visible.
4. Embed each extension in the Runner app (Build Phases ▸ Embed App Extensions —
   Xcode usually does this automatically when the target is created).

## 4. Shield branding asset
`ShieldConfigurationExtension.swift` uses `UIImage(named: "AppIcon")`. Either add
a small Levio logo image to the Shield target's asset catalog, or replace with an
SF Symbol (`UIImage(systemName: "moon.zzz.fill")`).

## 5. Known constraints (validate on a real device — no simulator support)
- **"Open Levio" button**: app extensions can't call `UIApplication.open`, so the
  shield action returns `.close` (sends the user Home to tap Levio). Re-evaluate
  per-iOS-version behaviour on device.
- **denyAppRemoval** blocks deleting *all* apps device-wide and only holds while
  Family Controls authorization is granted.
- **Overnight windows** (22:00→07:00): `DeviceActivitySchedule` is scheduled as a
  daily interval; `ScreenTimeStore.reconcile()` is the source of truth for which
  windows are actually open (it re-checks repeat days + the overnight wrap), so
  the shield is correct even with overlapping schedules.
