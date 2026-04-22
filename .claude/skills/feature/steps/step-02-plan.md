---
name: step-02-plan
description: Strategic planning - create detailed file-by-file implementation strategy
prev_step: steps/step-01-analyze.md
next_step: steps/step-03-execute.md
---

# Step 2: Plan (Strategic Design)

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER start implementing - that's step 3
- 🛑 NEVER write or modify code in this step
- ✅ ALWAYS structure plan by FILE, not by feature
- ✅ ALWAYS include specific line numbers from analysis
- ✅ ALWAYS map acceptance criteria to file changes
- ✅ ALWAYS create a TaskList using TaskCreate tool to track all planned file changes
- 📋 YOU ARE A PLANNER, not an implementer
- 💬 FOCUS on "What changes need to be made where?"
- 🚫 FORBIDDEN to use Edit, Write, or Bash tools

## EXECUTION PROTOCOLS:

- 🎯 ULTRA THINK before creating the plan
- 💾 Save plan to output file (if save_mode)
- 📖 Reference patterns from step-01 analysis
- 🚫 FORBIDDEN to proceed until user approves plan (unless auto_mode)

## CONTEXT BOUNDARIES:

- Context from step-01 (files, patterns, utilities) is available
- Implementation has NOT started
- User has NOT approved any changes yet
- Plan must be complete before execution

## YOUR TASK:

Transform analysis findings into a comprehensive, executable, file-by-file implementation plan.

---

<available_state>
From previous steps:

| Variable | Description |
|----------|-------------|
| `{task_description}` | What to implement |
| `{task_id}` | Kebab-case identifier |
| `{acceptance_criteria}` | Success criteria from step-01 |
| `{auto_mode}` | Skip confirmations |
| `{save_mode}` | Save outputs to files |
| `{output_dir}` | Path to output (if save_mode) |
| Files found | From step-01 codebase exploration |
| Patterns | From step-01 pattern analysis |
| Utilities | From step-01 utility discovery |
</available_state>

---

## EXECUTION SEQUENCE:

### 1. Initialize Save Output (if save_mode)

**If `{save_mode}` = true:**

```bash
bash {skill_dir}/scripts/update-progress.sh "{task_id}" "02" "plan" "in_progress"
```

Append plan to `{output_dir}/02-plan.md` as you work.

### 2. ULTRA THINK: Design Complete Strategy

**CRITICAL: Think through ENTIRE implementation before writing any plan.**

Mental simulation:
- Walk through the implementation step by step
- Identify all files that need changes
- Determine logical order (dependencies first)
- Consider edge cases and error handling
- Plan test coverage

### 3. Clarify Ambiguities

**If `{auto_mode}` = true:**
→ Use recommended option for any ambiguity, proceed automatically

**If `{auto_mode}` = false AND multiple valid approaches exist:**

```yaml
questions:
  - header: "Approach"
    question: "Multiple approaches are possible. Which should we use?"
    options:
      - label: "Approach A (Recommended)"
        description: "Description and tradeoffs of A"
      - label: "Approach B"
        description: "Description and tradeoffs of B"
      - label: "Approach C"
        description: "Description and tradeoffs of C"
    multiSelect: false
```

### 4. Create Detailed Plan

**Structure by FILE, not by feature:**

```markdown
## Implementation Plan: {task_description}

### Overview
[1-2 sentences: High-level strategy and approach]

### Prerequisites
- [ ] Prerequisite 1 (if any)
- [ ] Prerequisite 2 (if any)

---

### File Changes

#### `lib/features/<feature>/cubit/<feature>_cubit.dart`
- Add `methodName` that handles X
- Emit state transitions (follow pattern in `alarm_cubit.dart:45`)
- Handle error case: [specific scenario, with `[<Feature>Cubit]` debugPrint]
- Consider: [edge case — stream subscription lifecycle, optimistic rollback]

#### `lib/features/<feature>/screens/<feature>_screen.dart`
- Wrap screen in `BlocBuilder<<Feature>Cubit, <Feature>State>`
- Wire cubit method to user interaction at line ~42
- Update any dependent widgets

#### `lib/features/<feature>/models/<model>.dart` (NEW FILE)
- Create `Equatable` model
- Fields: [fieldA, fieldB]
- Pattern: follow `lib/features/alarms/models/alarm.dart`

---

### Testing Strategy

**New tests:**
- `test/features/<feature>/<feature>_cubit_test.dart` - Test methodName with:
  - Initial state
  - Happy path (state transition sequence)
  - Error path with optimistic rollback

**Update existing:**
- `test/features/<feature>/<feature>_service_test.dart` - Add test for new flow

---

### Acceptance Criteria Mapping
- [ ] AC1: Satisfied by changes in `<feature>_cubit.dart`
- [ ] AC2: Satisfied by changes in `<feature>_screen.dart`

---

### Risks & Considerations
- Risk 1: [potential issue and mitigation]
```

