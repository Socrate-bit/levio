---
name: step-01b-qualify
description: Deep requirements qualification AFTER codebase analysis — structured questioning to build a complete brief before planning
next_step: steps/step-02-plan.md
---

# Step 1b: Qualify — Deep Requirements Qualification

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER skip this step — it is MANDATORY when `{qualify_mode}` = true (even if `{auto_mode}` = true)
- ✅ ALWAYS communicate in **English**
- ✅ ALWAYS use AskUserQuestion with structured options — NEVER plain text prompts
- ✅ ALWAYS reference specific files, patterns, and findings from step-01 analysis
- ✅ ALWAYS build a structured brief from answers
- ✅ ALWAYS get user confirmation on the final brief before proceeding
- 📋 YOU ARE A REQUIREMENTS QUALIFIER, not a planner or implementer
- 🚫 FORBIDDEN to suggest HOW to implement — only ask about WHAT and WHY
- 🚫 FORBIDDEN to proceed to step-02 without user-confirmed brief

## CONTEXT BOUNDARIES:

- All variables from step-00-init are available
- **Codebase analysis from step-01 is complete** — use findings to ask precise questions
- `{scope}` has been auto-detected
- This step REPLACES step-01b-clarify when `{qualify_mode}` = true

## YOUR TASK:

Using the codebase context from step-01, conduct a structured qualification of the user's need. Ask precise questions that reference what you found in the code to eliminate ambiguity and build a complete brief before planning.

---

## EXECUTION SEQUENCE:

### 1. Analyze What You Know vs What's Missing

**ULTRA THINK about the task using step-01 findings:**

```
Given {task_description} and what I found in the codebase:

1. WHAT I KNOW FOR SURE:
   - What the user explicitly asked for
   - What patterns exist in the codebase (from analysis)
   - What files/code are related

2. WHAT I'M UNSURE ABOUT:
   - Ambiguous behavior expectations
   - Edge cases the user may not have considered
   - Choices between multiple valid approaches found in the codebase
   - Scope boundaries (what's included vs excluded)
   - Impact on existing features

3. WHAT COULD GO WRONG IF I ASSUME:
   - Misunderstanding the expected UX flow
   - Building the wrong thing because scope is fuzzy
   - Missing a critical requirement
   - Breaking existing behavior
```

From this analysis, craft **targeted questions** — each one addressing a specific gap.

### 2. Ask Structured Questions (3-8 questions)

Ask questions one at a time using AskUserQuestion. Each question MUST:
- Reference specific codebase findings from step-01
- Propose a default when possible
- Focus on WHAT/WHY, never HOW

**Question categories to cover:**

#### A. Expected behavior (mandatory)
```yaml
- header: "🎯 Behavior — {aspect}"
  question: |
    I found in `{file:line}` that {existing_behavior}.

    For your feature, what happens when {specific_scenario}?

    By default I'd go with: {default_assumption}
  options:
    - label: "Yes, like that"
      description: "{default description}"
    - label: "No, rather..."
      description: "I'll specify"
    - label: "{alternative grounded in code}"
      description: "{description}"
  freeformLabel: "Another behavior..."
```

#### B. Scope (mandatory)
```yaml
- header: "📐 Scope"
  question: |
    Based on my analysis, this touches:
    - `{file1}` — {what it does}
    - `{file2}` — {what it does}

    Detected scope: **{scope}**

    Correct? Anything to add or exclude?
  options:
    - label: "Correct"
      description: "Scope is good"
    - label: "Broader"
      description: "Things are missing"
    - label: "Narrower"
      description: "Too wide"
  freeformLabel: "Details..."
```

#### C. Edge cases (if relevant)
```yaml
- header: "⚠️ Edge cases"
  question: |
    I saw in `{file:line}` that {existing_edge_case_handling}.

    For your feature, what happens if {edge_case}?
  options:
    - label: "{option1}"
      description: "{description}"
    - label: "{option2}"
      description: "{description}"
    - label: "Not handled for now"
      description: "MVP — we'll revisit later"
  freeformLabel: "Other..."
```

#### D. UX / Interaction (if UI involved)
```yaml
- header: "📱 Interaction"
  question: |
    I found that {existing_screen_or_widget} does {behavior}.

    For your feature, how does the user interact?
  options:
    - label: "{option grounded in existing patterns}"
      description: "Like {existing_feature}"
    - label: "{alternative}"
      description: "{description}"
  freeformLabel: "Other flow..."
```

#### E. Data / Firestore (if service concerned)
```yaml
- header: "🗄️ Data"
  question: |
    The Firestore schema in `CLAUDE.md` has:
    `users/{uid}/alarms/{alarmId}` with fields {existing_fields}.

    For your feature, what data is needed?
  options:
    - label: "Existing data is enough"
      description: "No schema change"
    - label: "Need to add fields to existing doc"
      description: "I'll specify which"
    - label: "New subcollection or root collection"
      description: "I'll describe the structure"
  freeformLabel: "Details..."
```

**Rules:**
- Minimum 3 questions, maximum 8
- Every question MUST reference code found in step-01
- Always propose a reasonable default
- Group related questions when possible
- NEVER ask about implementation details

### 3. Build the Brief

Synthesize all answers into a structured brief:

```markdown
## 📋 Brief — {feature_name}

### Need
{One-line summary of the need}

### Expected behavior
- When {trigger}, then {behavior}
- If {condition}, then {behavior}
- Edge case: {edge_case} → {handling}

### Confirmed scope
- **{scope}** : {files/areas concerned}
- Included: {what's in}
- Excluded: {what's out}

### Acceptance criteria
- [ ] AC1: {measurable criterion}
- [ ] AC2: {measurable criterion}
- [ ] AC3: {measurable criterion}

### Constraints
- {constraints mentioned by the user}
```

### 4. Confirm the Brief

Display the brief and ask for confirmation:

```yaml
- header: "📋 Final brief"
  question: |
    {display full brief}

    Is this brief correct? I'll move on to the implementation plan.
  options:
    - label: "Looks good, go!"
      description: "Move to plan"
    - label: "I'd like to change something"
      description: "Revisit a detail"
  freeformLabel: "Adjustments..."
```

If the user wants to edit → fix the point, re-confirm.

### 5. Update State

```
{task_description} = full brief (replaces the initial description)
{acceptance_criteria} = criteria extracted from the brief
{scope} = confirmed scope
```

### 6. Proceed

→ Continue to `./step-02-plan.md`

---

## SUCCESS METRICS:

✅ Each question references code from step-01 (file:line)
✅ Questions about WHAT/WHY, never HOW
✅ Structured brief built from answers
✅ Brief confirmed by the user before continuing
✅ {task_description} updated with the full brief
✅ {acceptance_criteria} defined and validated
✅ Scope confirmed or corrected
✅ Used AskUserQuestion (no plain text)
✅ English

## FAILURE MODES:

❌ Asking generic questions without referencing code
❌ Asking implementation questions ("which Cubit method?")
❌ Proceeding without user-confirmed brief
❌ Fewer than 3 questions (not deep enough)
❌ More than 8 questions (too long)
❌ No default proposed for each question
❌ Using plain text instead of AskUserQuestion
❌ Not updating {task_description} with the brief

---

## NEXT STEP:

After brief confirmed → Load `./step-02-plan.md`

<critical>
Remember:
- This step is about UNDERSTANDING what the user wants, not deciding how to build it
- Every question MUST be grounded in codebase findings from step-01
- The brief is a CONTRACT — don't proceed without confirmation
- This replaces step-01b-clarify when qualify_mode is true
</critical>
