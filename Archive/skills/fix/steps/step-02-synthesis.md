---
name: step-02-synthesis
description: Cross-reference investigation results and identify root cause
prev_step: steps/step-01-investigate.md
next_step: steps/step-03-fix-proposal.md
---

# Step 2: Synthesis & Root Cause Analysis

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER propose fixes — that's step-03's job
- ✅ ALWAYS cross-reference ALL 4 agent results
- ✅ ALWAYS communicate in **French** with the user
- ✅ ALWAYS assign a confidence level to the root cause
- 📋 YOU ARE AN ANALYST, not a fixer
- 💬 FOCUS on finding the root cause from evidence
- 🚫 FORBIDDEN to write code or propose changes

## EXECUTION PROTOCOLS:

- 🎯 Analyze all 4 agent results before forming a conclusion
- 📖 Look for corroborating evidence across agents
- 🚫 FORBIDDEN to propose fixes (step-03 will)
- ✅ Present findings clearly to user before proceeding

## CONTEXT BOUNDARIES:

- `{investigation_results}` from step-01 contains all 4 agent results
- `{bug_description}` is the original user description
- Don't re-investigate — work with what agents found

## YOUR TASK:

Cross-reference the 4 investigation results to identify the definitive root cause with confidence level.

---

<available_state>

| Variable | Description |
|----------|-------------|
| `{auto_mode}` | Skip confirmations |
| `{bug_description}` | Original bug description |
| `{investigation_results}` | Results from all 4 agents |

</available_state>

---

## EXECUTION SEQUENCE:

### 1. Display Investigation Summary

```
## Investigation — "{bug_description}"

| Agent | Status | Resultat cle |
|-------|--------|-------------|
| Code Tracer | {emoji} | {one-line summary} |
| Test Runner | {emoji} | {one-line summary} |
| DB Inspector | {emoji} | {one-line summary} |
| Runtime Inspector | {emoji} | {one-line summary} |
```

Use emojis:
- Found issue / FAIL = ❌
- PASS / SKIPPED = ✅
- Partial findings = ⚠️

### 2. Cross-Reference Evidence

For each suspect identified by the Code Tracer:
- Is it confirmed by a failing test? (Test Runner)
- Is it confirmed by unexpected data? (DB Inspector)
- Is it confirmed by runtime errors? (Runtime Inspector)

Build an evidence table:

```
### Evidence croisee

| Suspect | Code Tracer | Tests | DB | Runtime | Confiance |
|---------|-------------|-------|-----|---------|-----------|
| {suspect_1} | ✅ | ✅/❌/- | ✅/❌/- | ✅/❌/- | {X}% |
| {suspect_2} | ✅ | ✅/❌/- | ✅/❌/- | ✅/❌/- | {X}% |
```

### 3. Determine Root Cause

Based on cross-referenced evidence, determine:

```
{root_cause} = {
  description: "One clear sentence describing the root cause",
  confidence: 0-100%,
  file: "path/to/file.ts",
  line: 42,
  category: "logic_error" | "race_condition" | "data_issue" | "missing_check" | "wrong_query" | "ui_state" | "config_error" | "external_service",
  evidence: ["list", "of", "supporting", "facts"]
}
```

**Confidence thresholds:**
- 90-100%: Definitive — evidence from 3+ agents
- 70-89%: Probable — evidence from 2 agents
- 50-69%: Possible — only Code Tracer suspects
- <50%: Uncertain — need more investigation

### 4. Present Root Cause

```
## Cause root identifiee

**{root_cause.description}**

- Fichier: `{root_cause.file}:{root_cause.line}`
- Categorie: {root_cause.category}
- Confiance: {root_cause.confidence}%

### Preuves
{bullet list of evidence}

### Contexte additionnel
{any relevant findings from agents that didn't directly point to root cause but add context}
```

### 5. User Decision

**If `{auto_mode}` = true:**
→ Proceed directly to step-03

**If `{auto_mode}` = false AND confidence >= 70%:**
Use AskUserQuestion:

```yaml
questions:
  - question: "Cause root identifiee avec {confidence}% de confiance. On continue vers la proposition de fix ?"
    options:
      - "Oui, propose un fix"
      - "Non, j'ai besoin de plus de details"
      - "La cause root est incorrecte — voici plus de contexte: ..."
    multiSelect: false
```

**If confidence < 70%:**
Use AskUserQuestion:

```yaml
questions:
  - question: "Confiance faible ({confidence}%). La cause root pourrait etre: {description}. Que faire ?"
    options:
      - "Continue quand meme avec cette hypothese"
      - "Lance une investigation plus profonde (-d)"
      - "Voici plus de contexte: ..."
      - "Annuler"
    multiSelect: false
```

### 6. Handle Response

- **"Oui, propose un fix"** / **"Continue"** → Load step-03
- **"Plus de details"** → Show full agent outputs
- **"Cause root incorrecte"** / **"Plus de contexte"** → Update context, re-run investigation
- **"Investigation profonde"** → Set `{deep_mode}` = true, go back to step-01
- **"Annuler"** → STOP

---

## SUCCESS METRICS:

✅ All 4 agent results cross-referenced
✅ Evidence table with confidence levels
✅ Single root cause identified with clear description
✅ Confidence level assigned based on corroboration
✅ User informed and decision captured

## FAILURE MODES:

❌ Proposing fixes (that's step-03)
❌ Ignoring agent results (not cross-referencing)
❌ Picking root cause without evidence
❌ Not showing confidence level
❌ Auto-proceeding with low confidence without asking

---

## NEXT STEP:

If user approves, load `./step-03-fix-proposal.md`

<critical>
Remember:
- You are the ANALYST — synthesize evidence, don't investigate
- Cross-reference ALL agents, not just Code Tracer
- Low confidence (< 70%) = MUST ask user before proceeding
- NEVER propose fixes — only identify the root cause
</critical>
