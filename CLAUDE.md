# CLAUDE.md — Levio

## What is Levio?

Levio is a Flutter alarm clock app that forces you to complete physical or mental missions to dismiss the alarm. It gamifies waking up with streaks, badges, and session analytics.

## Tech Stack

- **Flutter** (Dart SDK ^3.11.4), Material Design 3
- **State management**: flutter_bloc (Cubit pattern)
- **Backend**: Firebase (Auth anonymous, Cloud Firestore, Firebase AI / Gemini 2.5 Flash Lite)
- **Native bridge**: iOS AlarmKit via MethodChannel/EventChannel (`levio/alarmkit`)
- **ML**: google_mlkit_pose_detection for exercise rep counting
- **Other**: camera, speech_to_text, shake, audioplayers, shared_preferences, adaptive_platform_ui

## Project Structure

```
lib/
├── main.dart                          # Bootstrap: Firebase init, auth, alarm listener, routing
├── firebase_options.dart              # Firebase config (iOS only, Android placeholder)
├── services/
│   └── auth_service.dart              # Anonymous Firebase auth
├── shared/
│   ├── theme/app_theme.dart           # AppColors, light/dark themes
│   ├── services/sound_service.dart    # Singleton: plays rep bell sound
│   └── widgets/
│       ├── bottom_nav_shell.dart      # 4-tab scaffold (Home, Alarms, Insights, Settings)
│       └── hexagon_badge.dart         # Badge display widget
└── features/
    ├── alarms/                        # CRUD alarms, native scheduling, Firestore sync
    ├── dismiss/                       # Mission screens (pushups, squats, shake, math, speech, photo)
    ├── missions/                      # MissionType enum, MissionInfo metadata
    ├── home/                          # Dashboard: streak, week view, next alarm
    ├── insights/                      # Real-time analytics with range toggle
    ├── milestones/                    # Badges & achievements (streak + achievement kinds)
    ├── wakeup/                        # Session history, daily quotes, completion flow
    └── settings/                      # Theme toggle (dark/light via SharedPreferences)
```

Each feature follows: `cubit/` (state), `screens/` (UI), `services/` (data), `models/` (entities), `widgets/` (reusable UI).

## Firestore Schema

```
users/{uid}/
├── alarms/{alarmId}       # dateTimeMs, missionType, name, soundId, repeatDays, isEnabled, isOneTime, mathDifficulty, customObject?
├── sessions/{docId}       # alarmId, timestamp, timeTakenSeconds, missionType, soundId, completed
├── meta/profile           # currentStreak, longestStreak, lastWakeupDate, totalWakeups, earnedBadgeIds[], usedSoundIds[], usedMissionTypeNames[]
└── meta/screentime        # enabled, schedules[] (id, enabled, repeatDays, startHour/Minute, endHour/Minute), updatedAtMs — blocked-app selection is NOT synced (device-local opaque tokens)
```
Firebase project: `levio-ef67e`

## Key Architecture Decisions

- **Optimistic UI**: AlarmCubit emits state changes immediately, rolls back on Firestore errors
- **Snooze alarms are native-only** — no Firestore doc, tracked via snooze map from native
- **Alarm sync on startup**: fetches Firestore + native IDs, reschedules missing, cancels orphans
- **iOS-first**: native AlarmKit integration via method/event channels; Android not fully configured
- **Anonymous auth**: single anonymous Firebase user per device, all data scoped to UID
- **Debug mode**: forces 5-second alarms for testing

## Native iOS Bridge (AlarmChannel)

- Method Channel: `levio/alarmkit`
- Event Channel: `levio/alarmkit/events` (ring, intentFired events)
- Key methods: scheduleOneShot, scheduleRepeating, cancel, stop, dismissAlarm, getRingingId, getSnoozeMap, getAlarms, markCompleted

## Navigation

- Bottom tabs: Home / Alarms / Insights / Settings (IndexedStack preserves state)
- `/alarm-dismiss` deep route with args `{alarmId, challenge, mathDifficulty, customObject}`
- Triggered by: native ring event, app resume lifecycle, cold start check

## Conventions

### Architecture & State Management

* **Folder Organization:** Use a feature-first structure.
* **State Management:** Cubit (not full Bloc) for state management — no events, just methods.
* **Model/State Equality:** Equatable for value equality on models and states
* **Reactivity:** Ensure the application is fully reactive to state changes. Every data change must be reflected in the UI immediately.
* **Optimistic Updates:** Implement optimistic UI changes where beneficial to improve perceived performance.
* **Data Streaming:** Use Firebase Streams for real-time data synchronization when appropriate.

### Development Standards

* **Simplicity:** Keep logic as simple as possible
* **Clean code:** Maintain strict separation of concerns.
* **Dry Principle:** Reuse existing functions. Minimize boilerplate and do not write speculative code (no unused or "future-proof" functions).
* **Error Handling:** Use `debugPrint` only for errors. Do not log successful operations.
* **Logging Format:** All `debugPrint` statements must include a class tag for easier filtering (e.g., `[AlarmService]`, `[AlarmCubit]`).
* **Comments:** Use comments to succinctly explain functions / object / steps etc.







