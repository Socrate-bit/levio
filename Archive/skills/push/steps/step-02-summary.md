---
name: step-02-summary
description: Display results table and decide whether to push
prev_step: steps/step-01-parallel-checks.md
next_step: steps/step-03-push.md
---

# Step 2: Summary & Decision

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER push if typecheck or tests FAIL (even in auto_mode)
- ✅ ALWAYS display the summary table
- ✅ ALWAYS use AskUserQuestion for decisions (unless auto_mode + all pass)
- ✅ ALWAYS communicate in **French** with the user
- 📋 YOU ARE A REPORTER, not a fixer
- 💬 FOCUS on presenting results clearly
- 🚫 FORBIDDEN to fix any issues yourself

## EXECUTION PROTOCOLS:

- 🎯 Display table first, then decide
- 📖 Show details only for FAIL/WARN items
- 🚫 FORBIDDEN to skip the summary table

## CONTEXT BOUNDARIES:

- `{check_results}` from step-01 contains all 6 agent results
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

| # | Check             | Status | Resume                          |
|---|-------------------|--------|---------------------------------|
| 1 | Code Reliability   | {s}    | {check_results.code_reliability.summary} |
| 2 | Refactoring       | {s}    | {check_results.refactoring.summary} |
| 3 | Rules Compliance  | {s}    | {check_results.rules.summary} |
| 4 | Typecheck & Tests | {s}    | {check_results.typecheck_tests.summary} |
| 5 | i18n              | {s}    | {check_results.i18n.summary} |
| 6 | Test Coverage     | {s}    | {check_results.test_coverage.summary} |

**Resultat: {X}/6 passed, {Y} warnings, {Z} failures**
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

**Rules Compliance (FAIL)**
- [typescript.md] apps/app/screens/Home.tsx:15 — Using `as any` type cast
- [api.md] apps/api/src/routes/auth.ts:42 — Missing ownership check

**Refactoring (WARN)**
- apps/app/hooks/useAuth.ts:23 — Function could be simplified (30 lines → ~15)

**i18n (WARN)**
- home.newFeature → manquant dans: es, it, de, tr

**Test Coverage (WARN)**
- apps/app/hooks/useOnboarding.ts — Nouveau hook sans fichier de test
```

### 4. Decision Logic

**If `{branch_mode}` = true:**
→ Display summary table + details for FAIL/WARN items
→ Display: "Mode branche: checks terminés, pas de push."
→ STOP workflow. No push step.

**If `{auto_mode}` = true AND `{all_passed}` = true:**
→ Display: "Auto-mode: tous les checks passent. Push en cours..."
→ Proceed directly to step-03-push.md

**If `{auto_mode}` = true AND `{all_passed}` = false:**
→ Display details
→ Use AskUserQuestion:

```yaml
questions:
  - question: "Des checks ont echoue. Que faire ?"
    options:
      - "Voir les details complets"
      - "Push quand meme (override)"
      - "Annuler"
    multiSelect: false
```

**If `{auto_mode}` = false AND `{all_passed}` = true:**
→ Use AskUserQuestion:

```yaml
questions:
  - question: "Tous les checks passent. Push sur {branch_name} ?"
    options:
      - "Push"
      - "Voir les details"
      - "Annuler"
    multiSelect: false
```

**If `{auto_mode}` = false AND `{all_passed}` = false:**
→ Display details
→ Use AskUserQuestion:

```yaml
questions:
  - question: "Des checks ont echoue ({Z} failures). Que faire ?"
    options:
      - "Voir les details complets"
      - "Push quand meme (override)"
      - "Annuler"
    multiSelect: false
```

### 5. Handle User Response

- **"Push" / "Push quand meme"** → Load step-03-push.md
- **"Voir les details" / "Voir les details complets"** → Show full agent outputs, then re-ask
- **"Annuler"** → STOP workflow. Display "Push annule."

---

## SUCCESS METRICS:

✅ Summary table displayed with all 6 checks
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
- WARN is non-blocking (refactoring suggestions, missing non-FR translations)
- FAIL is blocking (typecheck errors, test failures, rule violations, missing FR keys)
- Use AskUserQuestion, NEVER plain text "[C] Continue" prompts
</critical>
