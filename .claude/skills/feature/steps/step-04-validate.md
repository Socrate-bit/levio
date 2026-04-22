---
name: step-04-validate
description: Self-check - run tests, verify AC, audit implementation quality
prev_step: steps/step-03-execute.md
next_step: steps/step-05-examine.md
---

# Step 4: Validate (Self-Check)

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER claim checks pass when they don't
- 🛑 NEVER skip any validation step
- ✅ ALWAYS run analyze, format, and tests
- ✅ ALWAYS verify each acceptance criterion
- ✅ ALWAYS fix failures before proceeding
- 📋 YOU ARE A VALIDATOR, not an implementer
- 💬 FOCUS on "Does it work correctly?"
- 🚫 FORBIDDEN to proceed with failing checks

## EXECUTION PROTOCOLS:

- 🎯 Run all validation commands
- 💾 Log results to output (if save_mode)
- 📖 Check each AC against implementation
- 🚫 FORBIDDEN to mark complete with failures

## CONTEXT BOUNDARIES:

- Implementation from step-03 (or step-03-execute-teams) is complete
- Tests may or may not pass yet
- Analyzer errors may exist
- Focus is on verification, not new implementation

## YOUR TASK:

Validate the implementation by running checks, verifying acceptance criteria, and ensuring quality.

---

<available_state>
From previous steps:

| Variable | Description |
|----------|-------------|
| `{task_description}` | What was implemented |
| `{task_id}` | Kebab-case identifier |
| `{acceptance_criteria}` | Success criteria |
| `{auto_mode}` | Skip confirmations |
| `{save_mode}` | Save outputs to files |
| `{test_mode}` | Include test steps |
| `{examine_mode}` | Auto-proceed to review |
| `{output_dir}` | Path to output (if save_mode) |
| Implementation | Completed in step-03 |
</available_state>

---

## EXECUTION SEQUENCE:

### 1. Initialize Save Output (if save_mode)

**If `{save_mode}` = true:**

```bash
bash {skill_dir}/scripts/update-progress.sh "{task_id}" "04" "validate" "in_progress"
```

Append results to `{output_dir}/04-validate.md` as you work.

### 2. Run Validation Suite

All commands are pre-configured — no discovery needed.

**2.1 Analyze (always)**
```bash
dart analyze
```

**MUST PASS.** If fails:
1. Read error messages
2. Fix analyzer issues (NEVER use `// ignore: ...` or `as dynamic` to silence)
3. Re-run until passing

**2.2 Format check (always)**

```bash
dart format --output=none --set-exit-if-changed lib test
```

If formatting drift:
```bash
dart format lib test
```

**MUST PASS.**

**2.3 Tests (always)**

```bash
flutter test
```

If `integration_test/` exists and `{test_mode}` = true:
```bash
flutter test integration_test/
```

**MUST PASS.** If fails:
1. Identify failing test
2. Determine if code bug or test bug
3. Fix the root cause
4. Re-run until passing

**2.4 Regenerate l10n (if ARB files modified)**

If any file in `lib/l10n/*.arb` was modified:
```bash
flutter gen-l10n
```

Commit the generated files under `lib/l10n/generated/` if they changed.

**If `{save_mode}` = true:** Log each result

### 3. Self-Audit Checklist

Verify each item:

**Tasks Complete:**
- [ ] All todos from step-03 marked complete
- [ ] No tasks skipped without reason
- [ ] Any blocked tasks have explanation

**Tests Passing:**
- [ ] All existing tests pass
- [ ] New tests written for new functionality (Cubit, service, widget)
- [ ] No skipped tests without reason

**Acceptance Criteria:**
- [ ] Each AC demonstrably met
- [ ] Can explain how implementation satisfies AC
- [ ] Edge cases considered

**Patterns Followed (`CLAUDE.md` conventions):**
- [ ] Feature-first folder structure respected
- [ ] Cubit (no events), `Equatable` on models/states
- [ ] UI is fully reactive; optimistic updates where sensible
- [ ] `debugPrint` only for errors, with `[ClassTag]` prefix
- [ ] No speculative code

### 5. Final Verification

Re-run analyze:
```bash
dart analyze
```

MUST pass.

### 7. Present Validation Results

```
**Validation Complete**

**Analyze:** ✓ Passed
**Format:** ✓ Passed
**Tests:** ✓ {X}/{X} passing

**Acceptance Criteria:**
- [✓] AC1: Verified by [how]
- [✓] AC2: Verified by [how]

**Files Modified:** {list}

**Summary:** All checks passing, ready for next step.
```

### 8. Determine Next Step

**Decision tree:**

```
IF {test_mode} = true:
    → Load step-07-tests.md (test analysis and creation)

ELSE IF {examine_mode} = true:
    → Load step-05-examine.md (adversarial review)

ELSE IF {auto_mode} = false:
    → Ask user:
```

```yaml
questions:
  - header: "Next"
    question: "Validation complete. What would you like to do?"
    options:
      - label: "Run adversarial review"
        description: "Deep review for security, logic, and quality"
      - label: "Complete workflow"
        description: "Skip review and finalize"
      - label: "Add tests"
        description: "Create additional tests first"
    multiSelect: false
```

```
ELSE:
    → Complete workflow (show final summary)
```

### 9. Complete Save Output (if save_mode)

**If `{save_mode}` = true:**

Append to `{output_dir}/04-validate.md`:
```markdown
---
## Step Complete
**Status:** ✓ Complete
**Analyze:** ✓
**Format:** ✓
**Tests:** ✓
**Next:** {next step based on flags}
**Timestamp:** {ISO timestamp}
```

---

## SUCCESS METRICS:

✅ Analyze passes
✅ Format passes
✅ All tests pass
✅ All AC verified
✅ User informed of status

## FAILURE MODES:

❌ Claiming checks pass when they don't
❌ Not running all validation commands
❌ Skipping tests for modified code
❌ Missing AC verification
❌ Proceeding with failures
❌ **CRITICAL**: Not using AskUserQuestion for next step

## VALIDATION PROTOCOLS:

- Run EVERY validation command
- Fix failures IMMEDIATELY
- Don't proceed until all green
- Verify EACH acceptance criterion
- Document all results

---

## NEXT STEP:

Based on flags (check in order):
- **If test_mode:** Load `./step-07-tests.md`
- **If examine_mode OR user requests:** Load `./step-05-examine.md`
- **If pr_mode:** Load `./step-09-finish.md` to create pull request
- **Otherwise:** Workflow complete - show summary

<critical>
Remember: NEVER proceed with failing checks - fix everything first!
</critical>
