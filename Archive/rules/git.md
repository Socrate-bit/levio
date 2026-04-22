---
description: Git commit and PR conventions
globs: *
---

# Git Conventions

## Commits atomiques

Chaque commit = UN SEUL changement logique. Ne jamais mélanger feature, fix et refactoring.

## Conventional Commits

```
<type>(<scope>): <description courte impérative en anglais>
```

Types : `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`

Scopes : `decks`, `review`, `auth`, `onboarding`, `api`, `ui`, `db`, `shared`, `admin`...

Exemples :
- `feat(decks): add deck progress bar with color-coded urgency`
- `fix(review): prevent double card flip during animation`
- `refactor(auth): extract token refresh logic into shared hook`
- `test(review): add unit tests for spaced repetition algorithm`

## Règles strictes

1. Avant de commit : `tsc --noEmit` + `lint` — jamais commit avec des erreurs
2. Après chaque modification : lancer les tests du scope modifié
3. Nouvelle feature = tests AVANT de considérer le travail terminé
4. Chaque commit doit laisser l'app fonctionnelle
5. Tâche multi-étapes → plusieurs commits ordonnés logiquement

## PR Summary

Après une feature complète :

```markdown
## PR Summary
**What**: description concise
**Why**: contexte et motivation
**How**: approche technique
**Testing**: ce qui a été testé
**Breaking changes**: le cas échéant
```
