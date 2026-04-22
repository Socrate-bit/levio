---
name: step-01b-clarify
description: Ask clarifying questions AFTER codebase analysis, informed by findings (skipped in auto_mode)
returns_to: step-01-analyze (continues to step-02-plan)
---

# Step 1b: Clarify Requirements (Post-Analysis)

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER execute this step if `{auto_mode}` = true
- 🛑 NEVER execute this step if `{qualify_mode}` = true (use step-01b-qualify instead)
- 🛑 NEVER ask more than 5 questions
- ✅ ALWAYS communicate in **French** — all questions, headers, descriptions, options
- ✅ ALWAYS use AskUserQuestion with structured options (form-style, NOT plain text)
- ✅ ALWAYS update `{task_description}` with answers
- ✅ ALWAYS leverage codebase findings from step-01 to ask INFORMED questions
- 📋 YOU ARE A CLARIFIER, not a planner
- 🚫 FORBIDDEN to suggest implementations or approaches
- 🚫 FORBIDDEN to ask questions in plain text — always use AskUserQuestion tool

## CONTEXT BOUNDARIES:

- Variables from step-00-init are available
- **Codebase analysis from step-01 is available** — use findings to ask better questions
- `{scope}` has been auto-detected but may need confirmation
- This step is OPTIONAL - only runs when `{auto_mode}` = false

## YOUR TASK:

Using the codebase context gathered in step-01, evaluate if the task description is clear enough to proceed. Ask focused, **informed** questions that reference specific patterns, files, or decisions discovered during analysis.

---

## EXECUTION SEQUENCE:

### 1. Evaluate Clarity (Informed by Analysis)

**THINK about these dimensions, using what you found in step-01:**

```
1. SCOPE CLARITY: Based on the files and patterns found, is it clear what needs to change?
   - Did analysis reveal multiple possible locations for changes?
   - Are there existing patterns that could be followed OR diverged from?

2. BEHAVIOR CLARITY: Given existing implementations found, is the expected behavior clear?
   - Does the codebase already handle similar cases? How?
   - Are there edge cases visible in existing code that apply here?

3. TECHNICAL CLARITY: Based on discovered patterns and utilities, are requirements clear?
   - Are there existing utilities/helpers that should be reused?
   - Did analysis reveal multiple valid approaches?
```

**If ALL dimensions are clear:** Skip questions, proceed directly to step-02.

**If ANY dimension is ambiguous:** Ask focused questions (max 5).

### 2. Ask Informed Clarifying Questions

Use AskUserQuestion with a structured form **in French**. Present each question as a separate AskUserQuestion call with selectable options (form-style). **Reference specific findings from analysis.**

**IMPORTANT: Use one AskUserQuestion per question, each with selectable options. This creates a form-like experience.**

Example format for each question:

```yaml
questions:
  - header: "📋 Clarification 1/3 — {topic}"
    question: |
      {Question en français référençant les fichiers/patterns trouvés}

      Par défaut je ferais : {default assumption}
    options:
      - label: "Oui, comme ça"
        description: "Procéder avec le défaut proposé"
      - label: "Non, plutôt..."
        description: "Je précise dans le champ texte"
    multiSelect: false
```

**Règles pour les questions :**
- Toujours en **français**, ton informel (tutoiement)
- Poser des questions sur le QUOI, pas le COMMENT
- **Référencer les fichiers trouvés** : "J'ai trouvé dans `src/auth/login.ts` que... — on suit le même pattern ?"
- **Proposer un défaut** quand possible : "Par défaut je ferais X, ça te va ?"
- Max 3-5 questions — moins c'est mieux
- Regrouper les questions liées

### 3. Confirm Detected Scope

If scope was auto-detected, confirm it with analysis-backed context:

```yaml
questions:
  - header: "Scope Detection"
    question: "Based on my analysis, this will affect: **{scope}**. I found related code in {list key files}. Is that correct?"
    options:
      - label: "Yes, correct"
        description: "Proceed with detected scope"
      - label: "API only"
        description: "Only backend changes needed"
      - label: "Expo only"
        description: "Only mobile app changes needed"
      - label: "Both API + Expo"
        description: "Full-stack changes needed"
      - label: "All (API + Expo + Shared)"
        description: "Changes across the entire monorepo"
    multiSelect: false
```

### 4. Update State

After receiving answers:

```
{task_description} = original description + clarifications
{scope} = confirmed or corrected scope
```

### 5. Proceed

Continue directly to `./step-02-plan.md`.

---

## SUCCESS METRICS:

✅ Questions are INFORMED by codebase analysis (reference specific files/patterns)
✅ Ambiguity identified correctly (skip if clear)
✅ Questions are focused and actionable (max 5)
✅ Used AskUserQuestion (not plain text)
✅ Task description updated with answers
✅ Scope confirmed or corrected
✅ Proceeded to step-02 without delay

## FAILURE MODES:

❌ Asking generic questions that ignore analysis findings
❌ Asking questions when task is already clear
❌ Asking implementation questions ("should I use hooks?")
❌ More than 5 questions
❌ Using plain text instead of AskUserQuestion
❌ Not updating {task_description} with answers
❌ Running this step when {auto_mode} = true
❌ Not referencing specific files or patterns discovered in step-01
