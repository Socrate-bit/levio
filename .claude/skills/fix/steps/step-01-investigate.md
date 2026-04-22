---
name: step-01-investigate
description: Launch 4 investigation agents in parallel and collect results
prev_step: steps/step-00-init.md
next_step: steps/step-02-synthesis.md
---

# Step 1: Parallel Investigation

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER run agents sequentially — ALL 4 in ONE message
- 🛑 NEVER investigate code yourself — delegate to agents
- ✅ ALWAYS launch all 4 agents with `run_in_background: true`
- ✅ ALWAYS pass full context from step-00 to each agent prompt
- ✅ ALWAYS communicate in **English** with the user
- 📋 YOU ARE A COORDINATOR, not an investigator
- 💬 FOCUS on launching agents and collecting results
- 🚫 FORBIDDEN to read/analyze code yourself

## EXECUTION PROTOCOLS:

- 🎯 Launch all 4 agents in a single message
- 📖 Each agent gets full context (they can't see your conversation)
- 🚫 FORBIDDEN to read/analyze code yourself
- ✅ Wait for all agents to complete before proceeding
- ✅ Skip agents that are not relevant (e.g., Firestore agent if `{needs_firestore}` = false)

## CONTEXT BOUNDARIES:

- State variables from step-00 are available: `{bug_description}`, `{scope_files}`, `{scope_modules}`, `{related_tests}`, `{needs_firestore}`, `{needs_posthog}`, `{posthog_email}`, `{deep_mode}`
- You have the scope — pass it to agents, don't re-search
- Agents return structured results to collect

## YOUR TASK:

Launch 4 independent investigation agents in parallel, wait for all results, and store them in `{investigation_results}`.

---

<available_state>
From step-00:

| Variable | Description |
|----------|-------------|
| `{auto_mode}` | Skip confirmations |
| `{deep_mode}` | Exhaustive investigation |
| `{bug_description}` | User's bug description |
| `{scope_files}` | Files identified as relevant |
| `{scope_modules}` | Modules involved (lib/features/*, lib/services/, ios/, etc.) |
| `{related_tests}` | Test files related to scope |
| `{needs_firestore}` | Whether Firestore investigation is needed |
| `{needs_posthog}` | Whether PostHog investigation is needed |
| `{posthog_email}` | Email of the affected user (if provided) |
</available_state>

---

## EXECUTION SEQUENCE:

### 1. Announce Launch

```
Launching 4 investigation agents in parallel...
```

### 2. Launch ALL 4 Agents in ONE Message

<critical>
ALL 4 Agent tool calls MUST be in a SINGLE message.
Each with `run_in_background: true`.
This is CRITICAL for true parallelism.
If an agent is not needed (e.g., Firestore agent when {needs_firestore} = false), still launch it but tell it to return SKIPPED immediately.
</critical>

---

#### Agent 1: Code Tracer

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "Code tracer"
  prompt: |
    You are a debugger expert. You trace a bug's execution path to find the root cause.

    ## Bug
    {bug_description}

    ## Affected files
    {scope_files}

    ## Modules
    {scope_modules}

    ## Project
    Levio — Flutter alarm clock app that forces physical/mental missions to dismiss the alarm.
    - Flutter (Dart ^3.11.4), Material 3
    - State management: flutter_bloc (Cubit — no events, just methods)
    - Backend: Firebase (anonymous Auth, Cloud Firestore, Firebase AI/Gemini)
    - Native iOS bridge: AlarmKit via MethodChannel/EventChannel `levio/alarmkit`
    - ML: google_mlkit_pose_detection for exercise rep counting
    - Other: camera, speech_to_text, shake, audioplayers, shared_preferences
    - Feature-first folder structure: `lib/features/<feature>/{cubit,screens,services,models,widgets}/`

    ## Conventions
    Read `CLAUDE.md` in the project root for the full project conventions (architecture, Cubit pattern, optimistic UI, Firestore schema, native bridge details, feature folder structure).

    PROCEDURE:
    1. Read IN FULL each file identified as affected
    2. Trace the bug's execution path:
       - Entry point (Cubit method, widget callback, native channel event, main.dart alarm listener)
       - Data flow (state transitions, Firestore reads/writes, streams, native → Flutter events)
       - Conditions and branches that could cause the bug
    3. Identify suspects:
       - Code that looks incorrect or fragile
       - Unhandled conditions (null, empty list, stream error, edge cases)
       - Race conditions or timing issues (optimistic UI rollback, alarm listener init, Firebase auth bootstrap)
       - Inverted or missing logic
    4. {deep_mode_instruction}

    RESPOND EXACTLY in this format:
    EXECUTION_PATH:
    - step: description (file:line)
    SUSPECTS:
    - file:line — description of the potential issue (confidence: 0-100%)
    ROOT_CAUSE_HYPOTHESIS: (your best hypothesis in one sentence)
    EVIDENCE: (the evidence supporting your hypothesis)
```

**Note:** Replace `{deep_mode_instruction}` with:
- If `{deep_mode}` = true: `"ALSO trace adjacent paths — imports, called functions, parent/child widgets, listeners. Read wide context."`
- If `{deep_mode}` = false: `"Focus on the main path only."`

---

#### Agent 2: Test Runner

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "Test runner"
  prompt: |
    You run tests related to a bug and analyze the results.

    ## Bug
    {bug_description}

    ## Related tests
    {related_tests}

    ## Affected modules
    {scope_modules}

    PROCEDURE:
    Run all commands from the current working directory (the project root).

    1. Run tests in scope:
       - If specific tests are identified: run them individually (`flutter test test/features/<feature>/<name>_test.dart`)
       - Otherwise: run `flutter test test/features/<feature>/` for the affected feature, or `flutter test` for a full run
    2. Analyze results:
       - FAILING tests → precise description of the error
       - PASSING tests that do NOT cover the bug case → note the gap
    3. If no test covers the bug:
       - Identify what test is missing
       - Describe what it should verify (initial state, state transition, error path, stream lifecycle)

    RESPOND EXACTLY in this format:
    TEST_STATUS: PASS, FAIL or NO_COVERAGE
    FAILING_TESTS:
    - test_name — error message (empty if all pass)
    COVERAGE_GAPS:
    - description of what is not tested
    RELEVANT_FINDINGS:
    - any useful observation from the test results
    SUMMARY: (one sentence)
```

---

#### Agent 3: Firestore Inspector

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "Firestore inspector"
  prompt: |
    You inspect expected Firestore document shapes and reads/writes to find clues about a bug.

    ## Bug
    {bug_description}

    ## Affected files
    {scope_files}

    ## Firestore investigation needed
    {needs_firestore}

    If {needs_firestore} = false:
    → Simply respond: STATUS: SKIPPED, SUMMARY: "No Firestore investigation needed"

    If {needs_firestore} = true:

    ## Schema
    Firestore schema is documented in `CLAUDE.md` (section "Firestore Schema"):
      users/{uid}/
      ├── alarms/{alarmId}       # dateTimeMs, missionType, name, soundId, repeatDays, isEnabled, isOneTime, mathDifficulty, customObject?
      ├── sessions/{docId}       # alarmId, timestamp, timeTakenSeconds, missionType, soundId, completed
      └── meta/profile           # currentStreak, longestStreak, lastWakeupDate, totalWakeups, earnedBadgeIds[], usedSoundIds[], usedMissionTypeNames[]

    No MCP tool is available for direct Firestore queries — you work by READING code + schema.

    PROCEDURE:
    1. Read `CLAUDE.md` section "Firestore Schema" and any referenced Cubit/service files
    2. Read the affected Cubits/services (`lib/features/<feature>/cubit/*.dart`, `.../services/*.dart`) to understand what shape they READ and WRITE
    3. Identify:
       - Expected document fields → what the code reads/writes
       - Missing or mistyped fields (e.g., code writes `missionType` but reads `mission_type`)
       - Missing null/default handling for optional fields (`customObject`, `mathDifficulty`)
       - Auth scoping issues (is the path `users/{uid}/...` correctly scoped?)
       - Orphan data (alarm doc without corresponding native alarm ID, or vice versa — `main.dart` startup sync logic)
       - Snooze vs native-only handling (snooze alarms have no Firestore doc per CLAUDE.md)
    4. List hypotheses the user can verify directly in the Firebase console

    ⚠️ READ-ONLY — never propose writes; this step is inspection only.

    RESPOND EXACTLY in this format:
    STATUS: PASS, ISSUE_FOUND, NEEDS_MANUAL_CHECK or SKIPPED
    EXPECTED_SHAPE:
    - path — description of expected fields
    MISMATCHES:
    - description of field/type/path mismatch (empty if PASS)
    MANUAL_CHECKS:
    - console query the user should run to verify (e.g., "open Firebase console → users/{uid}/alarms, check that missionType exists on doc xyz")
    SUMMARY: (one sentence)
```

---

#### Agent 4: PostHog Inspector

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "PostHog inspector"
  prompt: |
    You inspect PostHog data (analytics/exceptions) for a specific user to find clues about a bug.

    ## Bug
    {bug_description}

    ## PostHog investigation needed
    {needs_posthog}

    ## User email
    {posthog_email}

    If {needs_posthog} = false:
    → Simply respond: STATUS: SKIPPED, SUMMARY: "No PostHog investigation needed"

    If {needs_posthog} = true:

    ## PostHog API
    The project uses `posthog_flutter`. The instance host is set by the `POSTHOG_HOST` env var (default `https://eu.i.posthog.com`) and the API key is in `POSTHOG_API_KEY` (Bearer token).

    If `POSTHOG_API_KEY` is NOT set:
    → Respond: STATUS: SKIPPED, SUMMARY: "POSTHOG_API_KEY not set — cannot query PostHog"

    ## PROCEDURE:

    1. **Find the user** — Search by email:
       ```bash
       curl -s "${POSTHOG_HOST:-https://eu.i.posthog.com}/api/projects/@current/persons/?search={posthog_email}" \
         -H "Authorization: Bearer $POSTHOG_API_KEY" | python3 -c "
       import sys,json
       d=json.load(sys.stdin)
       for p in d.get('results',[]):
           print('Person ID:', p.get('id'))
           print('Distinct IDs:', p.get('distinct_ids'))
       "
       ```

    2. **Look for exceptions** — Use distinct_id (internal UUID, NOT the email) to filter:
       ```bash
       curl -s "${POSTHOG_HOST:-https://eu.i.posthog.com}/api/projects/@current/events/?distinct_id={DISTINCT_ID}&event=\$exception&limit=20" \
         -H "Authorization: Bearer $POSTHOG_API_KEY" | python3 -c "
       import sys,json
       d=json.load(sys.stdin)
       for r in d.get('results',[]):
           ts = r.get('timestamp','')
           props = r.get('properties',{})
           exc_types = props.get('\$exception_types', [])
           exc_values = props.get('\$exception_values', [])
           print(f'{ts} | {exc_types}: {str(exc_values)[:300]}')
       "
       ```

    3. **Look for bug-specific events** (any alarm / mission / streak / auth related events — grep the returned event list for names that match the bug area):
       ```bash
       curl -s "${POSTHOG_HOST:-https://eu.i.posthog.com}/api/projects/@current/events/?person_id={PERSON_ID}&limit=100" \
         -H "Authorization: Bearer $POSTHOG_API_KEY" | python3 -c "
       import sys,json
       d=json.load(sys.stdin)
       events = set()
       for r in d.get('results',[]): events.add(r.get('event',''))
       for e in sorted(events): print(e)
       "
       ```

    4. **Analyze** the results:
       - Recent exceptions related to the bug?
       - Missing events (the user did not trigger the expected action)?
       - Repeated error patterns?
       - What platform/OS is the user on (iOS / macOS / other)?

    ⚠️ READ-ONLY API (GET only)

    RESPOND EXACTLY in this format:
    STATUS: PASS, ISSUE_FOUND or SKIPPED
    USER_FOUND: yes/no (person_id if yes)
    EXCEPTIONS:
    - timestamp — type: message (empty if none)
    RELEVANT_EVENTS:
    - event_name — count or details
    USER_PLATFORM: (iOS/macOS/other/unknown)
    SUMMARY: (one sentence)
```

---

### 3. Wait for All Agents

As each agent completes, store its result. Wait until ALL 4 have returned.

Store results in `{investigation_results}`:

```
{investigation_results} = {
  code_tracer: { execution_path, suspects, root_cause_hypothesis, evidence },
  test_runner: { test_status, failing_tests, coverage_gaps, findings, summary },
  firestore_inspector: { status, expected_shape, mismatches, manual_checks, summary },
  posthog_inspector: { status, user_found, exceptions, relevant_events, user_platform, summary }
}
```

### 4. Proceed to Synthesis

Once all 4 agents have returned, immediately load step-02.

---

## SUCCESS METRICS:

✅ All 4 agents launched in ONE message (parallel)
✅ Each agent received full context (bug description, scope, tool instructions)
✅ Irrelevant agents told to SKIP (not omitted)
✅ All 4 agents completed and results collected
✅ Results stored in `{investigation_results}`
✅ No code analysis done by coordinator

## FAILURE MODES:

❌ Launching agents sequentially (one at a time)
❌ Not passing scope context to agents
❌ Coordinator analyzing code instead of delegating
❌ Proceeding before all 4 agents complete
❌ **CRITICAL**: Not using `run_in_background: true` on all agents
❌ Not giving tool names to agents that need them

---

## NEXT STEP:

After all 4 agents return, load `./step-02-synthesis.md`

<critical>
Remember:
- ALL 4 agents in ONE message — this is non-negotiable for parallelism
- You are the COORDINATOR — never analyze code yourself
- Each agent needs FULL context (they can't see your conversation)
- Give tool names explicitly — agents don't know what's available
- Wait for ALL agents before proceeding
</critical>
