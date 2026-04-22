---
name: push
description: Pre-push quality gate — lance 6 checks en parallele (fiabilite code, refactoring, rules, typecheck+tests, i18n, test coverage) puis push. Use when ready to push, before merging, or to validate code quality.
argument-hint: "[-a] [-f] [-b]"
---

<objective>
Run 6 parallel quality checks (code reliability, refactoring, rules compliance, typecheck+tests, i18n completeness, test coverage) and push to the current branch if all checks pass.
</objective>

<quick_start>

```bash
/push                    # Interactive — shows results, asks before pushing
/push -a                 # Auto — push immediately if all checks pass
/push -a -f              # Auto + fix suggestions from agents
/push -b                 # Branch check — run all checks on entire branch diff, no push
```

</quick_start>

<flags>

| ON | OFF | Long | Description |
|----|-----|------|-------------|
| `-a` | `-A` | `--auto` | Skip confirmations, auto-push if all checks pass |
| `-f` | `-F` | `--fix` | Agents propose fixes alongside findings |
| `-b` | `-B` | `--branch` | Check entire branch diff (no push, no commit check) |

**Parsing:** Defaults all false. Flags override. No positional arguments needed.

</flags>

<workflow>

1. **Init** — Parse flags, detect branch, verify PR exists, gather diff context
2. **Parallel Checks** — Launch 6 agents simultaneously:
   - Code Reliability: race conditions, edge cases, error handling, design quality
   - Refactoring: dead code, duplication, simplification opportunities
   - Rules Compliance: `.claude/rules/*.md` respected on changed files
   - Typecheck & Tests: `pnpm typecheck` + `pnpm test`
   - i18n Completeness: new translation keys present in all 6 languages
   - Test Coverage: new features/hooks/routes have unit tests
3. **Summary** — Display pass/fail/warn table, decide next step
4. **Push** — `git push -u origin {branch}`

</workflow>

<step_files>

| Step | File | Purpose |
|------|------|---------|
| 00 | `steps/step-00-init.md` | Parse flags, detect branch, gather diff |
| 01 | `steps/step-01-parallel-checks.md` | Launch 5 check agents in parallel |
| 02 | `steps/step-02-summary.md` | Display results table, user decision |
| 03 | `steps/step-03-push.md` | Execute git push |

</step_files>

<state_variables>

| Variable | Type | Set by |
|----------|------|--------|
| `{auto_mode}` | boolean | step-00 |
| `{fix_mode}` | boolean | step-00 |
| `{branch_mode}` | boolean | step-00 |
| `{branch_name}` | string | step-00 |
| `{base_branch}` | string | step-00 |
| `{diff_content}` | string | step-00 |
| `{changed_files}` | string | step-00 |
| `{commit_messages}` | string | step-00 |
| `{check_results}` | object | step-01 |
| `{all_passed}` | boolean | step-02 |

</state_variables>

<execution_rules>

- **Load one step at a time** (progressive loading)
- **Persist state variables** across all steps
- **Follow next_step directive** at end of each step
- **Launch ALL 6 agents in ONE message** for true parallelism
- **WARN is non-blocking** — only FAIL prevents push
- **Always communicate in French** with the user

</execution_rules>

<entry_point>
**FIRST ACTION:** Load `steps/step-00-init.md`
</entry_point>
