---
description: API backend conventions
globs: "apps/api/**"
---

## Procedure Types

- `publicProcedure` — no auth required, `ctx.userId` is `null`
- `protectedProcedure` — session required, `ctx.userId` is `string`
- `adminProcedure` — `x-admin-key` header, no user session needed

## Ownership Enforcement

- Always scope queries by `userId` in protected procedures
- Direct ownership: `.where(and(eq(table.id, id), eq(table.userId, ctx.userId)))`
- Indirect ownership (via joins): fetch parent, verify `parent.userId === ctx.userId`, throw `NOT_FOUND` if mismatch
- Never skip ownership checks — assume every unscoped query is a security bug

## CRUD Patterns

- **Updates**: Always manually set `updatedAt: new Date()`
- **Deletes**: Always return `{ success: true }`
- **Input schemas**: Define in `packages/shared/src/schemas.ts`, import from `@diane/shared`
- **Imports**: Always use `.js` extension on relative imports (ESM — no rewrite in API)
- **Registration**: Add router import + key in `src/trpc/index.ts`

## Error Handling

- Throw `TRPCError({ code: "NOT_FOUND" })` for ownership violations (not "UNAUTHORIZED")
- Throw `TRPCError({ code: "UNAUTHORIZED" })` only for auth failures
- Input validation errors are automatic via Zod input schema

## Database

- Use Drizzle query builder with type safety
- See `.claude/rules/drizzle.md` for schema conventions
- Use `lessonCardCounts(userId)` from `src/db/extras.ts` for computed lesson stats

## Special Patterns

- **Bulk SQL Copy**: Use `INSERT ... SELECT` raw SQL for card duplication (not loading into memory)
- **SSE Subscriptions**: Use tRPC `.subscription()` with async generators for real-time updates
- **Rate Limiting**: `checkGenerationRateLimit()` counts jobs in last hour, throws `TOO_MANY_REQUESTS` if >= 20

## Commands

- `pnpm dev` — start dev server
- `pnpm test` — run tests
- `pnpm typecheck` — tsc --noEmit
- `pnpm db:generate` — generate Drizzle migrations
- `pnpm db:migrate` — apply migrations
