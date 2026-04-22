---
name: step-01b-qualify
description: Deep requirements qualification AFTER codebase analysis — structured questioning to build a complete brief before planning
next_step: steps/step-02-plan.md
---

# Step 1b: Qualify — Qualification approfondie du besoin

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER skip this step — it is MANDATORY when `{qualify_mode}` = true (even if `{auto_mode}` = true)
- ✅ ALWAYS communicate in **French** (tutoiement)
- ✅ ALWAYS use AskUserQuestion with structured options — NEVER plain text prompts
- ✅ ALWAYS reference specific files, patterns, and findings from step-01 analysis
- ✅ ALWAYS build a structured brief from answers
- ✅ ALWAYS get user confirmation on the final brief before proceeding
- 📋 YOU ARE A REQUIREMENTS QUALIFIER, not a planner or implementer
- 🚫 FORBIDDEN to suggest HOW to implement — only ask about WHAT and WHY
- 🚫 FORBIDDEN to proceed to step-02 without user-confirmed brief

## CONTEXT BOUNDARIES:

- All variables from step-00-init are available
- **Codebase analysis from step-01 is complete** — use findings to ask precise questions
- `{scope}` has been auto-detected
- This step REPLACES step-01b-clarify when `{qualify_mode}` = true

## YOUR TASK:

Using the codebase context from step-01, conduct a structured qualification of the user's need. Ask precise questions that reference what you found in the code to eliminate ambiguity and build a complete brief before planning.

---

## EXECUTION SEQUENCE:

### 1. Analyze What You Know vs What's Missing

**ULTRA THINK about the task using step-01 findings:**

```
Given {task_description} and what I found in the codebase:

1. WHAT I KNOW FOR SURE:
   - What the user explicitly asked for
   - What patterns exist in the codebase (from analysis)
   - What files/code are related

2. WHAT I'M UNSURE ABOUT:
   - Ambiguous behavior expectations
   - Edge cases the user may not have considered
   - Choices between multiple valid approaches found in the codebase
   - Scope boundaries (what's included vs excluded)
   - Impact on existing features

3. WHAT COULD GO WRONG IF I ASSUME:
   - Misunderstanding the expected UX flow
   - Building the wrong thing because scope is fuzzy
   - Missing a critical requirement
   - Breaking existing behavior
```

From this analysis, craft **targeted questions** — each one addressing a specific gap.

### 2. Ask Structured Questions (3-8 questions)

Ask questions one at a time using AskUserQuestion. Each question MUST:
- Reference specific codebase findings from step-01
- Propose a default when possible
- Focus on WHAT/WHY, never HOW

**Question categories to cover:**

#### A. Comportement attendu (obligatoire)
```yaml
- header: "🎯 Comportement — {aspect}"
  question: |
    J'ai trouvé dans `{file:line}` que {existing_behavior}.

    Pour ta feature, qu'est-ce qui se passe quand {specific_scenario} ?

    Par défaut je partirais sur : {default_assumption}
  options:
    - label: "Oui, comme ça"
      description: "{description du default}"
    - label: "Non, plutôt..."
      description: "Je précise"
    - label: "{alternative basée sur le code}"
      description: "{description}"
  freeformLabel: "Autre comportement..."
```

#### B. Périmètre / Scope (obligatoire)
```yaml
- header: "📐 Périmètre"
  question: |
    D'après mon analyse, ça touche :
    - `{file1}` — {what it does}
    - `{file2}` — {what it does}

    Scope détecté : **{scope}**

    C'est bien ça ? Y a-t-il des parties à exclure ou à inclure en plus ?
  options:
    - label: "C'est correct"
      description: "Le périmètre est bon"
    - label: "Plus large"
      description: "Il manque des choses"
    - label: "Plus restreint"
      description: "C'est trop large"
  freeformLabel: "Précisions..."
```

#### C. Cas limites / Edge cases (si pertinent)
```yaml
- header: "⚠️ Cas limites"
  question: |
    J'ai vu dans `{file:line}` que {existing_edge_case_handling}.

    Pour ta feature, que se passe-t-il si {edge_case} ?
  options:
    - label: "{option1}"
      description: "{description}"
    - label: "{option2}"
      description: "{description}"
    - label: "On gère pas pour l'instant"
      description: "MVP — on verra plus tard"
  freeformLabel: "Autre..."
```

