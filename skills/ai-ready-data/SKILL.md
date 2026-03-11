---
name: ai-ready-data
description: Assess and optimize data for AI workloads across platforms. Runs checks against workload profiles, identifies gaps, and guides remediation.
---

# AI-Ready Data

Assess data products for AI-readiness and remediate gaps. Each requirement is a self-contained directory with a check (returns 0–1 score), diagnostic (detail drill-down), fix (remediation), and metadata. Every assessment has exactly six stages named after the six factors of AI-ready data — use these exact names everywhere (reports, plans, tasks): **Clean**, **Contextual**, **Consumable**, **Current**, **Correlated**, **Compliant**.

## What This Skill Does

1. **Assess** — Run platform-specific checks against a workload profile, score each requirement, report pass/fail.
2. **Remediate** — For failing requirements, present platform-specific fixes, get approval, execute, verify.

## Conversation Flow

```
1. Platform        → user selects platform
2. Discovery       → agent asks about database, schema, tables
3. Workload        → user picks a workload profile or selects requirements
4. Adjustments     → apply overrides (skip/set/add)
5. Coverage        → show what's runnable vs N/A before executing
6. Assess          → execute checks, score, report
7. Remediate       → platform-specific fixes for failures
```

### Step 1: Platform

Ask the user what platform their data is on. Supported platforms:

- `snowflake`
- `databricks`
- `aws`
- `azure`

Load the platform reference from `platforms/` — either `platforms/{PLATFORM}.md` or `platforms/{platform}/{PLATFORM}.md`. This is your reference for all platform-specific behavior during this session.

### Step 2: Discovery

Discovery is conversational. Ask the user:

1. **What database?**
2. **What schema?**
3. **What tables?** All tables in the schema, or specific ones?

This establishes the scope for the assessment. No SQL is executed during discovery.

### Step 3: Workload

Ask the user what they want to assess:

```
What would you like to assess?
  1. RAG readiness (27 requirements)
  2. Feature serving readiness (39 requirements)
  3. Training readiness (50 requirements)
  4. Agent readiness (37 requirements)
  5. Full assessment (all 61 requirements)
  6. Let me pick specific requirements
```

If the user picks a built-in workload, load `workloads/{name}.yaml`.

If the user picks "full assessment," include all requirements from `requirements/index.yaml` with default thresholds of `0.80`.

If the user wants to pick specific requirements, present the requirement catalog grouped by factor and help them select.

### Step 4: Adjustments

After loading the workload profile, offer three adjustment verbs:

- **`skip <requirement>`** — Exclude a requirement entirely.
- **`set <requirement> <threshold>`** — Override a threshold (e.g., `set chunk_readiness 0.70`).
- **`add <requirement> <threshold>`** — Include a requirement not in the workload profile.

### Step 5: Coverage Summary

Before executing, intersect the selected requirements with what the platform can actually run. For each requirement, check if `requirements/{key}/{platform}/check.sql` exists.

Present the coverage summary:

```
{Workload} Assessment — {platform} — {DATABASE}.{SCHEMA}

Selected: {N} requirements
Runnable: {R}
Not available: {N-R} (no implementation for this platform)
  - {requirement_key}: no {platform} implementation
  - ...

Proceed?
```

**Checkpoint:** User confirms before execution begins.

### Step 6: Assess

For each stage in order (Clean, Contextual, Consumable, Current, Correlated, Compliant), for each requirement:

1. Load `requirements/{requirement_name}/requirement.yaml` for metadata (scope, placeholders, constraints).
2. Read the platform check implementation from `requirements/{requirement_name}/{platform}/`.
3. Substitute `{{ placeholder }}` values from the user's scope context (database, schema, asset, column, etc.).
4. Execute the check. Read the `value` result (float 0.0–1.0, where 1.0 is perfect).
5. Compare `value >= threshold` to determine pass/fail.
6. If no implementation exists for this platform, report `N/A`.

Implementation files use `{{ placeholder }}` syntax for variable substitution. The `scope` field in `requirement.yaml` tells you whether the check is schema-scoped, table-scoped, or column-scoped:

- **Schema-scoped** (only `database`, `schema`): run once per schema.
- **Table-scoped** (includes `asset`): run per table, aggregate results.
- **Column-scoped** (includes `column`): run per column, aggregate results.

### Step 7: Report

```
{Workload} Assessment — {platform} — {DATABASE}.{SCHEMA}

{Stage Name}                                              {PASS/FAIL}
  "{why}"
  {requirement}    {value}  (need >= {threshold})         {PASS/FAIL}

Summary: {N} of {total} stages passing ({M} of {R} requirements passing)
```

**Checkpoint:** Options: `remediate` (fix gaps), `tell-me-more` (run diagnostics), `done` (stop).

### Diagnostics

When the user wants detail on a failing requirement, resolve the platform diagnostic implementation, substitute placeholders, execute, and present the results. If unavailable, explain that diagnostics aren't available for this requirement on this platform.

