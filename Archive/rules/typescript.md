---
description: TypeScript strict rules
globs: "**/*.ts,**/*.tsx"
---

# TypeScript Rules

- NEVER use `as unknown as`, `as any`, or type casts that bypass TypeScript safety. Fix the actual types instead.
- NEVER use `eslint-disable` comments to bypass lint rules. Fix the actual code instead.
- **Import extensions differ by package**:
  - `apps/api/`: use `.js` extension on relative imports (ESM, no rewrite)
  - `packages/shared/`: use `.ts` extension on relative imports (`rewriteRelativeImportExtensions: true` in tsconfig rewrites `.ts` → `.js` at compile time)
  - `apps/app/` (Expo): no extension needed (Metro resolves automatically)
- Shared types and schemas live in `packages/shared` — import from `@diane/shared`.