**If `{save_mode}` = true:** Append full plan to 02-plan.md

### 5. Create Task List (MANDATORY)

<critical>
You MUST create a TaskList using TaskCreate for every planned change.
This is NOT optional - the task list tracks progress through execution.
</critical>

**Create one task per file change from the plan:**

For each file in the plan, call `TaskCreate` with:
- **subject**: `{action} {filepath}` (e.g., "Add validateToken to lib/features/auth/services/auth_service.dart")
- **description**: The full details of what changes are needed for this file, including specific functions, patterns to follow, and line references
- **activeForm**: Present continuous form (e.g., "Adding validateToken to auth_service.dart")

**Then set up dependencies using `TaskUpdate`:**
- If file B depends on file A (e.g., B imports from A), use `addBlockedBy` to mark the dependency
- This ensures execution follows the correct order

**Example:**
```
TaskCreate: "Create auth models in lib/features/auth/models/auth_token.dart"
  → description: "Create AuthToken Equatable model and ValidateResult class. Follow pattern from lib/features/alarms/models/alarm.dart"
  → activeForm: "Creating auth models"

TaskCreate: "Add validateToken to lib/features/auth/services/auth_service.dart"
  → description: "Add validateToken method returning ValidateResult. Handle expired token error case with debugPrint('[AuthService] ...')."
  → activeForm: "Adding validateToken to auth_service"
  → Then: TaskUpdate with addBlockedBy: [auth-models-task-id]
```

### 6. Verify Plan Completeness

Checklist:
- [ ] All files identified - nothing missing
- [ ] Logical order - dependencies handled first
- [ ] Clear actions - every step specific and actionable
- [ ] Test coverage - all paths have test strategy
- [ ] In scope - no scope creep
- [ ] AC mapped - every criterion has implementation
- [ ] **TaskList created with all file changes**
- [ ] **Task dependencies set correctly**

### 7. Brainstorm Uncertainty Points

<critical>
Before proceeding, THINK about what you're NOT 100% certain about.
DO NOT ask generic "is this plan good?" questions.
Instead, identify SPECIFIC uncertainties and ask TARGETED questions.
</critical>

**ULTRA THINK: Identify Uncertainties**

For each aspect of the plan, rate your confidence (High/Medium/Low):

```markdown
## Uncertainty Analysis

| Aspect | Confidence | Uncertainty |
|--------|------------|-------------|
| File locations correct? | High/Medium/Low | [What's unclear] |
| Patterns match codebase? | High/Medium/Low | [What's unclear] |
| Dependencies complete? | High/Medium/Low | [What's unclear] |
| Error handling approach? | High/Medium/Low | [What's unclear] |
| User expectations for X? | High/Medium/Low | [What's unclear] |
| Technical approach for Y? | High/Medium/Low | [What's unclear] |
```

**Identify TOP 1-4 uncertainties with Low or Medium confidence.**

These are the ONLY things worth asking about.

---

### 8. Ask Smart Questions (if not auto_mode)

**If `{auto_mode}` = true:**
→ Skip questions, use your best judgment, proceed directly

**If `{auto_mode}` = false AND you have uncertainties:**

<critical>
ONLY ask questions about things where:
1. Multiple valid approaches exist AND the choice significantly impacts implementation
2. User intent is genuinely ambiguous from the task description
3. A wrong assumption could cause significant rework

DO NOT ask about:
- Implementation details you can decide yourself
- Things you're "slightly unsure" about (just decide)
- Generic plan approval (never ask "is this plan good?")
</critical>

**Question Types to Use:**

**Type 1: Behavior Clarification**
When user intent is genuinely unclear:
```yaml
questions:
  - header: "Behavior"
    question: "When [specific scenario], should the system [option A] or [option B]?"
    options:
      - label: "[Option A] (Recommended)"
        description: "[What A does and why it might be preferred]"
      - label: "[Option B]"
        description: "[What B does and when it's better]"
    multiSelect: false
```

