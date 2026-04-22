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
- ✅ ALWAYS communicate in **French** with the user
- ✅ ALWAYS respect project rules (.claude/rules/*.md)
- 📋 YOU ARE A PROPOSAL WRITER, not a coder
- 💬 FOCUS on clear, precise, minimal changes
- 🚫 FORBIDDEN to use Edit, Write, or Bash tools

## EXECUTION PROTOCOLS:

- 🎯 Read the file(s) to modify to get exact current code
- 📖 Propose the minimum change that fixes the root cause
- 🚫 FORBIDDEN to refactor adjacent code or add features
- ✅ Check that the fix respects ALL project rules

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
- Respects project rules:
  - `typescript.md` — no `as any`, no `eslint-disable`, correct import extensions
  - `expo.md` — no className on Animated, correct imports
  - `api.md` — ownership checks, correct error codes
  - `drizzle.md` — correct column conventions
  - `i18n.md` — French translations only

### 3. Present Fix Proposal

```
## Proposition de fix

### Cause root
{root_cause.description}

### Fichier(s) a modifier

#### `{file_path}` (lignes {start}-{end})

**Avant:**
```{lang}
{exact current code}
```

**Apres:**
```{lang}
{proposed fix code}
```

### Explication
{1-2 sentences explaining WHY this fix works}

### Impact
- Fichiers modifies: {count}
- Lignes changees: ~{count}
- Risque de regression: faible/moyen/eleve
- Tests a ajouter: {yes/no — description si oui}
```

### 4. Side Effects Check

List any potential side effects:

```
### Effets de bord potentiels
- {effect_1} — risque: faible/moyen/eleve
- (aucun si le fix est isole)
```

### 5. Test Recommendation

If the bug wasn't covered by existing tests:

```
### Test recommande
Un test devrait verifier que:
- {test case description}

Fichier: `{test_file_path}`
Pattern a suivre: voir {existing_similar_test}
```

### 6. User Decision

**If `{auto_mode}` = true:**
→ Display the fix proposal and end workflow.
→ Tell user: "Fix propose. Lance `/fix` avec `-f` pour l'appliquer automatiquement (feature a venir)."

**If `{auto_mode}` = false:**
Use AskUserQuestion:

```yaml
questions:
  - question: "Fix propose. Que faire ?"
    options:
      - "Le fix est bon — je l'applique moi-meme"
      - "Modifier le fix — voici mes retours: ..."
      - "Annuler"
    multiSelect: false
```

### 7. Handle Response

- **"Le fix est bon"** → End workflow. Display: "Diagnostic termine. Applique le fix manuellement ou demande-moi de le faire."
- **"Modifier le fix"** → Adjust based on feedback, re-present
- **"Annuler"** → End workflow

---

## SUCCESS METRICS:

✅ Current code read (not guessed)
✅ Fix is minimal — addresses ONLY the root cause
✅ Before/after code shown with exact syntax
✅ Project rules respected in proposed code
✅ Side effects identified
✅ Test recommendation if gap found
✅ Fix NOT applied (proposal only)

## FAILURE MODES:

❌ Applying the fix (using Edit/Write tools)
❌ Proposing code without reading current state
❌ Over-engineering the fix (refactoring, adding features)
❌ Ignoring project rules (wrong import extensions, type casts)
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
- Check project rules before proposing
</critical>