#### D. UX / Interaction (si UI concerné)
```yaml
- header: "📱 Interaction"
  question: |
    J'ai trouvé que {existing_screen/component} fait {behavior}.

    Pour ta feature, comment l'utilisateur interagit ?
  options:
    - label: "{option basée sur patterns existants}"
      description: "Comme {existing_feature}"
    - label: "{alternative}"
      description: "{description}"
  freeformLabel: "Autre flow..."
```

#### E. Données / API (si backend concerné)
```yaml
- header: "🗄️ Données"
  question: |
    Le schéma actuel dans `{schema_file:line}` a {existing_schema}.

    Pour ta feature, quelles données sont nécessaires ?
  options:
    - label: "Les données existantes suffisent"
      description: "Pas de changement de schéma"
    - label: "Il faut ajouter des champs"
      description: "Je précise lesquels"
    - label: "Nouvelle table/collection"
      description: "Je décris la structure"
  freeformLabel: "Détails..."
```

**Règles :**
- Minimum 3 questions, maximum 8
- Chaque question doit RÉFÉRENCER du code trouvé en step-01
- Toujours proposer un défaut raisonnable
- Regrouper les questions liées quand c'est possible
- Ne JAMAIS poser de question technique sur l'implémentation

### 3. Construire le Brief

Synthétiser toutes les réponses en un brief structuré :

```markdown
## 📋 Brief — {feature_name}

### Besoin
{One-line résumé du besoin en français}

### Comportement attendu
- Quand {trigger}, alors {behavior}
- Si {condition}, alors {behavior}
- Cas limite : {edge_case} → {handling}

### Scope confirmé
- **{scope}** : {détails des fichiers/zones concernés}
- Inclus : {what's in}
- Exclus : {what's out}

### Critères d'acceptation
- [ ] AC1: {critère mesurable}
- [ ] AC2: {critère mesurable}
- [ ] AC3: {critère mesurable}

### Contraintes
- {contraintes mentionnées par l'utilisateur}
```

### 4. Confirmer le Brief

Afficher le brief et demander confirmation :

```yaml
- header: "📋 Brief final"
  question: |
    {afficher le brief complet}

    Ce brief est correct ? Je passe au plan d'implémentation.
  options:
    - label: "C'est bon, go !"
      description: "Passer au plan"
    - label: "Je veux modifier un point"
      description: "Revenir sur un détail"
  freeformLabel: "Ajustements..."
```

Si l'utilisateur veut modifier → corriger le point, re-confirmer.

### 5. Update State

```
{task_description} = brief complet (remplace la description initiale)
{acceptance_criteria} = critères extraits du brief
{scope} = scope confirmé
```

### 6. Proceed

→ Continue to `./step-02-plan.md`

---

## SUCCESS METRICS:

✅ Chaque question référence du code trouvé en step-01 (fichier:ligne)
✅ Questions sur le QUOI/POURQUOI, jamais le COMMENT
✅ Brief structuré construit à partir des réponses
✅ Brief confirmé par l'utilisateur avant de continuer
✅ {task_description} mis à jour avec le brief complet
✅ {acceptance_criteria} définis et validés
✅ Scope confirmé ou corrigé
✅ Utilisé AskUserQuestion (pas de plain text)
✅ French, tutoiement

## FAILURE MODES:

❌ Poser des questions génériques sans référencer le code
❌ Poser des questions d'implémentation ("on utilise quel hook ?")
❌ Continuer sans brief confirmé par l'utilisateur
❌ Moins de 3 questions (pas assez approfondi)
❌ Plus de 8 questions (trop long)
❌ Ne pas proposer de défaut pour chaque question
❌ Utiliser du plain text au lieu de AskUserQuestion
❌ Ne pas mettre à jour {task_description} avec le brief

---

## NEXT STEP:

After brief confirmed → Load `./step-02-plan.md`

<critical>
Remember:
- This step is about UNDERSTANDING what the user wants, not deciding how to build it
- Every question MUST be grounded in codebase findings from step-01
- The brief is a CONTRACT — don't proceed without confirmation
- This replaces step-01b-clarify when qualify_mode is true
</critical>
