---
name: step-03-fix-proposal
description: Propose a precise fix based on root cause analysis
prev_step: steps/step-02-synthesis.md
---

# Step 3: Fix Proposal

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER apply the fix — only PROPOSE it
- 🛑 NEVER modify any files
- ✅ ALWAYS show exact code changes (before → after)
- ✅ ALWAYS communicate in **English** with the user
- ✅ ALWAYS respect project conventions described in `CLAUDE.md`
- 📋 YOU ARE A PROPOSAL WRITER, not a coder
- 💬 FOCUS on clear, precise, minimal changes
- 🚫 FORBIDDEN to use Edit, Write, or Bash tools

## EXECUTION PROTOCOLS:

- 🎯 Read the file(s) to modify to get exact current code
- 📖 Propose the minimum change that fixes the root cause
- 🚫 FORBIDDEN to refactor adjacent code or add features
- ✅ Check that the fix respects project conventions from `CLAUDE.md`

## CONTEXT BOUNDARIES:

- `{root_cause}` from step-02 is the confirmed root cause
- `{investigation_results}` provides supporting context
- Read files to get exact current code — don't guess

## YOUR TASK:

Propose a precise, minimal fix for the root cause with exact code changes, without applying it.

---

<available_state>

| Variable | Description |
|----------|-------------|
| `{auto_mode}` | Skip confirmations |
| `{bug_description}` | Original bug description |
| `{root_cause}` | Confirmed root cause with file, line, evidence |
| `{investigation_results}` | Full investigation results |

</available_state>

---

## EXECUTION SEQUENCE:

### 1. Read Current Code

Read the file(s) that need to be modified to get the exact current code:

```
Use Read tool to get the exact content around {root_cause.file}:{root_cause.line}
```

### 2. Design the Fix

Design a minimal fix that:
- Addresses the root cause directly
- Does NOT refactor surrounding code
- Does NOT add features
- Respects project conventions (see `CLAUDE.md` → Conventions):
  - Feature-first folder organization
  - Cubit (not full Bloc) — no events, just methods
  - `Equatable` for models and states
  - Fully reactive UI — every data change reflected immediately
  - Optimistic UI updates where beneficial
  - Firebase streams for real-time data sync
  - Keep logic simple, strict separation of concerns, no speculative code
  - `debugPrint` only for errors, prefixed with a class tag (e.g. `[AlarmCubit]`)
  - Comments: concise, explain what the function/object does

### 3. Present Fix Proposal

```
## Fix proposal

### Root cause
{root_cause.description}

### File(s) to modify

#### `{file_path}` (lines {start}-{end})

**Before:**
```{lang}
{exact current code}
```

**After:**
```{lang}
{proposed fix code}
```

### Explanation
{1-2 sentences explaining WHY this fix works}

### Impact
- Files modified: {count}
- Lines changed: ~{count}
- Regression risk: low/medium/high
- Tests to add: {yes/no — description if yes}
```

### 4. Side Effects Check

List any potential side effects:

```
### Potential side effects
- {effect_1} — risk: low/medium/high
- (none if the fix is isolated)
```

### 5. Test Recommendation

If the bug wasn't covered by existing tests:

```
### Recommended test
A test should verify that:
- {test case description}

File: `{test_file_path}`
Pattern to follow: see {existing_similar_test}
```

### 6. User Decision

**If `{auto_mode}` = true:**
→ Display the fix proposal and end workflow.
→ Tell user: "Fix proposed. Apply it manually, or rerun `/fix` later with an `-f` auto-apply flag (not yet implemented)."

**If `{auto_mode}` = false:**
Use AskUserQuestion:

```yaml
questions:
  - question: "Fix proposed. What now?"
    options:
      - "The fix looks good — I'll apply it myself"
      - "Change the fix — here's my feedback: ..."
      - "Cancel"
    multiSelect: false
```

### 7. Handle Response

- **"Fix looks good"** → End workflow. Display: "Diagnosis complete. Apply the fix manually or ask me to do it."
- **"Change the fix"** → Adjust based on feedback, re-present
- **"Cancel"** → End workflow

---

## SUCCESS METRICS:

✅ Current code read (not guessed)
✅ Fix is minimal — addresses ONLY the root cause
✅ Before/after code shown with exact syntax
✅ Project conventions respected in proposed code
✅ Side effects identified
✅ Test recommendation if gap found
✅ Fix NOT applied (proposal only)

## FAILURE MODES:

❌ Applying the fix (using Edit/Write tools)
❌ Proposing code without reading current state
❌ Over-engineering the fix (refactoring, adding features)
❌ Ignoring `CLAUDE.md` conventions (wrong feature folder, misusing Cubit, missing Equatable)
❌ Not showing before/after comparison
❌ Not mentioning test coverage gap

---

## END OF WORKFLOW

This is the final step. After the user acknowledges the fix proposal, the workflow ends.

<critical>
Remember:
- PROPOSAL ONLY — never apply the fix
- Read the actual file first — never guess code
- Minimal change — fix the bug, nothing more
- Show exact before/after with syntax highlighting
- Check project conventions (CLAUDE.md) before proposing
</critical>
