---
name: step-07-tests
description: Smart test analysis and creation - analyze patterns, create appropriate tests
prev_step: steps/step-04-validate.md
next_step: steps/step-08-run-tests.md
---

# Step 7: Tests (Analysis & Creation)

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER create tests without analyzing existing patterns first
- 🛑 NEVER use wrong test type (unit when integration needed)
- ✅ ALWAYS analyze test infrastructure BEFORE writing
- ✅ ALWAYS follow existing test conventions exactly
- ✅ ALWAYS map tests to acceptance criteria
- 📋 YOU ARE A TEST ENGINEER, not a code generator
- 💬 FOCUS on "What tests does this ACTUALLY need?"
- 🚫 FORBIDDEN to ignore project test conventions

## EXECUTION PROTOCOLS:

- 🎯 Analyze test infrastructure first
- 💾 Document test strategy (if save_mode)
- 📖 Read similar tests before writing
- 🚫 FORBIDDEN to write tests without reading examples

## CONTEXT BOUNDARIES:

- Implementation is complete and validated
- Test infrastructure exists (discovered in this step)
- Existing tests show conventions to follow
- Focus on creating RIGHT tests, not just tests

## YOUR TASK:

Analyze existing test patterns and create appropriate tests for the implementation.

---

<available_state>
From previous steps:

| Variable | Description |
|----------|-------------|
| `{task_description}` | What was implemented |
| `{task_id}` | Kebab-case identifier |
| `{auto_mode}` | Skip confirmations |
| `{save_mode}` | Save outputs to files |
| `{economy_mode}` | Lighter test analysis |
| `{output_dir}` | Path to output (if save_mode) |
| Files modified | From implementation |
| Acceptance criteria | From step-01 |
</available_state>

---

## EXECUTION SEQUENCE:

### 1. Initialize Save Output (if save_mode)

**If `{save_mode}` = true:**

```bash
bash {skill_dir}/scripts/update-progress.sh "{task_id}" "07" "tests" "in_progress"
```

Append analysis to `{output_dir}/07-tests.md` as you work.

### 2. Test Infrastructure (pre-configured)

**Diane test stack — no discovery needed:**

| Scope | Framework | Command | Test location |
|-------|-----------|---------|---------------|
| API | Vitest + PGlite | `pnpm -F @diane/api test` | `apps/api/src/**/*.test.ts` |
| Expo hooks | Vitest + @testing-library/react | `pnpm -F @diane/app test` | `apps/app/hooks/**/*.test.ts` |
| Expo E2E | Playwright | `pnpm -F @diane/app test:e2e` | `apps/app/e2e/**/*.test.ts` |

**API test helpers:** `apps/api/src/test/` (fixtures, helpers, test DB setup)
**API patterns:** tRPC caller tests, Drizzle test transactions, auth mocking
**Expo hook patterns:** `renderHook` + `act` from `@testing-library/react`, jsdom env, co-located test files

### 3. Analyze Existing Test Patterns

**If `{economy_mode}` = true:**
→ Read 1 similar test file for patterns

**If `{economy_mode}` = false:**
→ Read 2-3 similar test files

**Pattern Checklist:**
- [ ] describe/it vs test() syntax
- [ ] Setup/teardown patterns
- [ ] Mocking approach
- [ ] Assertion style
- [ ] Test data approach

### 4. Determine Test Strategy (scope-aware)

| Implementation Type | Test Type | Framework |
|--------------------|-----------|-----------|
| tRPC procedure | Integration via caller | Vitest + PGlite (`pnpm -F @diane/api test`) |
| Service/Logic | Unit/Integration | Vitest (`pnpm -F @diane/api test`) |
| Drizzle schema | Migration + query test | Vitest with test DB |
| Expo hook | Unit via renderHook | Vitest + @testing-library/react (`pnpm -F @diane/app test`) |
| Expo screen/flow | E2E user flow | Playwright (`pnpm -F @diane/app test:e2e`) |
| Shared schema | Unit validation | Vitest |

### 5. Create Test Plan

```markdown
## Test Plan

### API Tests (if scope includes api)
**Framework:** Vitest
**Command:** `pnpm -F @diane/api test`
**Helpers:** `apps/api/src/test/`

**Integration:** `apps/api/src/routes/auth/register.test.ts`
- creates user with valid data (happy path)
- rejects invalid email (error case)
- requires authentication (auth guard)
- isolates user data (multi-tenant)

### Expo E2E Tests (if scope includes expo)
**Framework:** Playwright
**Command:** `pnpm -F @diane/app test:e2e`

**E2E:** `apps/app/e2e/register.test.ts`
- completes registration flow
- shows validation errors on invalid input
```

**If `{auto_mode}` = false:**

```yaml
questions:
  - header: "Tests"
    question: "Review the test plan. Ready to create tests?"
    options:
      - label: "Create tests (Recommended)"
        description: "Proceed with planned tests"
      - label: "Add more tests"
        description: "I want additional test cases"
      - label: "Modify approach"
        description: "Change the strategy"
      - label: "Skip tests"
        description: "Don't create tests"
    multiSelect: false
```

### 6. Create Tests

**CRITICAL: Follow existing patterns EXACTLY**

1. Read similar test for reference
2. Create test file matching structure
3. Write tests following conventions

```typescript
import { describe, it, expect, beforeEach } from 'vitest'

describe('POST /api/auth/register', () => {
  beforeEach(async () => {
    await db.user.deleteMany()
  })

  it('creates user with valid data', async () => {
    const response = await client.post('/api/auth/register', {
      email: 'test@example.com',
      password: 'SecurePass123!'
    })

    expect(response.status).toBe(201)
  })

  it('rejects invalid email', async () => {
    const response = await client.post('/api/auth/register', {
      email: 'invalid',
      password: 'SecurePass123!'
    })

    expect(response.status).toBe(400)
  })
})
```

### 7. Verify Tests

```bash
pnpm run typecheck
```

List created tests:
```
**Tests Created:**
- `src/auth/register.test.ts` (3 tests)
- `src/utils/validation.test.ts` (2 tests)
```

### 8. Complete Save Output (if save_mode)

**If `{save_mode}` = true:**

Append to `{output_dir}/07-tests.md`:
```markdown
---
## Step Complete
**Status:** ✓ Complete
**Tests created:** {count}
**Test files:** {list}
**Next:** step-08-run-tests.md
**Timestamp:** {ISO timestamp}
```

---

## SUCCESS METRICS:

✅ Test infrastructure analyzed
✅ Existing patterns studied
✅ Appropriate test types chosen
✅ Tests follow codebase conventions
✅ Tests pass syntax check
✅ All AC have corresponding tests

## FAILURE MODES:

❌ Writing tests without analyzing patterns
❌ Wrong test type for implementation
❌ Ignoring project conventions
❌ Tests don't match acceptance criteria
❌ Over-testing (testing implementation, not behavior)
❌ **CRITICAL**: Not using AskUserQuestion for approval

## TEST PROTOCOLS:

- Analyze BEFORE writing
- Follow existing patterns EXACTLY
- Test behavior, not implementation
- Map to acceptance criteria
- Create minimal, focused tests

---

## NEXT STEP:

After tests created, load `./step-08-run-tests.md`

<critical>
Remember: Create the RIGHT tests - analyze patterns first, then write!
</critical>
