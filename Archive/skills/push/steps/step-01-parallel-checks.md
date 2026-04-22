---
name: step-01-parallel-checks
description: Launch 6 quality check agents in parallel and collect results
prev_step: steps/step-00-init.md
next_step: steps/step-02-summary.md
---

# Step 1: Parallel Quality Checks

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER run agents sequentially — ALL 6 in ONE message
- 🛑 NEVER analyze code yourself — delegate to agents
- ✅ ALWAYS launch all 6 agents with `run_in_background: true`
- ✅ ALWAYS pass diff context from step-00 to each agent prompt
- ✅ ALWAYS communicate in **French** with the user
- 📋 YOU ARE A COORDINATOR, not a checker
- 💬 FOCUS on launching agents and collecting results
- 🚫 FORBIDDEN to implement any checks yourself

## EXECUTION PROTOCOLS:

- 🎯 Launch all 6 agents in a single message
- 📖 Each agent gets full context (they can't see your conversation)
- 🚫 FORBIDDEN to read/analyze code yourself
- ✅ Wait for all agents to complete before proceeding

## CONTEXT BOUNDARIES:

- State variables from step-00 are available: `{diff_content}`, `{changed_files}`, `{commit_messages}`, `{base_branch}`, `{fix_mode}`
- You have the diff — pass it to agents, don't re-run git commands
- Agents return structured results to collect

## YOUR TASK:

Launch 6 independent check agents in parallel, wait for all results, and store them in `{check_results}`.

---

<available_state>
From step-00:

| Variable | Description |
|----------|-------------|
| `{auto_mode}` | Skip confirmations |
| `{fix_mode}` | Agents propose fixes |
| `{branch_name}` | Current git branch |
| `{base_branch}` | Base branch (or "main") |
| `{diff_content}` | Full git diff |
| `{changed_files}` | List of changed file paths |
| `{commit_messages}` | One-line commit messages |
</available_state>

---

## EXECUTION SEQUENCE:

### 1. Announce Launch

```
Lancement de 6 checks en parallele...
```

### 2. Launch ALL 6 Agents in ONE Message

<critical>
ALL 6 Agent tool calls MUST be in a SINGLE message.
Each with `run_in_background: true`.
This is CRITICAL for true parallelism.
</critical>

---

#### Agent 1: Code Reliability & Design Check

```
Agent:
  subagent_type: "feature-dev:code-reviewer"
  run_in_background: true
  description: "Code reliability check"
  prompt: |
    Tu analyses la fiabilite et la qualite de conception du code modifie.

    ## Changed Files
    {changed_files}

    ## Full Diff
    {diff_content}

    Lis chaque fichier modifie EN ENTIER (pas juste le diff) et cherche:
    1. **Race conditions** — etats partages non proteges, async sans guard, effets de bord concurrents
    2. **Edge cases non geres** — null/undefined non checkes, tableaux vides, cas limites oublies
    3. **Gestion d'erreurs** — try/catch manquants, erreurs avalees silencieusement, pas de fallback
    4. **Design** — couplage fort, responsabilites melangees, abstractions mal placees
    5. **Securite** — injection, donnees sensibles exposees, validation manquante aux frontieres
    6. **Memoire / Performance** — fuites memoire (listeners non cleanup, refs), re-renders inutiles, boucles couteuses

    {fix_mode_instruction}

    Sois pragmatique — ne flag que les problemes qui pourraient causer un bug en production.
    Ne flag PAS les preferences de style ou les micro-optimisations.

    REPONDS EXACTEMENT dans ce format:
    STATUS: PASS, WARN ou FAIL
    ISSUES:
    - file:line — [severity: critical/warning] description (vide si PASS)
    SUMMARY: (une phrase)
```

**Note:** Replace `{fix_mode_instruction}` with:
- If `{fix_mode}` = true: `"Pour chaque probleme, propose le code corrige."`
- If `{fix_mode}` = false: `"Liste les problemes sans proposer de code."`

---

#### Agent 2: Refactoring Check

```
Agent:
  subagent_type: "feature-dev:code-reviewer"
  run_in_background: true
  description: "Refactoring check"
  prompt: |
    Tu analyses le code modifie pour des opportunites de refactoring.

    ## Changed Files
    {changed_files}

    ## Full Diff
    {diff_content}

    Lis chaque fichier modifie EN ENTIER (pas juste le diff) et cherche:
    1. Dead code introduit ou laisse
    2. Duplication de code (>10 lignes repetees)
    3. Fonctions qui pourraient etre simplifiees
    4. Logique trop complexe
    5. Imports ou variables inutilises
    6. Magic numbers ou strings hardcodes qui devraient etre des constantes

    {fix_mode_instruction}

    Sois pragmatique — ne flag que les ameliorations significatives, pas les details de style.

    REPONDS EXACTEMENT dans ce format:
    STATUS: PASS ou WARN
    SUGGESTIONS:
    - file:line — description (vide si PASS)
    SUMMARY: (une phrase)
```

**Note:** Replace `{fix_mode_instruction}` with:
- If `{fix_mode}` = true: `"Pour chaque suggestion, propose le code corrige."`
- If `{fix_mode}` = false: `"Liste les suggestions sans proposer de code."`

---

#### Agent 3: Typecheck & Tests

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "Typecheck and tests"
  prompt: |
    Tu executes le typecheck et les tests du projet.

    Le projet est dans: {project_root}

    Lance ces 2 commandes EN PARALLELE (2 appels Bash dans un seul message):

    1. pnpm typecheck
    2. pnpm test

    Attends les resultats des deux.

    REPONDS EXACTEMENT dans ce format:
    STATUS: PASS ou FAIL
    TYPECHECK_STATUS: PASS ou FAIL
    TYPECHECK_ERRORS:
    - (liste des erreurs TS, vide si PASS)
    TEST_STATUS: PASS ou FAIL
    TEST_FAILURES:
    - (liste des tests failing, vide si PASS)
    SUMMARY: (une phrase, ex: "0 erreurs TS, 47/47 tests OK")
```

---

#### Agent 5: i18n Completeness

```
Agent:
  subagent_type: "feature-dev:code-reviewer"
  run_in_background: true
  description: "i18n completeness check"
  prompt: |
    Tu verifies que les cles de traduction ajoutees/modifiees dans cette PR existent dans TOUTES les langues.

    ## Changed Files
    {changed_files}

    ## Full Diff
    {diff_content}

    ## i18n file locations
    - apps/app/i18n/{fr,en,es,it,de,tr}.json

    PROCEDURE:
    1. Dans le diff, extrais les NOUVELLES ou MODIFIEES cles de traduction:
       - Cherche les patterns t("key.path") dans les fichiers .tsx/.ts modifies
       - Cherche les ajouts directs dans les fichiers i18n JSON
    2. Pour chaque cle trouvee, verifie qu'elle existe dans les 6 fichiers de langues:
       - fr.json, en.json, es.json, it.json, de.json, tr.json
    3. Verifie SEULEMENT les cles du diff — PAS un audit complet

    REGLES DE SEVERITE:
    - Cle manquante dans fr.json = FAIL (le francais est la langue source)
    - Cles manquantes dans d'autres langues = WARN (attendu par le workflow, les devs n'ajoutent que le FR)
    - Aucune cle i18n dans le diff = PASS (pas de changement i18n)

    REPONDS EXACTEMENT dans ce format:
    STATUS: PASS, WARN ou FAIL
    MISSING_KEYS:
    - key.path → manquant dans: [langues] (vide si PASS)
    SUMMARY: (une phrase)
