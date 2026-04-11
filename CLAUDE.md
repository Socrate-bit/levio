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
└── meta/profile           # currentStreak, longestStreak, lastWakeupDate, totalWakeups, earnedBadgeIds[], usedSoundIds[], usedMissionTypeNames[]
```

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

## Mission Types

| Type | Dismiss Mechanism |
|------|-------------------|
| none | Simple button |
| pushUps | ML Kit pose detection (10 reps, elbow angle state machine) |
| squats | ML Kit pose detection (20 reps) |
| shakePhone | Shake detector |
| math | Solve 3 problems (easy/medium/hard) |
| bibleVerse / affirmation | Speech-to-text, 50% word match |
| skyPhoto, makeBed, objectHunt, petHunt, natureHunt, touchGrass | Camera + Firebase AI (Gemini) image validation |
| random | Picks random mission at runtime |

## Navigation

- Bottom tabs: Home / Alarms / Insights / Settings (IndexedStack preserves state)
- `/alarm-dismiss` deep route with args `{alarmId, challenge, mathDifficulty, customObject}`
- Triggered by: native ring event, app resume lifecycle, cold start check

## Build & Run

```bash
flutter pub get
flutter run           # iOS simulator/device (primary target)
```

Firebase project: `levio-ef67e`

## Assets

- `assets/sounds/alarm.mp3`, `assets/sounds/bell.mp3`
- `assets/app_icon.png`, `assets/icon.png`

## Conventions

- Feature-first folder organization
- Cubit (not full Bloc) for state management — no events, just methods
- Equatable for value equality on models and states
- debugPrint with tags like `[AlarmService]`, `[AlarmCubit]` for logging
- Platform-adaptive UI via adaptive_platform_ui (iOS 26+ SF Symbols detection)
