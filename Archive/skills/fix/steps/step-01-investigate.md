---
name: step-01-investigate
description: Launch 4 investigation agents in parallel and collect results
prev_step: steps/step-00-init.md
next_step: steps/step-02-synthesis.md
---

# Step 1: Parallel Investigation

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER run agents sequentially — ALL 4 in ONE message
- 🛑 NEVER investigate code yourself — delegate to agents
- ✅ ALWAYS launch all 5 agents with `run_in_background: true`
- ✅ ALWAYS pass full context from step-00 to each agent prompt
- ✅ ALWAYS communicate in **French** with the user
- 📋 YOU ARE A COORDINATOR, not an investigator
- 💬 FOCUS on launching agents and collecting results
- 🚫 FORBIDDEN to read/analyze code yourself

## EXECUTION PROTOCOLS:

- 🎯 Launch all 5 agents in a single message
- 📖 Each agent gets full context (they can't see your conversation)
- 🚫 FORBIDDEN to read/analyze code yourself
- ✅ Wait for all agents to complete before proceeding
- ✅ Skip agents that are not relevant (e.g., DB agent if `{needs_db}` = false)

## CONTEXT BOUNDARIES:

- State variables from step-00 are available: `{bug_description}`, `{scope_files}`, `{scope_modules}`, `{related_tests}`, `{needs_db}`, `{needs_runtime}`, `{needs_revenuecat}`, `{needs_posthog}`, `{posthog_email}`, `{deep_mode}`
- You have the scope — pass it to agents, don't re-search
- Agents return structured results to collect

## YOUR TASK:

Launch 4 independent investigation agents in parallel, wait for all results, and store them in `{investigation_results}`.

---

<available_state>
From step-00:

| Variable | Description |
|----------|-------------|
| `{auto_mode}` | Skip confirmations |
| `{deep_mode}` | Exhaustive investigation |
| `{bug_description}` | User's bug description |
| `{scope_files}` | Files identified as relevant |
| `{scope_modules}` | Modules involved (apps/api, apps/app, etc.) |
| `{related_tests}` | Test files related to scope |
| `{needs_db}` | Whether DB investigation is needed |
| `{needs_runtime}` | Whether runtime/UI investigation is needed |
| `{needs_revenuecat}` | Whether RevenueCat investigation is needed |
</available_state>

---

## EXECUTION SEQUENCE:

### 1. Announce Launch

```
Lancement de 5 agents d'investigation en parallele...
```

### 2. Launch ALL 4 Agents in ONE Message

<critical>
ALL 4 Agent tool calls MUST be in a SINGLE message.
Each with `run_in_background: true`.
This is CRITICAL for true parallelism.
If an agent is not needed (e.g., DB agent when {needs_db} = false), still launch it but tell it to return PASS immediately.
</critical>

---

#### Agent 1: Code Tracer

```
Agent:
  subagent_type: "feature-dev:code-explorer"
  run_in_background: true
  description: "Code tracer"
  prompt: |
    Tu es un debugger expert. Tu traces le chemin d'execution d'un bug pour trouver sa cause root.

    ## Bug
    {bug_description}

    ## Fichiers concernes
    {scope_files}

    ## Modules
    {scope_modules}

    ## Projet
    C'est un monorepo avec:
    - apps/api/ — Fastify + tRPC backend, Drizzle ORM, PostgreSQL
    - apps/app/ — Expo React Native (mobile + web)
    - packages/shared/ — Zod schemas et types partages
    - services/ai-worker/ — Python AI worker

    ## Regles du projet
    Lis les fichiers .claude/rules/*.md pour comprendre les conventions:
    - api.md, drizzle.md, expo.md, typescript.md, testing.md

    PROCEDURE:
    1. Lis EN ENTIER chaque fichier identifie comme concerne
    2. Trace le chemin d'execution du bug:
       - Point d'entree (route API, handler, composant, hook)
       - Flux de donnees (props, state, DB queries, mutations)
       - Conditions et branches qui pourraient causer le bug
    3. Identifie les suspects:
       - Code qui semble incorrect ou fragile
       - Conditions non gerees (null, undefined, edge cases)
       - Race conditions ou problemes de timing
       - Logique inversee ou manquante
    4. {deep_mode_instruction}

    REPONDS EXACTEMENT dans ce format:
    EXECUTION_PATH:
    - step: description (file:line)
    SUSPECTS:
    - file:line — description du probleme potentiel (confiance: 0-100%)
    ROOT_CAUSE_HYPOTHESIS: (ta meilleure hypothese en une phrase)
    EVIDENCE: (les preuves qui supportent ton hypothese)
```

**Note:** Replace `{deep_mode_instruction}` with:
- If `{deep_mode}` = true: `"Trace AUSSI les chemins adjacents — imports, fonctions appelees, composants parents/enfants. Lis le contexte large."`
- If `{deep_mode}` = false: `"Focus sur le chemin principal seulement."`

---

#### Agent 2: Test Runner

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "Test runner"
  prompt: |
    Tu lances les tests lies a un bug et analyses les resultats.

    ## Bug
    {bug_description}

    ## Tests lies
    {related_tests}

    ## Modules concernes
    {scope_modules}

    ## Projet root
    Le projet est dans: {project_root}

    PROCEDURE:
    1. Lance les tests du scope:
       - Si des tests specifiques sont identifies: lance-les individuellement
       - Sinon: lance `pnpm --filter @diane/api test` ou `pnpm --filter @diane/app test` selon le module
    2. Analyse les resultats:
       - Tests qui FAIL → description precise de l'erreur
       - Tests qui PASS mais ne couvrent pas le cas du bug → note le gap
    3. Si aucun test ne couvre le bug:
       - Identifie quel test manque
       - Decris ce qu'il devrait verifier

    REPONDS EXACTEMENT dans ce format:
    TEST_STATUS: PASS, FAIL ou NO_COVERAGE
    FAILING_TESTS:
    - test_name — error message (vide si tous passent)
    COVERAGE_GAPS:
    - description de ce qui n'est pas teste
    RELEVANT_FINDINGS:
    - toute observation utile des resultats de tests
    SUMMARY: (une phrase)
```

---

#### Agent 3: DB Inspector

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "DB inspector"
  prompt: |
    Tu inspectes la base de donnees pour trouver des indices sur un bug.

    ## Bug
    {bug_description}

    ## Fichiers concernes
    {scope_files}

    ## Investigation DB requise
    {needs_db}

    Si {needs_db} = false:
    → Reponds simplement: STATUS: SKIPPED, SUMMARY: "Pas d'investigation DB necessaire"

    Si {needs_db} = true:

    ## MCP disponibles
    - `mcp__postgres-prod__query` — requeter la DB production (SELECT ONLY)
    - `mcp__postgres-local__query` — requeter la DB locale

    ## Schema DB
    Le schema est dans apps/api/src/db/schema.ts — lis-le d'abord pour comprendre les tables.

    PROCEDURE:
    1. Lis le schema DB pour identifier les tables concernees
    2. Lis le code des fichiers concernes pour comprendre les queries attendues
    3. Ecris des requetes SELECT pour verifier:
       - Les donnees existent-elles comme attendu ?
       - Y a-t-il des NULL inattendus ?
       - Les relations FK sont-elles coherentes ?
       - Les timestamps sont-ils logiques ?
    4. Execute les requetes via MCP (prod d'abord, local en fallback)
    5. Compare les resultats avec ce que le code attend

    ⚠️ SECURITE: SELECT ONLY — jamais d'UPDATE/DELETE/INSERT

    REPONDS EXACTEMENT dans ce format:
    STATUS: PASS, ISSUE_FOUND ou SKIPPED
    QUERIES_RUN:
    - query — resultat resume
    DATA_ISSUES:
    - description du probleme de donnees (vide si PASS)
    SUMMARY: (une phrase)
```

---

#### Agent 4: Runtime Inspector

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "Runtime inspector"
  prompt: |
    Tu inspectes l'environnement runtime pour trouver des indices sur un bug.

    ## Bug
    {bug_description}

    ## Fichiers concernes
    {scope_files}

    ## Investigation runtime requise
    {needs_runtime}

    ## Investigation RevenueCat requise
    {needs_revenuecat}

    Si {needs_runtime} = false ET {needs_revenuecat} = false:
    → Reponds simplement: STATUS: SKIPPED, SUMMARY: "Pas d'investigation runtime necessaire"

    ## MCP disponibles
    - `mcp__chrome-devtools__*` — Console, network, screenshots du navigateur
    - `mcp__dokploy__*` — Logs de deploiement, status des apps
    - `mcp__revenuecat__*` — Subscriptions, entitlements, offerings, customers

    PROCEDURE:

    **Si {needs_runtime} = true (bug UI/frontend):**
    1. Utilise chrome-devtools pour:
       - Lire les messages console (errors, warnings)
       - Checker les requetes network (failures, slow, wrong data)
       - Prendre un screenshot si pertinent
    2. Cherche des patterns:
       - Erreurs JS dans la console
       - Requetes API qui fail (4xx, 5xx)
       - Donnees inattendues dans les responses

    **Si {needs_revenuecat} = true (bug payments/subscription):**
    1. Utilise les outils RevenueCat MCP pour:
       - Checker les offerings actuelles (`get-offering`, `list-offerings`)
       - Verifier les entitlements (`get-entitlement`, `list-entitlements`)
       - Checker un customer specifique si un userId est mentionne (`get-customer`)
       - Verifier les produits (`list-products`, `get-product`)
    2. Compare avec ce que le code attend

    **Si bug deploiement:**
    1. Utilise dokploy pour checker:
       - Status de l'app (`application-one`)
       - Logs recents

    REPONDS EXACTEMENT dans ce format:
    STATUS: PASS, ISSUE_FOUND ou SKIPPED
    CONSOLE_ERRORS:
    - error message (vide si aucun)
    NETWORK_ISSUES:
    - endpoint — status — description (vide si aucun)
    REVENUECAT_ISSUES:
    - description (vide si aucun ou non verifie)
    DEPLOY_ISSUES:
    - description (vide si aucun ou non verifie)
    SUMMARY: (une phrase)
```

---

#### Agent 5: PostHog Inspector

```
Agent:
  subagent_type: "general-purpose"
  run_in_background: true
  description: "PostHog inspector"
  prompt: |
    Tu inspectes les donnees PostHog (analytics/exceptions) pour un user specifique afin de trouver des indices sur un bug.

    ## Bug
    {bug_description}

    ## Investigation PostHog requise
    {needs_posthog}

    ## Email utilisateur
    {posthog_email}

    Si {needs_posthog} = false:
    → Reponds simplement: STATUS: SKIPPED, SUMMARY: "Pas d'investigation PostHog necessaire"

    Si {needs_posthog} = true:

    ## API PostHog (self-hosted)
    L'instance PostHog est a https://ph.diane.app
    La cle API est dans la variable d'environnement POSTHOG_API_KEY (Bearer token).

    ## PROCEDURE:

    1. **Trouver le user** — Cherche par email:
       ```bash
       curl -s "https://ph.diane.app/api/projects/1/persons/?search={posthog_email}" \
         -H "Authorization: Bearer $POSTHOG_API_KEY" | python3 -c "
       import sys,json
       d=json.load(sys.stdin)
       for p in d.get('results',[]):
           print('Person ID:', p.get('id'))
           print('Distinct IDs:', p.get('distinct_ids'))
       "
       ```

    2. **Chercher les exceptions** — Utilise le distinct_id (UUID interne, pas l'email) pour filtrer:
       ```bash
       curl -s "https://ph.diane.app/api/projects/1/events/?distinct_id={DISTINCT_ID}&event=\$exception&limit=20" \
         -H "Authorization: Bearer $POSTHOG_API_KEY" | python3 -c "
       import sys,json
       d=json.load(sys.stdin)
       for r in d.get('results',[]):
           ts = r.get('timestamp','')
           props = r.get('properties',{})
           exc_types = props.get('\$exception_types', [])
           exc_values = props.get('\$exception_values', [])
           print(f'{ts} | {exc_types}: {str(exc_values)[:300]}')
       "
       ```

    3. **Chercher des events specifiques** lies au bug (upload, image, source, etc.):
       ```bash
       curl -s "https://ph.diane.app/api/projects/1/events/?person_id={PERSON_ID}&limit=100" \
         -H "Authorization: Bearer $POSTHOG_API_KEY" | python3 -c "
       import sys,json
       d=json.load(sys.stdin)
       events = set()
       for r in d.get('results',[]): events.add(r.get('event',''))
       for e in sorted(events): print(e)
       "
       ```

    4. **Analyser** les resultats:
       - Exceptions recentes liees au bug ?
       - Events manquants (le user n'a pas declenche l'action attendue) ?
       - Patterns d'erreurs repetees ?
       - Quelle app/plateforme le user utilise (Expo vs Ionic) ?

    ⚠️ SECURITE: API en lecture seule (GET only)

    REPONDS EXACTEMENT dans ce format:
    STATUS: PASS, ISSUE_FOUND ou SKIPPED
    USER_FOUND: oui/non (person_id si oui)
    EXCEPTIONS:
    - timestamp — type: message (vide si aucune)
    RELEVANT_EVENTS:
    - event_name — count ou details
    USER_PLATFORM: (Expo/Ionic/Web/unknown)
    SUMMARY: (une phrase)
```

---

### 3. Wait for All Agents

As each agent completes, store its result. Wait until ALL 4 have returned.

Store results in `{investigation_results}`:

```
{investigation_results} = {
  code_tracer: { execution_path, suspects, root_cause_hypothesis, evidence },
  test_runner: { test_status, failing_tests, coverage_gaps, findings, summary },
  db_inspector: { status, queries_run, data_issues, summary },
  runtime_inspector: { status, console_errors, network_issues, revenuecat_issues, deploy_issues, summary },
  posthog_inspector: { status, user_found, exceptions, relevant_events, user_platform, summary }
}
```

### 4. Proceed to Synthesis

Once all 5 agents have returned, immediately load step-02.

---

## SUCCESS METRICS:

✅ All 5 agents launched in ONE message (parallel)
✅ Each agent received full context (bug description, scope, MCP instructions)
✅ Irrelevant agents told to SKIP (not omitted)
✅ All 5 agents completed and results collected
✅ Results stored in `{investigation_results}`
✅ No code analysis done by coordinator

## FAILURE MODES:

❌ Launching agents sequentially (one at a time)
❌ Not passing scope context to agents
❌ Coordinator analyzing code instead of delegating
❌ Proceeding before all 5 agents complete
❌ **CRITICAL**: Not using `run_in_background: true` on all agents
❌ Not giving MCP tool names to agents that need them

---

## NEXT STEP:

After all 5 agents return, load `./step-02-synthesis.md`

<critical>
Remember:
- ALL 5 agents in ONE message — this is non-negotiable for parallelism
- You are the COORDINATOR — never analyze code yourself
- Each agent needs FULL context (they can't see your conversation)
- Give MCP tool names explicitly — agents don't know what's available
- Wait for ALL agents before proceeding
</critical>
