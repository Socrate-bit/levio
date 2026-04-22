---
name: fix
description: Bug diagnosis — launches 4 agents in parallel (code tracer, test runner, Firestore inspector, PostHog inspector) then proposes a fix. Use when investigating bugs, runtime errors, unexpected behavior, or data issues.
argument-hint: "<bug description> [-a] [-d]"
---

<objective>
Diagnose a user-reported bug by launching 4 investigation agents in parallel, then propose a precise fix without applying it.
</objective>

<quick_start>

```bash
/fix "the share button crashes on iOS"           # Interactive
/fix -a "onboarding skips step 3"                # Auto — propose the fix directly
/fix -d "XP no longer increments"                # Deep — exhaustive investigation
```

</quick_start>

<flags>

| ON | OFF | Long | Description |
|----|-----|------|-------------|
| `-a` | `-A` | `--auto` | Skip confirmations, propose fix directly |
| `-d` | `-D` | `--deep` | Exhaustive investigation (more agents, more context) |

**Parsing:** Defaults all false. First positional argument = bug description.

</flags>

<workflow>

1. **Init** — Parse flags, understand the bug, identify scope (relevant files/modules)
2. **Parallel Investigation** — Launch 4 agents simultaneously:
   - Code Tracer: traces execution path, looks for the root cause
   - Test Runner: runs tests in scope, analyzes failures
   - Firestore Inspector: maps expected doc shape against code (no SQL — Firestore is schemaless; reads `CLAUDE.md` + Cubits/services)
   - PostHog Inspector: checks exceptions, events, sessions for a specific user via the PostHog REST API
3. **Synthesis** — Cross-references the 4 agent outputs, identifies the root cause
4. **Fix Proposal** — Proposes a precise fix with the code to change (without applying it)

</workflow>

<step_files>

| Step | File | Purpose |
|------|------|---------|
| 00 | `steps/step-00-init.md` | Parse flags, understand the bug, identify scope |
| 01 | `steps/step-01-investigate.md` | Launch 4 investigation agents in parallel |
| 02 | `steps/step-02-synthesis.md` | Cross-reference results, identify root cause |
| 03 | `steps/step-03-fix-proposal.md` | Propose the fix with precise code |

</step_files>

<state_variables>

| Variable | Type | Set by |
|----------|------|--------|
| `{auto_mode}` | boolean | step-00 |
| `{deep_mode}` | boolean | step-00 |
| `{bug_description}` | string | step-00 |
| `{scope_files}` | string | step-00 |
| `{scope_modules}` | string | step-00 |
| `{related_tests}` | string | step-00 |
| `{needs_firestore}` | boolean | step-00 |
| `{needs_posthog}` | boolean | step-00 |
| `{posthog_email}` | string | step-00 |
| `{investigation_results}` | object | step-01 |
| `{root_cause}` | string | step-02 |
| `{fix_proposal}` | object | step-03 |

</state_variables>

<mcp_tools>

Agents can use these tools depending on context:

| Tool | Usage | When |
|------|-------|------|
| Bash + Firebase Console (manual) | Firestore inspection — schema lives in `CLAUDE.md` (section Firestore Schema), agent maps expected doc shape against code | When `{needs_firestore}` = true |
| `posthog` (REST API) | Exceptions, events, sessions for a user | When `{needs_posthog}` = true and `POSTHOG_API_KEY` is set |

</mcp_tools>

<execution_rules>

- **Load one step at a time** (progressive loading)
- **Persist state variables** across all steps
- **Follow next_step directive** at end of each step
- **Launch ALL 4 agents in ONE message** for true parallelism
- **NEVER apply the fix** — propose only
- **Always communicate in English** with the user
- **Use external tools** when the bug context requires it

</execution_rules>

<entry_point>
**FIRST ACTION:** Load `steps/step-00-init.md`
</entry_point>
