# Native Build — Push to App Stores

Build and submit a native iOS/Android version via EAS workflows.

## Pre-flight Checks

Before triggering a build, always:

1. **Typecheck**: `cd apps/app && pnpm typecheck`
2. **Lint**: `cd apps/app && pnpm lint`
3. **Check git status**: ensure working tree is clean (commit or stash pending changes)
4. **Confirm version**: read `apps/app/app.config.js` and confirm `version` + `ios.buildNumber` / `android.versionCode` with the user

If any check fails, fix the issue before proceeding. Never skip checks.

## Bump Version

Ask the user what kind of bump is needed:

- **Patch** (3.0.0 → 3.0.1): bug fixes only
- **Minor** (3.0.0 → 3.1.0): new features
- **Major** (3.0.0 → 4.0.0): breaking changes

Then update in `apps/app/app.config.js`:
- `version` field (semver string)
- `ios.buildNumber` (increment by 1, string)
- `android.versionCode` (increment by 1, integer)

Commit the version bump: `chore(app): bump version to X.Y.Z`

## Build

Run from `apps/app/`:

```bash
# Build both platforms for production
eas workflow:run .eas/workflows/build.yml --input platform=all --input profile=production

# Or single platform
eas workflow:run .eas/workflows/build.yml --input platform=ios --input profile=production
eas workflow:run .eas/workflows/build.yml --input platform=android --input profile=production
```

After triggering, tell the user the build is running on EAS and they can monitor it at https://expo.dev.

## Submit to Stores

Once builds complete, submit:

```bash
# Submit both platforms
eas submit --platform all --latest --non-interactive

# Or single platform
eas submit --platform ios --latest --non-interactive
eas submit --platform android --latest --non-interactive
```

## Full Pipeline (shortcut)

The `native` script does build + submit in one go:

```bash
cd apps/app && pnpm native
```

## Checklist

- [ ] Typecheck passes
- [ ] Lint passes
- [ ] Working tree clean
- [ ] Version bumped and committed
- [ ] Build triggered
- [ ] Submit triggered (after build completes)
