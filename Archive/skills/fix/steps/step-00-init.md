---
name: step-00-init
description: Parse flags, comprendre le bug, identifier le scope d'investigation
next_step: steps/step-01-investigate.md
---

# Step 0: Initialization

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER start investigating code — that's step-01's job
- 🛑 NEVER propose fixes — that's step-03's job
- ✅ ALWAYS parse ALL flags before any other action
- ✅ ALWAYS communicate in **French** with the user
- ✅ ALWAYS identify scope (files, modules, MCP needed) before proceeding
- 📋 YOU ARE AN INITIALIZER, not an investigator
- 💬 FOCUS on understanding the bug and scoping the investigation
- 🚫 FORBIDDEN to load step-01 until scope is identified

## EXECUTION PROTOCOLS:

- 🎯 Parse flags → understand bug → identify scope → proceed
- 📖 Initialize all state variables before proceeding
- 🚫 FORBIDDEN to read code files in detail (just identify them)
- ✅ ALWAYS show COMPACT summary and proceed immediately

## CONTEXT BOUNDARIES:

- This is the FIRST step — no previous context exists
- User input contains the bug description and optional flags
- Use quick searches (grep, glob) to identify scope — don't deep-read

## YOUR TASK:

Parse the user's bug description, identify which files/modules/MCP tools are relevant, and prepare the investigation scope for the parallel agents.

---

<defaults>

```yaml
auto_mode: false    # -a: Skip confirmations, propose fix directly
deep_mode: false    # -d: Exhaustive investigation (more context per agent)
```

</defaults>

---

## EXECUTION SEQUENCE:

### 1. Parse Flags and Bug Description

```
Enable flags (lowercase ON):
  -a or --auto  → {auto_mode} = true
  -d or --deep  → {deep_mode} = true

Disable flags (UPPERCASE OFF):
  -A or --no-auto  → {auto_mode} = false
  -D or --no-deep  → {deep_mode} = false

First positional argument = {bug_description}
```

### 2. Understand the Bug

Analyze the bug description to determine:

**Category** (set flags for which agents/MCP to activate):

| Keywords in description | Sets |
|------------------------|------|
| "DB", "data", "missing", "not saved", "query", "null in DB" | `{needs_db}` = true |
| "UI", "screen", "button", "crash", "display", "render", "console" | `{needs_runtime}` = true |
| "subscription", "paywall", "pro", "entitlement", "offering", "purchase", "RevenueCat" | `{needs_revenuecat}` = true |
| "deploy", "build", "CI", "prod down", "500", "server" | needs dokploy MCP |
| user email mentioned, "user reports", "user can't", "crash for user", "exception", "error in prod" | `{needs_posthog}` = true |

If an email address is provided in the bug description, store it as `{posthog_email}`.

If unsure, default ALL to false — agents will use grep/read instead.

### 3. Identify Scope

Run quick searches to find relevant files:

```bash
# Search for keywords from the bug description in the codebase
grep -r "{keyword}" apps/ packages/ --include="*.ts" --include="*.tsx" -l | head -20
```

Store results as `{scope_files}`.

Determine which **modules** are involved:
- `apps/api/` → backend, tRPC routes, DB queries
- `apps/app/` → mobile/web UI, hooks, components
- `apps/admin/` → admin dashboard
- `packages/shared/` → shared schemas, types
- `services/ai-worker/` → AI generation

Store as `{scope_modules}`.

### 4. Find Related Tests

```bash
# Find test files related to scope
# For each scope file, check if a .test.ts exists
```

Store as `{related_tests}`.

### 5. Show Summary and Proceed

Display COMPACT initialization summary:

```
/fix: "{bug_description}"

| Parameter | Value |
|-----------|-------|
| auto_mode | true/false |
| deep_mode | true/false |
| Scope | {scope_modules} |
| Fichiers | {count} fichiers identifies |
| Tests | {count} tests lies |
| DB | oui/non |
| Runtime | oui/non |
| RevenueCat | oui/non |
| PostHog | oui/non (email: {posthog_email}) |

→ Lancement de l'investigation...
```

Then IMMEDIATELY proceed to step-01.

---

## SUCCESS METRICS:

✅ All flags correctly parsed
✅ Bug description understood and categorized
✅ Scope files identified via quick search
✅ MCP needs determined (DB, runtime, RevenueCat)
✅ Output is COMPACT (one table, no verbose logs)
✅ Proceeded to step-01 immediately

## FAILURE MODES:

❌ Starting to read/analyze code in detail
❌ Proposing fixes before investigation
❌ Not identifying scope (agents won't know where to look)
❌ Verbose output with explanations
❌ Asking unnecessary questions when scope is clear

---

## NEXT STEP:

After showing summary, proceed directly to `./step-01-investigate.md`

<critical>
Remember:
- Step-00 is an INITIALIZER — quick scope identification only
- Use grep/glob to find files, don't read them
- Determine which MCP tools agents will need
- Output MUST be compact: one table, proceed immediately
</critical>
