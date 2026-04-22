# API Test Writer

## Framework

Vitest with PGlite (in-memory Postgres).

## Test Template

```ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import type { PGlite } from "@electric-sql/pglite";
import {
  createTestDb,
  createAuthenticatedCaller,
  createUnauthenticatedCaller,
  type TestDb,
} from "../../test/helpers.js";
import { createUser, createLesson } from "../../test/fixtures.js";

describe("myRouter", () => {
  let db: TestDb;
  let client: PGlite;
  let userId1: string;
  let userId2: string;

  beforeAll(async () => {
    const t = await createTestDb();
    db = t.db;
    client = t.client;
    const user1 = await createUser(db);
    const user2 = await createUser(db);
    userId1 = user1.id;
    userId2 = user2.id;
  });

  afterAll(async () => {
    await client.close();
  });

  describe("list", () => {
    it("should list items for authenticated user", async () => {
      const caller = createAuthenticatedCaller(db, userId1);
      const result = await caller.my.list();
      expect(result).toBeDefined();
    });

    it("should isolate users - user B cannot see user A data", async () => {
      const caller2 = createAuthenticatedCaller(db, userId2);
      const result = await caller2.my.list();
      expect(result).toHaveLength(0);
    });

    it("should require authentication", async () => {
      const caller = createUnauthenticatedCaller(db);
      await expect(caller.my.list()).rejects.toThrow();
    });
  });

  describe("create", () => {
    it("should create with valid input", async () => {
      const caller = createAuthenticatedCaller(db, userId1);
      const item = await caller.my.create({ name: "Test" });
      expect(item.name).toBe("Test");
      expect(item.userId).toBe(userId1);
    });

    it("should reject invalid input", async () => {
      const caller = createAuthenticatedCaller(db, userId1);
      await expect(caller.my.create({ name: "" })).rejects.toThrow();
    });
  });

  describe("delete", () => {
    it("should delete own item", async () => {
      const caller = createAuthenticatedCaller(db, userId1);
      // ... create then delete
      const result = await caller.my.delete({ id: "..." });
      expect(result.success).toBe(true);
    });

    it("should not delete other user's item", async () => {
      // ... create as user1, try delete as user2
    });
  });
});
```

## Helpers

`apps/api/src/test/helpers.ts`:
- `createTestDb()` — PGlite instance + runs all migrations
- `createAuthenticatedCaller(db, userId)` — simulates logged-in user
- `createUnauthenticatedCaller(db)` — simulates no auth
- `createAdminCaller(db)` — simulates admin with `x-admin-key`

## Fixtures

`apps/api/src/test/fixtures.ts`:
- `createUser(db, overrides?)` — random email + UUID
- `createFolder(db, userId, overrides?)`
- `createLesson(db, userId, overrides?)`
- `createCard(db, userId, lessonId, overrides?)`
- `createSource(db, userId, lessonId, overrides?)`
- `createSubscription(db, userId, overrides?)`
- `createGenerationJob(db, userId, lessonId, overrides?)`
- `createCardGroup(db, lessonId, overrides?)`
- `createXpEvent(db, userId, overrides?)`

## Always Test

1. Happy path (CRUD works)
2. Auth required (unauthenticated throws)
3. User isolation (user B can't see/modify user A's data)
4. Input validation (reject invalid data)

## Run

```bash
pnpm test
```
