---
name: step-03-push
description: Execute git push to current branch
prev_step: steps/step-02-summary.md
---

# Step 3: Push

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER force push unless user explicitly chooses it
- 🛑 NEVER push to main
- 🛑 NEVER push without user confirmation (unless auto_mode + all passed)
- ✅ ALWAYS verify branch name before pushing
- ✅ ALWAYS ask confirmation before commit+push (unless auto_mode)
- ✅ ALWAYS communicate in **French** with the user
- 📋 YOU ARE A PUSHER, not a fixer
- 🚫 FORBIDDEN to make code changes

## EXECUTION PROTOCOLS:

- 🎯 Push, handle errors, show final summary
- 📖 Use `-u` flag to set upstream tracking
- 🚫 FORBIDDEN to amend commits or rebase without user consent

## CONTEXT BOUNDARIES:

- `{branch_name}` from step-00
- `{check_results}` from step-01 (for final table)
- User has already approved the push in step-02

## YOUR TASK:

Execute `git push` to the current branch and display the final summary.

---

## EXECUTION SEQUENCE:

### 1. Final Confirmation

**If `{auto_mode}` = true:**
→ Skip confirmation, proceed directly to push.

**If `{auto_mode}` = false:**
→ Use AskUserQuestion:

```yaml
questions:
  - question: "Pret a push sur {branch_name} ?"
    options:
      - "Oui, push"
      - "Annuler"
    multiSelect: false
```

If user chooses "Annuler" → STOP workflow.

### 2. Execute Push

```bash
git push -u origin {branch_name}
```

### 3. Handle Push Result

**If push succeeds:**
→ Go to step 3 (final summary)

**If push fails (diverged/rejected):**
→ Use AskUserQuestion:

```yaml
questions:
  - question: "Le push a echoue (branche divergente). Que faire ?"
    options:
      - "Pull --rebase puis re-push"
      - "Force push (ecrase le remote)"
      - "Annuler"
    multiSelect: false
```

- **"Pull --rebase puis re-push":**
  ```bash
  git pull --rebase origin {branch_name} && git push -u origin {branch_name}
  ```
  If rebase conflicts → STOP, tell user to resolve manually.

- **"Force push":**
  ```bash
  git push -u origin {branch_name} --force-with-lease
  ```

- **"Annuler":** → STOP workflow.

### 4. Display Final Summary

```
Push OK — {branch_name}

| # | Check             | Status |
|---|-------------------|--------|
| 1 | PR Mission        | {s}    |
| 2 | Refactoring       | {s}    |
| 3 | Rules Compliance  | {s}    |
| 4 | Typecheck & Tests | {s}    |
| 5 | i18n              | {s}    |
| 6 | Test Coverage     | {s}    |
| 7 | Push              | DONE   |
```

---

## SUCCESS METRICS:

✅ Push executed successfully
✅ Final summary table displayed
✅ Push errors handled gracefully (rebase/force/cancel options)
✅ Used `--force-with-lease` (not `--force`) for safety

## FAILURE MODES:

❌ Force pushing without user consent
❌ Pushing to main
❌ Not handling push rejection
❌ Using `--force` instead of `--force-with-lease`

---

## WORKFLOW COMPLETE

<critical>
Remember:
- Use `--force-with-lease` (not `--force`) — it's safer
- NEVER push to main
- If rebase has conflicts, STOP and let user resolve
- Keep the final table compact — one glance tells the story
</critical>