**Type 2: Scope Clarification**
When scope boundaries are unclear:
```yaml
questions:
  - header: "Scope"
    question: "Should we also [related thing] as part of this, or keep it focused on [core thing]?"
    options:
      - label: "Keep focused (Recommended)"
        description: "Only do [core thing], faster implementation"
      - label: "Include [related thing]"
        description: "More complete but expands scope"
    multiSelect: false
```

**Type 3: Technical Choice**
When multiple valid technical approaches exist:
```yaml
questions:
  - header: "Approach"
    question: "For [specific technical decision], we can use [approach A] or [approach B]. Which fits your needs?"
    options:
      - label: "[Approach A] (Recommended)"
        description: "[Tradeoffs of A - e.g., simpler but less flexible]"
      - label: "[Approach B]"
        description: "[Tradeoffs of B - e.g., more complex but extensible]"
    multiSelect: false
```

**Type 4: Edge Case Handling**
When edge case behavior is unclear:
```yaml
questions:
  - header: "Edge case"
    question: "If [edge case scenario] occurs, should we [behavior A] or [behavior B]?"
    options:
      - label: "[Behavior A] (Recommended)"
        description: "[What happens with A]"
      - label: "[Behavior B]"
        description: "[What happens with B]"
    multiSelect: false
```

**If you have 0 uncertainties worth asking about:**
→ Proceed directly to execution without asking anything

**Example of GOOD questions:**
- "When a user submits invalid email format, should we show inline validation or only validate on submit?"
- "Should the loading state show a spinner on the button or a full-page skeleton?"
- "For rate limiting, should we limit per user or per IP address?"

**Example of BAD questions (NEVER ask these):**
- ❌ "Does this plan look good to you?"
- ❌ "Ready to proceed with implementation?"
- ❌ "Should I use async/await or promises?" (just decide)
- ❌ "Is the file structure correct?" (you already verified)

---

### 9. Present Plan Summary

```
**Implementation Plan Ready**

**Overview:** [1 sentence summary]

**Files to modify:** {count} files
**New files:** {count} files
**Tests:** {count} test files

**Key decisions made:**
- [Decision 1 from user responses or auto-decided]
- [Decision 2 from user responses or auto-decided]

**Estimated changes:**
- `<feature>_cubit.dart` - Major changes (add method, state transitions, error handling)
- `<feature>_screen.dart` - Minor changes (wire cubit call)
- `<feature>_cubit_test.dart` - New test file

→ Proceeding to implementation...
```

### 10. Complete Save Output (if save_mode)

**If `{save_mode}` = true:**

Append to `{output_dir}/02-plan.md`:
```markdown
---
## Step Complete
**Status:** ✓ Complete
**Files planned:** {count}
**Tests planned:** {count}
**Uncertainties resolved:** {count}
**Next:** step-03-execute.md
**Timestamp:** {ISO timestamp}
```

---

## SUCCESS METRICS:

✅ Complete file-by-file plan created
✅ Logical dependency order established
✅ All acceptance criteria mapped to changes
✅ Test strategy defined
✅ **TaskList created with TaskCreate for every file change**
✅ **Task dependencies set with TaskUpdate (addBlockedBy)**
✅ Uncertainty points identified and addressed
✅ Smart, targeted questions asked (if not auto_mode and uncertainties exist)
✅ NO code written or modified
✅ Output saved (if save_mode)

## FAILURE MODES:

❌ Organizing by feature instead of file
❌ Vague actions like "add feature" or "fix issue"
❌ Missing test strategy
❌ Not mapping to acceptance criteria
❌ Starting to write code (that's step 3!)
❌ **CRITICAL**: Not creating a TaskList with TaskCreate
❌ **CRITICAL**: Asking generic "is this plan good?" questions
❌ **CRITICAL**: Asking about implementation details you can decide yourself
❌ **CRITICAL**: Not brainstorming uncertainties before asking questions

## PLANNING PROTOCOLS:

- Structure by FILE - each file is a section
- Include line number references from analysis
- Every action must be specific and actionable
- Map every AC to specific file changes
- Plan tests alongside implementation

---

## NEXT STEP:

After user approves via AskUserQuestion (or auto-proceed):

**If `{tasks_mode}` = true OR `{teams_mode}` = true:**
→ Load `./step-02b-tasks.md` to generate task breakdown with dependencies

**If `{teams_mode}` = true (after task breakdown):**
→ Flow continues to `./step-03-execute-teams.md` for Agent Team parallel execution

**Otherwise:**
→ Load `./step-03-execute.md` to start implementation

<critical>
Remember: Planning is ONLY about designing the approach - save all implementation for step-03!
</critical>
