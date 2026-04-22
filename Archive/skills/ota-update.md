# OTA Update — Push Over-the-Air Update

Push a JS-only update to production devices without rebuilding native binaries.

## When to Use OTA vs Native Build

**OTA** (this skill): JS/TS code changes, asset changes, config changes that don't touch native modules.
**Native build** (use `native-build` skill): new native dependencies, Expo SDK upgrade, native config changes (permissions, schemes, plugins), version bump required by stores.

## Pre-flight Checks

Before triggering an OTA update, always:

1. **Typecheck**: `cd apps/app && pnpm typecheck`
2. **Lint**: `cd apps/app && pnpm lint`
3. **Check git status**: ensure working tree is clean
4. **Verify no native changes**: check if any native modules were added/changed since last native build. If native changes exist, a full native build is required instead.

```bash
# Quick check for native changes (new plugins, native deps)
git diff HEAD~5 -- apps/app/app.config.js apps/app/package.json | grep -E "plugin|expo-|react-native-"
```

If any check fails, fix the issue before proceeding.

## Push OTA Update

Run from `apps/app/`:

```bash
# Via EAS workflow
eas workflow:run .eas/workflows/update.yml

# Or via shortcut script
pnpm ota
```

This publishes the current JS bundle to the `production` channel. All devices with a matching runtime version will receive the update on next app launch.

## Verify

After pushing, tell the user:
- The update is live on the `production` channel
- Users will receive it on their next app cold start
- They can monitor rollout at https://expo.dev

## Checklist

- [ ] Typecheck passes
- [ ] Lint passes
- [ ] Working tree clean
- [ ] No native changes since last native build
- [ ] OTA update pushed
