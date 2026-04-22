---
name: step-00-init
description: Initialize push workflow - parse flags, detect branch, gather diff context
next_step: steps/step-01-parallel-checks.md
---

# Step 0: Initialization

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER skip branch detection
- 🛑 NEVER proceed if on `main` branch
- ✅ ALWAYS parse ALL flags before any other action
- ✅ ALWAYS communicate in **English** with the user
- ✅ ALWAYS gather diff context ONCE here (shared with all agents)
- 📋 YOU ARE AN INITIALIZER, not a checker
- 💬 FOCUS on setup only — don't analyze code
- 🚫 FORBIDDEN to load step-01 until init is complete

## EXECUTION PROTOCOLS:

- 🎯 Parse flags first, then detect branch, then gather context
- 📖 Initialize all state variables before proceeding
- 🚫 FORBIDDEN to start any checks (that's step-01's job)
- ✅ ALWAYS show COMPACT summary (one table) and proceed immediately
- 🚫 FORBIDDEN to show verbose parsing logs or explanations

## CONTEXT BOUNDARIES:

- This is the FIRST step — no previous context exists
- User input may contain flags (-a, -f)
- Don't analyze code — just gather diff data

## YOUR TASK:

Initialize the push workflow by parsing flags, detecting the current branch, verifying PR exists, and gathering diff context for the parallel check agents.

---

<defaults>

```yaml
auto_mode: false    # -a: Skip confirmations, auto-push if all pass
fix_mode: false     # -f: Agents propose fixes alongside findings
branch_mode: false  # -b: Check entire branch diff, no push, no commit check
```

</defaults>

---

## EXECUTION SEQUENCE:

### 1. Parse Flags and Input

```
Enable flags (lowercase ON):
  -a or --auto    → {auto_mode} = true
  -f or --fix     → {fix_mode} = true
  -b or --branch  → {branch_mode} = true

Disable flags (UPPERCASE OFF):
  -A or --no-auto    → {auto_mode} = false
  -F or --no-fix     → {fix_mode} = false
  -B or --no-branch  → {branch_mode} = false
```

### 2. Check for Uncommitted Changes

**Skip this step entirely if `{branch_mode}` = true** (branch mode doesn't push, so uncommitted changes don't matter).

```bash
git status --porcelain
```

**If there are uncommitted changes (staged or unstaged):**

Show the list of modified files, then use AskUserQuestion:

```yaml
questions:
  - question: "Tu as des modifications non commitees. On commit avant de continuer ?"
    options:
      - "Oui, commit tout"
      - "Non, continuer sans commit"
      - "Annuler"
    multiSelect: false
```

**If `{auto_mode}` = true:**
→ Auto-commit with message: `chore: wip changes before push`

**If user chooses "Oui, commit tout":**
```bash
git add -A && git commit -m "chore: wip changes before push"
```

**If user chooses "Non, continuer sans commit":**
→ Continue (changes stay unstaged, won't be pushed)

**If user chooses "Annuler":**
→ STOP workflow.

### 3. Detect Current Branch

```bash
git branch --show-current
```

Store as `{branch_name}`.

**If on `main`:**
→ STOP. Tell user: "Tu es sur main. Change de branche avant de push."

### 4. Detect Base Branch

```bash
gh pr view --json baseRefName 2>/dev/null
```

- **If PR exists:** store baseRefName as `{base_branch}`
- **If no PR:** `{base_branch}` = "main"

### 5. Verify Commits to Push

**If `{branch_mode}` = true:** Skip this check entirely — branch mode checks the full branch diff regardless of what's already pushed.

```bash
git log origin/{branch_name}..HEAD --oneline 2>/dev/null
```

**If no commits AND `{branch_mode}` = false:** → STOP. Tell user: "Rien a push."

### 6. Gather Diff Context (shared with all agents)

Run these 3 commands and store results:

```bash
# Full diff against base branch
git diff {base_branch}...HEAD
```
Store as `{diff_content}`

```bash
# Changed file list
git diff {base_branch}...HEAD --name-only
```
Store as `{changed_files}`

```bash
# Commit messages
git log {base_branch}..HEAD --oneline
```
Store as `{commit_messages}`

### 7. Show Summary and Proceed

Display COMPACT initialization summary:

```
/push: {branch_name} → {base_branch} {if branch_mode: "(check only, no push)"}

| Variable | Value |
|----------|-------|
| auto_mode | true/false |
| fix_mode | true/false |
| branch_mode | true/false |
| Commits | {count} commits |
| Fichiers | {count} fichiers modifies |

→ Lancement des checks...
```

Then IMMEDIATELY proceed to step-01.

---

## SUCCESS METRICS:

✅ All flags correctly parsed
✅ Branch detected, not on main
✅ PR status known
✅ Diff context gathered (one time, not repeated by agents)
✅ Output is COMPACT (one table, no verbose logs)
✅ Proceeded to step-01 immediately

## FAILURE MODES:

❌ Running on `main` without stopping
❌ Not gathering diff context (agents will re-run git commands)
❌ Verbose output with explanations
❌ Blocking with unnecessary confirmations

---

## NEXT STEP:

After showing summary, proceed directly to `./step-01-parallel-checks.md`

<critical>
Remember:
- Step-00 is an INITIALIZER, not a CHECKER
- Gather diff ONCE here — agents will receive it in their prompts
- Output MUST be compact: one table, proceed immediately
- NEVER proceed if on main or if no commits to push
</critical>
