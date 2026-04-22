# Drizzle Schema & Migration

## File

`apps/api/src/db/schema.ts`

## Table Template

```ts
export const myTable = pgTable(
  "my_table",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),

    name: varchar("name", { length: 255 }).notNull(),
    description: text("description"),

    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    index("my_table_user_id_idx").on(table.userId),
  ]
);
```

## Conventions

- **Primary keys**: `uuid("id").defaultRandom().primaryKey()`
- **Timestamps**: Always `{ withTimezone: true }` + `.defaultNow()`, both `createdAt` and `updatedAt`
- **Column naming**: camelCase in JS, snake_case in DB — always pass explicit string: `userId: uuid("user_id")`
- **Foreign keys**: Explicit `onDelete` strategy:
  - `"cascade"` for owned resources (user deletes = delete children)
  - `"set null"` for optional references (e.g. `folderId` on lessons)
- **Indexes**: Second argument of `pgTable()`, array of `index()` / `uniqueIndex()`
- **Typed JSON**: `json("col").$type<T>().notNull().default([])`

## Relations

Define separately after all tables, always exported:

```ts
export const myTableRelations = relations(myTable, ({ one, many }) => ({
  user: one(users, { fields: [myTable.userId], references: [users.id] }),
  children: many(childTable),
}));
```

Self-referential: use `relationName` to disambiguate:
```ts
parent: one(folders, { fields: [folders.parentId], references: [folders.id], relationName: "folderTree" }),
children: many(folders, { relationName: "folderTree" }),
```

## Migration Commands

```bash
pnpm db:generate   # Generate SQL migration files
pnpm db:migrate    # Apply migrations to database
pnpm db:studio     # Open Drizzle Studio to inspect
```

## Checklist

1. Add table definition in `apps/api/src/db/schema.ts`
2. Add relations below existing relations
3. Run `pnpm db:generate` then `pnpm db:migrate`
4. Add fixture in `apps/api/src/test/fixtures.ts` if needed
5. Update admin (`apps/admin`) if the table needs admin CRUD
