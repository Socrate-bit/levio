---
name: fix
description: Debug et diagnostic de bugs — lance 5 agents en parallele (code tracer, test runner, DB inspector, runtime inspector) puis propose un fix. Use when investigating bugs, runtime errors, unexpected behavior, or data issues.
argument-hint: "<description du bug> [-a] [-d]"
---

<objective>
Diagnostiquer un bug decrit par l'utilisateur en lancant 4 agents d'investigation en parallele, puis proposer un fix precis sans l'appliquer.
</objective>

<quick_start>

```bash
/fix "le bouton partager crash sur iOS"          # Interactif
/fix -a "l'onboarding skip la step 3"            # Auto — propose le fix direct
/fix -d "les XP ne s'incrementent plus"          # Deep — investigation exhaustive
```

</quick_start>

<flags>

| ON | OFF | Long | Description |
|----|-----|------|-------------|
| `-a` | `-A` | `--auto` | Skip confirmations, propose fix directement |
| `-d` | `-D` | `--deep` | Investigation exhaustive (plus d'agents, plus de contexte) |

**Parsing:** Defaults all false. Premier argument positionnel = description du bug.

</flags>

<workflow>

1. **Init** — Parse flags, comprendre le bug, identifier le scope (fichiers/modules concernes)
2. **Parallel Investigation** — Lance 4 agents simultanement:
   - Code Tracer: trace le chemin d'execution, cherche la cause root
   - Test Runner: lance les tests du scope, analyse les failures
   - DB Inspector: requete les DB local/prod si le bug implique des donnees (MCP postgres)
   - Runtime Inspector: check console/network/logs si bug UI (MCP chrome-devtools, dokploy, revenuecat)
   - PostHog Inspector: check exceptions, events, sessions d'un user specifique via API REST PostHog
3. **Synthesis** — Croise les resultats des 4 agents, identifie la cause root
4. **Fix Proposal** — Propose un fix precis avec le code a modifier (sans l'appliquer)

</workflow>

<step_files>

| Step | File | Purpose |
|------|------|---------|
| 00 | `steps/step-00-init.md` | Parse flags, comprendre le bug, identifier le scope |
| 01 | `steps/step-01-investigate.md` | Lance 4 agents d'investigation en parallele |
| 02 | `steps/step-02-synthesis.md` | Croise les resultats, identifie la cause root |
| 03 | `steps/step-03-fix-proposal.md` | Propose le fix avec code precis |

</step_files>

<state_variables>

| Variable | Type | Set by |
|----------|------|--------|
| `{auto_mode}` | boolean | step-00 |
| `{deep_mode}` | boolean | step-00 |
| `{bug_description}` | string | step-00 |
| `{scope_files}` | string | step-00 |
| `{scope_modules}` | string | step-00 |
| `{related_tests}` | string | step-00 |
| `{needs_db}` | boolean | step-00 |
| `{needs_runtime}` | boolean | step-00 |
| `{needs_revenuecat}` | boolean | step-00 |
| `{needs_posthog}` | boolean | step-00 |
| `{posthog_email}` | string | step-00 |
| `{investigation_results}` | object | step-01 |
| `{root_cause}` | string | step-02 |
| `{fix_proposal}` | object | step-03 |

</state_variables>

<mcp_tools>

Les agents peuvent utiliser ces MCP selon le besoin:

| MCP | Usage | Quand |
|-----|-------|-------|
| `postgres-local` | Requetes DB locale | Toujours disponible |
| `postgres-prod` | Requetes DB production | Quand `{needs_db}` = true |
| `chrome-devtools` | Console, network, screenshots | Quand `{needs_runtime}` = true et bug UI |
| `dokploy` | Logs de deploiement, status | Quand bug lie au deploiement |
| `revenuecat` | Subscriptions, entitlements, offerings | Quand `{needs_revenuecat}` = true |
| `posthog` (API REST) | Exceptions, events, sessions d'un user | Quand `{needs_posthog}` = true |

</mcp_tools>

<execution_rules>

- **Load one step at a time** (progressive loading)
- **Persist state variables** across all steps
- **Follow next_step directive** at end of each step
- **Launch ALL 4 agents in ONE message** for true parallelism
- **Ne JAMAIS appliquer le fix** — proposer seulement
- **Always communicate in French** with the user
- **Utiliser les MCP** quand le contexte du bug le requiert

</execution_rules>

<entry_point>
**FIRST ACTION:** Load `steps/step-00-init.md`
</entry_point>
