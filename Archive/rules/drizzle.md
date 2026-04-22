---
description: Drizzle ORM schema conventions
globs: "**/db/schema.ts,**/migrations/**"
---

## File Location

`apps/api/src/db/schema.ts`

## Column Conventions

- **Primary keys**: `uuid("id").defaultRandom().primaryKey()`
- **Timestamps**: Always `{ withTimezone: true }` + `.defaultNow()`, both `createdAt` and `updatedAt`
- **Naming**: camelCase in JS code, snake_case in DB — always pass explicit string: `userId: uuid("user_id")`
- **Typed JSON**: `json("col").$type<T>().notNull().default([])`

## Foreign Keys

Always specify `onDelete` strategy:
- `"cascade"` — for owned resources (user deletion = delete all children)
- `"set null"` — for optional references (e.g., `folderId` on lessons)

Example: `userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" })`

## Indexes

Define in second argument of `pgTable()` as array:
```
(table) => [
  index("table_user_id_idx").on(table.userId),
  uniqueIndex("table_name_unique").on(table.name),
]
```

## Relations

Define separately after all tables, always exported:
```ts
export const myTableRelations = relations(myTable, ({ one, many }) => ({
  user: one(users, { fields: [myTable.userId], references: [users.id] }),
  children: many(childTable),
}));
```

Self-referential: use `relationName`:
```ts
parent: one(folders, {
  fields: [folders.parentId],
  references: [folders.id],
  relationName: "folderTree"
}),
children: many(folders, { relationName: "folderTree" }),
```

## Checklist for New Tables

1. Add table definition in `apps/api/src/db/schema.ts`
2. Add relations below existing relations
3. Run `pnpm db:generate` then `pnpm db:migrate`
4. Add fixture in `apps/api/src/test/fixtures.ts` if needed
5. Update admin (`apps/admin`) if table needs admin CRUD

## Commands

- `pnpm db:generate` — generate SQL migration files
- `pnpm db:migrate` — apply migrations to database
- `pnpm db:studio` — open Drizzle Studio to inspect data
