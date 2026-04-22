---
name: step-02-summary
description: Display results table and decide whether to push
prev_step: steps/step-01-parallel-checks.md
next_step: steps/step-03-push.md
---

# Step 2: Summary & Decision

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER push if analyze or tests FAIL (even in auto_mode)
- ✅ ALWAYS display the summary table
- ✅ ALWAYS use AskUserQuestion for decisions (unless auto_mode + all pass)
- ✅ ALWAYS communicate in **English** with the user
- 📋 YOU ARE A REPORTER, not a fixer
- 💬 FOCUS on presenting results clearly
- 🚫 FORBIDDEN to fix any issues yourself

## EXECUTION PROTOCOLS:

- 🎯 Display table first, then decide
- 📖 Show details only for FAIL/WARN items
- 🚫 FORBIDDEN to skip the summary table

## CONTEXT BOUNDARIES:

- `{check_results}` from step-01 contains all 5 agent results
- `{auto_mode}` determines whether to ask user or auto-proceed
- `{branch_mode}` if true, skip push entirely (check-only mode)
- `{branch_name}` for display

## YOUR TASK:

Display a clear summary table of all check results and determine whether to proceed to push.

---

<available_state>

| Variable | Description |
|----------|-------------|
| `{auto_mode}` | Skip confirmations |
| `{branch_name}` | Current branch |
| `{check_results}` | Results from all 5 agents |

</available_state>

---

## EXECUTION SEQUENCE:

### 1. Compile Summary Table

Display this table with results from `{check_results}`:

```
## Pre-Push Quality Gate — {branch_name}

| # | Check             | Status | Summary                          |
|---|-------------------|--------|----------------------------------|
| 1 | Code Reliability  | {s}    | {check_results.code_reliability.summary} |
| 2 | Refactoring       | {s}    | {check_results.refactoring.summary} |
| 3 | Analyze & Tests   | {s}    | {check_results.analyze_tests.summary} |
| 4 | i18n              | {s}    | {check_results.i18n.summary} |
| 5 | Test Coverage     | {s}    | {check_results.test_coverage.summary} |

**Result: {X}/5 passed, {Y} warnings, {Z} failures**
```

Use status indicators:
- PASS = `PASS`
- WARN = `WARN`
- FAIL = `FAIL`

### 2. Determine Overall Result

```
{all_passed} = true if NO check has status FAIL
               (WARN is acceptable, only FAIL blocks)
```

### 3. Show Details for Non-PASS Items

For each FAIL or WARN, show details below the table:

```
### Details

**Analyze & Tests (FAIL)**
- lib/features/alarms/cubit/alarm_cubit.dart:42 — `The argument type 'String?' can't be assigned to the parameter type 'String'`
- test/features/alarms/alarm_cubit_test.dart — 2/5 tests failing

**Refactoring (WARN)**
- lib/features/auth/cubit/auth_cubit.dart:23 — Function could be simplified (30 lines → ~15)

**i18n (WARN)**
- home.newFeature → missing `@key` metadata for placeholder

**Test Coverage (WARN)**
- lib/features/onboarding/cubit/onboarding_cubit.dart — New cubit without a test file
```

### 4. Decision Logic

**If `{branch_mode}` = true:**
→ Display summary table + details for FAIL/WARN items
→ Display: "Branch mode: checks complete, no push."
→ STOP workflow. No push step.

**If `{auto_mode}` = true AND `{all_passed}` = true:**
→ Display: "Auto-mode: all checks passed. Pushing..."
→ Proceed directly to step-03-push.md

**If `{auto_mode}` = true AND `{all_passed}` = false:**
→ Display details
→ Use AskUserQuestion:

```yaml
questions:
  - question: "Some checks failed. What now?"
    options:
      - "Show full details"
      - "Push anyway (override)"
      - "Cancel"
    multiSelect: false
```

**If `{auto_mode}` = false AND `{all_passed}` = true:**
→ Use AskUserQuestion:

```yaml
questions:
  - question: "All checks passed. Push to {branch_name}?"
    options:
      - "Push"
      - "Show details"
      - "Cancel"
    multiSelect: false
```

**If `{auto_mode}` = false AND `{all_passed}` = false:**
→ Display details
→ Use AskUserQuestion:

```yaml
questions:
  - question: "Some checks failed ({Z} failures). What now?"
    options:
      - "Show full details"
      - "Push anyway (override)"
      - "Cancel"
    multiSelect: false
```

### 5. Handle User Response

- **"Push" / "Push anyway"** → Load step-03-push.md
- **"Show details" / "Show full details"** → Show full agent outputs, then re-ask
- **"Cancel"** → STOP workflow. Display "Push cancelled."

---

## SUCCESS METRICS:

✅ Summary table displayed with all 5 checks
✅ Details shown for FAIL/WARN items
✅ Correct decision logic applied (auto vs interactive)
✅ AskUserQuestion used for all user decisions
✅ User can see enough information to make a decision

## FAILURE MODES:

❌ Not showing the summary table
❌ Auto-pushing when there are FAILs
❌ Not using AskUserQuestion (plain text prompts instead)
❌ Not showing details for failed checks
❌ Fixing issues instead of reporting them

---

## NEXT STEP:

If user chooses to push, load `./step-03-push.md`
If user cancels, workflow ends.

<critical>
Remember:
- NEVER auto-push with FAILs — always ask the user
- WARN is non-blocking (refactoring suggestions, missing placeholder metadata)
- FAIL is blocking (analyzer errors, test failures, missing keys in any locale)
- Use AskUserQuestion, NEVER plain text "[C] Continue" prompts
</critical>
