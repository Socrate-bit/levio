---
name: step-01-parallel-checks
description: Launch 5 quality check agents in parallel and collect results
prev_step: steps/step-00-init.md
next_step: steps/step-02-summary.md
---

# Step 1: Parallel Quality Checks

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER run agents sequentially — ALL 5 in ONE message
- 🛑 NEVER analyze code yourself — delegate to agents
- ✅ ALWAYS launch all 5 agents with `run_in_background: true`
- ✅ ALWAYS pass diff context from step-00 to each agent prompt
- ✅ ALWAYS communicate in **English** with the user
- 📋 YOU ARE A COORDINATOR, not a checker
- 💬 FOCUS on launching agents and collecting results
- 🚫 FORBIDDEN to implement any checks yourself

## EXECUTION PROTOCOLS:

- 🎯 Launch all 5 agents in a single message
- 📖 Each agent gets full context (they can't see your conversation)
- 🚫 FORBIDDEN to read/analyze code yourself
- ✅ Wait for all agents to complete before proceeding

## CONTEXT BOUNDARIES:

- State variables from step-00 are available: `{diff_content}`, `{changed_files}`, `{commit_messages}`, `{base_branch}`, `{fix_mode}`
- You have the diff — pass it to agents, don't re-run git commands
- Agents return structured results to collect

## YOUR TASK:

Launch 5 independent check agents in parallel, wait for all results, and store them in `{check_results}`.

---

<available_state>
From step-00:

| Variable | Description |
|----------|-------------|
| `{auto_mode}` | Skip confirmations |
| `{fix_mode}` | Agents propose fixes |
| `{branch_name}` | Current git branch |
| `{base_branch}` | Base branch (or "main") |
| `{diff_content}` | Full git diff |
| `{changed_files}` | List of changed file paths |
| `{commit_messages}` | One-line commit messages |
</available_state>

---

## EXECUTION SEQUENCE:

### 1. Announce Launch

```
Launching 5 checks in parallel...
```

### 2. Launch ALL 5 Agents in ONE Message

<critical>
ALL 5 Agent tool calls MUST be in a SINGLE message.
Each with `run_in_background: true`.
This is CRITICAL for true parallelism.
</critical>

---

#### Agent 1: Code Reliability & Design Check

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "Code reliability check"
  prompt: |
    You are analyzing the reliability and design quality of the modified code.

    ## Changed Files
    {changed_files}

    ## Full Diff
    {diff_content}

    Read each modified file IN FULL (not just the diff) and look for:
    1. **Race conditions** — unguarded shared state, async without guard, concurrent side effects (especially around AlarmCubit, Firestore writes, native AlarmKit bridge)
    2. **Unhandled edge cases** — null/undefined not checked, empty lists, forgotten boundary cases, stream errors
    3. **Error handling** — missing try/catch, silently swallowed errors, no fallback, missing `debugPrint('[ClassTag] ...')` on errors
    4. **Design** — tight coupling, mixed responsibilities, misplaced abstractions, Cubit that does too much
    5. **Security** — Firestore rules bypassed, sensitive data exposed, validation missing at boundaries (user input, native channel events)
    6. **Memory / Performance** — stream/controller not disposed, listeners not cleaned up in `close()`, unnecessary rebuilds, missing `const` on widgets, expensive loops in build

    {fix_mode_instruction}

    Be pragmatic — only flag issues that could cause a production bug.
    Do NOT flag style preferences or micro-optimizations.

    RESPOND EXACTLY in this format:
    STATUS: PASS, WARN or FAIL
    ISSUES:
    - file:line — [severity: critical/warning] description (empty if PASS)
    SUMMARY: (one sentence)
```

**Note:** Replace `{fix_mode_instruction}` with:
- If `{fix_mode}` = true: `"For each issue, propose the fixed code."`
- If `{fix_mode}` = false: `"List issues without proposing code."`

---

#### Agent 2: Refactoring Check

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "Refactoring check"
  prompt: |
    You analyze the modified code for refactoring opportunities.

    ## Changed Files
    {changed_files}

    ## Full Diff
    {diff_content}

    Read each modified file IN FULL (not just the diff) and look for:
    1. Dead code introduced or left behind
    2. Code duplication (>10 repeated lines)
    3. Functions that could be simplified
    4. Over-complex logic
    5. Unused imports or variables
    6. Magic numbers or hardcoded strings that should be constants
    7. Speculative/unused helpers (project convention: "do not write speculative code")

    {fix_mode_instruction}

    Be pragmatic — only flag significant improvements, not style details.

    RESPOND EXACTLY in this format:
    STATUS: PASS or WARN
    SUGGESTIONS:
    - file:line — description (empty if PASS)
    SUMMARY: (one sentence)
```

**Note:** Replace `{fix_mode_instruction}` with:
- If `{fix_mode}` = true: `"For each suggestion, propose the fixed code."`
- If `{fix_mode}` = false: `"List suggestions without proposing code."`

---

#### Agent 3: Analyze & Tests

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "Dart analyze and flutter test"
  prompt: |
    You run `dart analyze` and `flutter test` on the project.

    The project is at: {project_root}

    Run these 2 commands IN PARALLEL (2 Bash calls in a single message):

    1. dart analyze
    2. flutter test

    Wait for both to finish.

    RESPOND EXACTLY in this format:
    STATUS: PASS or FAIL
    ANALYZE_STATUS: PASS or FAIL
    ANALYZE_ERRORS:
    - (list of analyzer errors/warnings, empty if PASS)
    TEST_STATUS: PASS or FAIL
    TEST_FAILURES:
    - (list of failing tests, empty if PASS)
    SUMMARY: (one sentence, e.g., "0 analyzer issues, 47/47 tests OK")
```

---

#### Agent 4: i18n Completeness

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "i18n completeness check"
  prompt: |
    You verify that translation keys added/modified in this PR exist in ALL locale files.

    ## Changed Files
    {changed_files}

    ## Full Diff
    {diff_content}

    ## i18n file locations
    - lib/l10n/app_en.arb (English)
    - lib/l10n/app_fr.arb (French)

    PROCEDURE:
    1. In the diff, extract NEW or MODIFIED translation keys:
       - Look for `AppLocalizations.of(context).<key>` patterns in modified .dart files
       - Look for `context.l10n.<key>` or equivalent helper patterns
       - Look for direct additions in the ARB JSON files
    2. For each key found, verify it exists in BOTH ARB files:
       - app_en.arb, app_fr.arb
       - If the key has placeholders (e.g. `{name}`), confirm the `@key` metadata block is present with matching placeholders
    3. Check ONLY keys in the diff — NOT a full audit

    SEVERITY RULES:
    - Key missing in app_en.arb = FAIL (English is the canonical source)
    - Key missing in app_fr.arb = FAIL (French is a first-class locale)
    - Missing `@key` metadata for a key that uses placeholders = WARN
    - No i18n key in the diff = PASS (no i18n change)

    RESPOND EXACTLY in this format:
    STATUS: PASS, WARN or FAIL
    MISSING_KEYS:
    - key.path → missing in: [locales] (empty if PASS)
    SUMMARY: (one sentence)
```

---

#### Agent 5: Test Coverage Check

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "Test coverage check"
  prompt: |
    You verify that new functionality introduced in this PR is covered by unit tests (and integration tests if a critical user flow is impacted).

    ## Changed Files
    {changed_files}

    ## Full Diff
    {diff_content}

    ## PART 1: Unit tests

    PROCEDURE:
    1. Identify modified/added SOURCE files (exclude test files, config, assets, generated l10n)
    2. For each source file with NEW logic (new Cubits, methods, services, helpers):
       - Check whether a corresponding test file exists under `test/`:
         - `lib/features/<feature>/cubit/<name>_cubit.dart` → `test/features/<feature>/<name>_cubit_test.dart`
         - `lib/features/<feature>/services/<name>_service.dart` → `test/features/<feature>/<name>_service_test.dart`
         - `lib/shared/services/<name>.dart` → `test/shared/services/<name>_test.dart`
         - `lib/features/<feature>/widgets/<name>.dart` → widget test under `test/features/<feature>/widgets/` (only if the widget has logic, not pure layout)
       - Verify the test covers the required cases:
         - Cubit: initial state, state transitions, error/rollback path, stream subscription lifecycle
         - Service: happy path, Firestore error path, auth scoping (uid in path)
         - Widget: render, tap/gesture callbacks, state-driven variants
    3. Do NOT flag files that are pure UI layout (presentational widgets with no logic)
    4. Do NOT flag minor changes (typos, imports, config)

    ## PART 2: Integration tests (flutter integration_test)

    Integration tests live in `integration_test/` and use the `integration_test` package.
    If `integration_test/` does not yet exist, critical-flow changes are WARN (recommend setup).

    INTEGRATION PROCEDURE:
    1. Check whether changes affect a CRITICAL USER FLOW:
       - Alarm creation / scheduling (including repeating + one-time)
       - Alarm ringing + dismiss (native → Flutter → mission)
       - Mission completion (pushups, squats, shake, math, speech, photo)
       - Streak / badge award flow
       - Anonymous auth bootstrap
       - Firestore sync on startup (orphan/missing alarm reconciliation)
       - Paywall / Superwall upgrade flow
    2. For each critical flow touched, verify:
       - Is there an existing integration test covering this flow? (read files in `integration_test/`)
       - Does the change break an existing integration test without updating it?
       - Is a NEW critical flow introduced without an integration test?
    3. Do NOT flag:
       - Purely visual/styling changes
       - Internal refactors without behavior change
       - Theme toggle and similar isolated settings

    SEVERITY RULES:
    - New Cubit without unit test = WARN
    - New service without unit test = WARN
    - New utility/helper without unit test = WARN
    - Minor change in already-tested file = PASS
    - Pure UI file (no logic) = PASS
    - New critical user flow without integration test = WARN
    - Change breaking an existing integration test = WARN
    - Backend/styling change with no flow impact = PASS

    RESPOND EXACTLY in this format:
    STATUS: PASS or WARN
    UNCOVERED_UNIT:
    - file — description of what is missing (empty if PASS)
    UNCOVERED_INTEGRATION:
    - flow — description of what is missing (empty if PASS)
    SUMMARY: (one sentence, e.g., "2 new cubits without tests, dismiss flow modified without integration update")
```

---

### 3. Wait for All Agents

As each agent completes, store its result. Wait until ALL 5 have returned.

Store results in `{check_results}`:

```
{check_results} = {
  code_reliability: { status, issues, summary },
  refactoring: { status, suggestions, summary },
  analyze_tests: { status, analyze_status, test_status, summary },
  i18n: { status, missing_keys, summary },
  test_coverage: { status, uncovered_unit, uncovered_integration, summary }
}
```

### 4. Proceed to Summary

Once all 5 agents have returned, immediately load step-02.

---

## SUCCESS METRICS:

✅ All 5 agents launched in ONE message (parallel)
✅ Each agent received full diff context
✅ All 5 agents completed and results collected
✅ Results stored in `{check_results}`
✅ No code analysis done by coordinator

## FAILURE MODES:

❌ Launching agents sequentially (one at a time)
❌ Not passing diff context to agents (they re-run git commands)
❌ Coordinator analyzing code instead of delegating
❌ Proceeding before all 5 agents complete
❌ **CRITICAL**: Not using `run_in_background: true` on all agents
❌ Not checking test coverage for new features

---

## NEXT STEP:

After all 5 agents return, load `./step-02-summary.md`

<critical>
Remember:
- ALL 5 agents in ONE message — this is non-negotiable for parallelism
- You are the COORDINATOR — never analyze code yourself
- Each agent needs FULL context (they can't see your conversation)
- Wait for ALL agents before proceeding
</critical>