```

---

#### Agent 6: Test Coverage Check

```
Agent:
  subagent_type: "feature-dev:code-reviewer"
  run_in_background: true
  description: "Test coverage check"
  prompt: |
    Tu verifies que les nouvelles fonctionnalites introduites dans cette PR sont couvertes par des tests unitaires ET des tests E2E si necessaire.

    ## Changed Files
    {changed_files}

    ## Full Diff
    {diff_content}

    ## PARTIE 1: Tests unitaires

    PROCEDURE:
    1. Identifie les fichiers de CODE SOURCE modifies/ajoutes (exclure les fichiers de test, config, i18n, assets)
    2. Pour chaque fichier source avec de la NOUVELLE logique (nouvelles fonctions, hooks, routes, services):
       - Verifie qu'un fichier de test correspondant existe:
         - apps/api/src/**/*.ts → fichier .test.ts a cote ou dans src/test/
         - apps/app/hooks/*.ts → fichier .test.ts co-localise (hooks/useX.test.ts)
         - apps/app/lib/*.ts → fichier .test.ts co-localise (lib/x.test.ts)
         - packages/shared/src/*.ts → fichier .test.ts
       - Verifie que le test couvre les cas obligatoires (cf testing.md):
         - API: happy path, auth required, user isolation, input validation
         - Hooks: initial state, state transitions, edge cases
    3. Ne flag PAS les fichiers qui ne contiennent que du JSX/UI (composants de rendu sans logique)
    4. Ne flag PAS les modifications mineures (typos, imports, config)

    ## PARTIE 2: Tests E2E (Playwright)

    Les tests E2E sont dans apps/app/e2e/ et utilisent Playwright.
    Tests existants: login-ui.spec.ts, login.spec.ts, routing.spec.ts
    Helpers existants: e2e/helpers/navigation.ts, e2e/helpers/otp.ts

    PROCEDURE E2E:
    1. Identifie si les changements touchent un FLUX UTILISATEUR CRITIQUE:
       - Authentification (login, signup, logout, OTP)
       - Navigation principale (routing, tabs, deep links)
       - Onboarding (ecrans d'accueil, configuration initiale)
       - Flux de review (lancer une session, repondre aux cartes)
       - Flux de creation (creer un deck, ajouter des cartes)
       - Paiement / abonnement (paywall, upgrade)
    2. Pour chaque flux critique touche, verifie:
       - Un test E2E existant couvre-t-il ce flux ? (lire les fichiers dans apps/app/e2e/)
       - Le changement modifie-t-il le comportement d'un test E2E existant sans mettre a jour le test ?
       - Un NOUVEAU flux critique est-il introduit sans test E2E ?
    3. Ne flag PAS:
       - Changements purement visuels/styling
       - Changements backend-only sans impact sur le flux utilisateur
       - Refactoring interne sans changement de comportement

    REGLES DE SEVERITE:
    - Nouvelle route API sans test unitaire = WARN
    - Nouveau hook sans test unitaire = WARN
    - Nouvelle fonction utilitaire/service sans test unitaire = WARN
    - Modification mineure d'un fichier existant deja teste = PASS
    - Fichier UI pur (pas de logique) = PASS (pas besoin de test unitaire)
    - Nouveau flux utilisateur critique sans test E2E = WARN
    - Changement cassant un test E2E existant = WARN
    - Changement backend/styling sans impact sur flux = PASS (pas besoin de test E2E)

    REPONDS EXACTEMENT dans ce format:
    STATUS: PASS ou WARN
    UNCOVERED_UNIT:
    - file — description de ce qui manque (vide si PASS)
    UNCOVERED_E2E:
    - flux — description de ce qui manque (vide si PASS)
    SUMMARY: (une phrase, ex: "2 nouveaux hooks sans tests, flux login modifie sans update E2E")
```

---

### 3. Wait for All Agents

As each agent completes, store its result. Wait until ALL 6 have returned.

Store results in `{check_results}`:

```
{check_results} = {
  code_reliability: { status, issues, summary },
  refactoring: { status, suggestions, summary },
  rules: { status, violations, summary },
  typecheck_tests: { status, typecheck_status, test_status, summary },
  i18n: { status, missing_keys, summary },
  test_coverage: { status, uncovered_unit, uncovered_e2e, summary }
}
```

### 4. Proceed to Summary

Once all 6 agents have returned, immediately load step-02.

---

## SUCCESS METRICS:

✅ All 6 agents launched in ONE message (parallel)
✅ Each agent received full diff context
✅ All 6 agents completed and results collected
✅ Results stored in `{check_results}`
✅ No code analysis done by coordinator

## FAILURE MODES:

❌ Launching agents sequentially (one at a time)
❌ Not passing diff context to agents (they re-run git commands)
❌ Coordinator analyzing code instead of delegating
❌ Proceeding before all 5 agents complete
❌ **CRITICAL**: Not using `run_in_background: true` on all agents
❌ Not checking test coverage for new features

---

## NEXT STEP:

After all 6 agents return, load `./step-02-summary.md`

<critical>
Remember:
- ALL 6 agents in ONE message — this is non-negotiable for parallelism
- You are the COORDINATOR — never analyze code yourself
- Each agent needs FULL context (they can't see your conversation)
- Wait for ALL agents before proceeding
</critical>
