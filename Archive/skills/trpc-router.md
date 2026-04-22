# tRPC Router Creator

## File Location

`apps/api/src/trpc/routers/<name>.ts`

## Router Template

```ts
import { eq, and } from "drizzle-orm";
import { z } from "zod";
import { TRPCError } from "@trpc/server";
import { router, protectedProcedure } from "../trpc.js";
import { myTable } from "../../db/schema.js";
import { createMyInput, updateMyInput } from "@diane/shared";

export const myRouter = router({
  list: protectedProcedure
    .input(z.object({ /* filters */ }).optional())
    .query(async ({ ctx, input }) => {
      return ctx.db.query.myTable.findMany({
        where: eq(myTable.userId, ctx.userId),
      });
    }),

  create: protectedProcedure
    .input(createMyInput)
    .mutation(async ({ ctx, input }) => {
      const [item] = await ctx.db
        .insert(myTable)
        .values({ ...input, userId: ctx.userId })
        .returning();
      return item;
    }),

  update: protectedProcedure
    .input(updateMyInput)
    .mutation(async ({ ctx, input }) => {
      const { id, ...data } = input;
      const [item] = await ctx.db
        .update(myTable)
        .set({ ...data, updatedAt: new Date() })
        .where(and(eq(myTable.id, id), eq(myTable.userId, ctx.userId)))
        .returning();
      return item;
    }),

  delete: protectedProcedure
    .input(z.object({ id: z.string().uuid() }))
    .mutation(async ({ ctx, input }) => {
      await ctx.db
        .delete(myTable)
        .where(and(eq(myTable.id, input.id), eq(myTable.userId, ctx.userId)));
      return { success: true };
    }),
});
```

## Conventions

- **Authorization**: Always scope queries by `eq(table.userId, ctx.userId)`
- **Ownership check** (tables without `userId` like `cardGroups`): Join to parent table and check `userId`:
  ```ts
  const group = await ctx.db.query.cardGroups.findFirst({
    where: eq(cardGroups.id, id),
    with: { lesson: true },
  });
  if (!group || group.lesson.userId !== ctx.userId) {
    throw new TRPCError({ code: "NOT_FOUND" });
  }
  ```
- **Updates**: Always set `updatedAt: new Date()` manually
- **Deletes**: Always return `{ success: true }`
- **Extensions**: `.js` on all relative imports
- **Input schemas**: Define in `packages/shared/src/schemas.ts`, import from `@diane/shared`

## Registration

Add to `apps/api/src/trpc/index.ts`:

```ts
import { myRouter } from "./routers/my.js";

export const appRouter = router({
  // ... existing routers
  my: myRouter,
});
```

## Procedure Types

| Type | Usage | Context |
|------|-------|---------|
| `publicProcedure` | No auth | `ctx.userId` is `null` |
| `protectedProcedure` | Requires auth | `ctx.userId` is `string` (narrowed) |
| `adminProcedure` | Requires `x-admin-key` header | For admin-only operations |

## Checklist

1. Create Zod input schemas in `packages/shared/src/schemas.ts`
2. Create router file in `apps/api/src/trpc/routers/`
3. Register in `apps/api/src/trpc/index.ts`
4. Write tests in `apps/api/src/trpc/routers/<name>.test.ts`