---

## Remediation Workflow

Process failing stages in order. For each stage:

### Present Stage Context

```
Stage: {Stage Name}
Why:   {why}

Failing requirements:
  {requirement}: {value} (need >= {threshold})
```

### Load Fix Operations

For each failing requirement:

1. Load `requirements/{requirement_name}/requirement.yaml` for placeholders and constraints.
2. List all fix files (`fix.*`) in `requirements/{requirement_name}/{platform}/`.
3. Read each fix implementation, substitute placeholders.
4. Check the platform reference for delegation targets. If a delegation exists for this requirement, follow the delegated workflow.

### Present Remediation Plan

Show the substituted implementation, affected objects, and any constraints.

**Checkpoint:** Options: `approve` (execute), `skip` (next stage), `modify` (edit SQL), `tell-me-more` (diagnostics), `abort` (stop).

### Execute with Idempotency Guards

Before executing non-idempotent operations, check the platform reference for idempotency guards. Run the guard first; skip the operation if the desired state already exists.

Skipped guards are not failures — the desired state already exists. Never use `CREATE OR REPLACE` unless the platform documentation explicitly says it's safe for that operation.

### Verify

Re-run the platform check implementation for each requirement in the stage. Show before/after:

```
{Stage Name} — remediation complete

  {requirement}:
    Before: {old_value}
    After:  {new_value}
    Status: {PASS/FAIL}
```

### Proceed or Finish

Move to the next failing stage. After all stages:

```
Remediation Complete

Stage                    Before    After
─────                    ──────    ─────
{Stage Name}             FAIL      PASS
{Stage Name}             FAIL      PASS

What changed:
  {Stage}: {one-line summary}
```

---

## Overrides

Overrides are applied in memory for the current run. For repeatability, overrides can be saved as a custom workload profile using `extends`:

```yaml
name: my-rag-profile
extends: rag
overrides:
  skip:
    - embedding_coverage
  set:
    chunk_readiness: { min: 0.70 }
  add:
    row_access_policy: { min: 0.50 }
```

When loading a workload profile with `extends`, first load the base profile, then apply overrides.

---

## Constraints

1. **Read-only during assessment.** Never execute mutating operations during assess phases.
2. **Fix operations require approval.** Execute only with explicit user consent per stage.
3. **Never batch without consent.** Present the plan first, execute stage-by-stage with approval.
4. **Surface all constraints.** Show constraints from `requirement.yaml` before executing fix operations.
5. **No credentials in output.** Connection strings stay in environment variables.
6. **Read platform docs first.** Load the platform reference from `platforms/` before executing any operations.
7. **Use capability gating.** If platform doesn't support an operation, return `N/A` with reason.

---

## Requirement Directory Convention

Each requirement is a self-contained directory under `requirements/`:

| File Pattern | Purpose |
|---|---|
| `requirement.yaml` | Canonical metadata: name, description, factor, workload, scope, placeholders, constraints |
| `{platform}/check.*` | Platform check implementation (returns normalized score) |
| `{platform}/check.{variant}.*` | Platform check variant |
| `{platform}/diagnostic.*` | Platform diagnostic implementation |
| `{platform}/diagnostic.{variant}.*` | Platform diagnostic variant |
| `{platform}/fix.{name}.*` | Platform fix operation (mutating, requires approval) |

## File Layout

```
skills/ai-ready-data/
  SKILL.md                              ← You are here
  platforms/                            ← Platform references
    {PLATFORM}.md                       ← Capabilities, nuances, permissions, dialect
  workloads/                            ← Workload profiles
    rag.yaml
    feature-serving.yaml
    training.yaml
    agents.yaml
  requirements/                         ← One directory per requirement (61 total)
    index.yaml                          ← Requirement registry
    {requirement_key}/
      requirement.yaml                  ← Canonical metadata
      {platform}/
        check.sql
        diagnostic.sql
        fix.*.sql
```

## Adding a New Requirement

1. Create `requirements/{name}/` directory.
2. Add `requirement.yaml` with metadata: name, description, factor, workload, scope, placeholders, constraints.
3. Add platform files under `{platform}/`:
   - required: `check.sql`
   - recommended: `diagnostic.sql`
   - optional: `fix.{name}.sql`
4. Add the requirement to the relevant workload profile YAML(s) under the matching factor stage.

## Adding a New Workload Profile

1. Create `workloads/{name}.yaml` with six stages (Clean, Contextual, Consumable, Current, Correlated, Compliant).
2. Select requirements for each stage and set thresholds appropriate for the workload.
3. Alternatively, use `extends` to derive from an existing profile and apply overrides.

## Adding a New Platform

1. Create `platforms/{PLATFORM}.md` covering capabilities, dialect, permissions, nuances, idempotency guards, and delegation targets.
2. Add requirement files under `requirements/{key}/{platform}/`.
