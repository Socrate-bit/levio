---
description: Test conventions for API (Vitest + PGlite) and Expo hooks (Vitest + @testing-library/react)
globs: "**/*.test.ts"
---

## API Tests (`apps/api`)

### Framework

- Vitest with `pool: "forks"` (separate process per file)
- PGlite in-memory Postgres — each test file gets isolated DB
- Timeout: 15 seconds per test

### Helpers

From `src/test/helpers.ts`:
- `createTestDb()` — returns `{ db, client }` with all migrations applied
- `createAuthenticatedCaller(db, userId)` — simulates logged-in user
- `createUnauthenticatedCaller(db)` — simulates no auth (throws on protected procedures)
- `createAdminCaller(db)` — simulates admin with `x-admin-key` header

### Fixtures

From `src/test/fixtures.ts`:
- `createUser(db, overrides?)` — random email + UUID
- `createFolder(db, userId, overrides?)`
- `createLesson(db, userId, overrides?)`
- `createCard(db, userId, lessonId, overrides?)`
- `createSource(db, userId, lessonId, overrides?)`
- `createSubscription(db, userId, overrides?)`
- `createGenerationJob(db, userId, lessonId, overrides?)`
- `createCardGroup(db, lessonId, overrides?)`
- `createXpEvent(db, userId, overrides?)`

### Pattern

```
beforeAll → createTestDb() + seed data
afterAll → client.close()
```

### Mandatory Test Cases

1. **Happy path** — CRUD works with valid input
2. **Auth required** — unauthenticated caller throws
3. **User isolation** — user B cannot see/modify user A's data
4. **Input validation** — invalid input is rejected by Zod

## Expo Hook Tests (`apps/app`)

### Framework

- Vitest with jsdom environment
- `@testing-library/react` — `renderHook` + `act` for hook testing
- Setup file: `apps/app/test/setup.ts` (mocks `react-native`)
- Config: `apps/app/vitest.config.ts`

### Pattern

```typescript
import { describe, it, expect } from "vitest";
import { renderHook, act } from "@testing-library/react";
import { useMyHook } from "./useMyHook";

describe("useMyHook", () => {
  it("should initialize with default state", () => {
    const { result } = renderHook(() => useMyHook());
    expect(result.current.value).toBe(defaultValue);
  });

  it("should update state via action", () => {
    const { result } = renderHook(() => useMyHook());
    act(() => {
      result.current.doSomething();
    });
    expect(result.current.value).toBe(expectedValue);
  });
});
```

### Conventions

- Test file co-located with hook: `hooks/useMyHook.test.ts`
- No `beforeAll`/`afterAll` needed (no DB) — use `renderHook` per test
- Wrap state mutations in `act()`
- Test: initial state, state transitions, reset/cleanup, edge cases
- Import from `@testing-library/react` (not `@testing-library/react-hooks` which is deprecated)

## Run

```bash
pnpm test                          # Run all tests
pnpm test:watch                    # Watch mode
pnpm --filter @diane/api test      # API tests only
pnpm --filter @diane/app test      # Expo hook tests only
```
