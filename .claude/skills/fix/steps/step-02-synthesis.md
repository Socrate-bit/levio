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
- ✅ ALWAYS communicate in **English** with the user
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

| Agent | Status | Key result |
|-------|--------|------------|
| Code Tracer        | {emoji} | {one-line summary} |
| Test Runner        | {emoji} | {one-line summary} |
| Firestore Inspector| {emoji} | {one-line summary} |
| PostHog Inspector  | {emoji} | {one-line summary} |
```

Use emojis:
- Found issue / FAIL = ❌
- PASS / SKIPPED = ✅
- Partial findings / NEEDS_MANUAL_CHECK = ⚠️

### 2. Cross-Reference Evidence

For each suspect identified by the Code Tracer:
- Is it confirmed by a failing test? (Test Runner)
- Is it confirmed by an expected/actual shape mismatch? (Firestore Inspector)
- Is it confirmed by runtime exceptions / missing events? (PostHog Inspector)

Build an evidence table:

```
### Cross-referenced evidence

| Suspect | Code Tracer | Tests | Firestore | PostHog | Confidence |
|---------|-------------|-------|-----------|---------|------------|
| {suspect_1} | ✅ | ✅/❌/- | ✅/❌/- | ✅/❌/- | {X}% |
| {suspect_2} | ✅ | ✅/❌/- | ✅/❌/- | ✅/❌/- | {X}% |
```

### 3. Determine Root Cause

Based on cross-referenced evidence, determine:

```
{root_cause} = {
  description: "One clear sentence describing the root cause",
  confidence: 0-100%,
  file: "lib/features/<feature>/cubit/<name>_cubit.dart",
  line: 42,
  category: "logic_error" | "race_condition" | "data_issue" | "missing_check" | "firestore_shape" | "firestore_query" | "ui_state" | "config_error" | "external_service" | "native_bridge",
  evidence: ["list", "of", "supporting", "facts"]
}
```

**Confidence thresholds:**
- 90-100%: Definitive — evidence from 3+ agents
- 70-89%: Probable — evidence from 2 agents
- 50-69%: Possible — only Code Tracer suspects
- <50%: Uncertain — needs more investigation

### 4. Present Root Cause

```
## Root cause identified

**{root_cause.description}**

- File: `{root_cause.file}:{root_cause.line}`
- Category: {root_cause.category}
- Confidence: {root_cause.confidence}%

### Evidence
{bullet list of evidence}

### Additional context
{any relevant findings from agents that don't directly point to the root cause but add context}
```

### 5. User Decision

**If `{auto_mode}` = true:**
→ Proceed directly to step-03

**If `{auto_mode}` = false AND confidence >= 70%:**
Use AskUserQuestion:

```yaml
questions:
  - question: "Root cause identified with {confidence}% confidence. Continue to fix proposal?"
    options:
      - "Yes, propose a fix"
      - "No, I need more details"
      - "The root cause is wrong — here is more context: ..."
    multiSelect: false
```

**If confidence < 70%:**
Use AskUserQuestion:

```yaml
questions:
  - question: "Low confidence ({confidence}%). Root cause could be: {description}. What now?"
    options:
      - "Continue with this hypothesis anyway"
      - "Run a deeper investigation (-d)"
      - "Here is more context: ..."
      - "Cancel"
    multiSelect: false
```

### 6. Handle Response

- **"Yes, propose a fix"** / **"Continue"** → Load step-03
- **"More details"** → Show full agent outputs
- **"Root cause is wrong"** / **"More context"** → Update context, re-run investigation
- **"Deeper investigation"** → Set `{deep_mode}` = true, go back to step-01
- **"Cancel"** → STOP

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
