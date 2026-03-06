---
name: ai-ready-data
description: Assess and optimize Snowflake data for AI workloads. Runs SQL checks against workload-specific assessments, identifies gaps, and guides remediation.
---

# AI-Ready Data

Assess Snowflake data products for AI-readiness and remediate gaps. Each requirement is a self-contained directory with check SQL (returns 0–1 score), diagnostic SQL, fix SQL, and metadata. Stages map to the six factors of AI-ready data: Clean, Contextual, Consumable, Current, Correlated, Compliant.

## What This Skill Does

1. **Assess** — Run SQL checks against a workload assessment (RAG, feature serving, training, or agents), score each requirement, report pass/fail.
2. **Remediate** — For failing requirements, present fix SQL, get approval, execute, verify.

## Quick Start

Ask the user:

1. **What workload?** RAG, feature serving, training, or agents. Load `assessments/{name}.yaml`. Default: rag.
2. **What scope?** Database, schema, and optionally specific tables.
3. **Any adjustments?** User may skip, set, or add requirements before running. See [Overrides](#overrides).
4. **Assess or remediate?** If no prior assessment exists, assess first.

### Available Assessments

| Assessment | File | Best For |
|---|---|---|
| RAG | `assessments/rag.yaml` | Retrieval-augmented generation pipelines |
| Feature Serving | `assessments/feature-serving.yaml` | Online feature stores, real-time inference |
| Training | `assessments/training.yaml` | Fine-tuning, ML training, dataset curation |
| Agents | `assessments/agents.yaml` | Text-to-SQL, agentic tool use, autonomous data access |

### Overrides

After loading an assessment but before running, offer the user three adjustment verbs:

- **`skip <requirement>`** — Exclude a requirement entirely.
- **`set <requirement> <threshold>`** — Override a threshold (e.g., `set chunk_readiness 0.70`).
- **`add <requirement> <threshold>`** — Include a requirement not in the base assessment.

Overrides are applied in memory for the current run. For repeatability, overrides can be saved as a custom assessment YAML using `extends`:

```yaml
name: my-rag-assessment
extends: rag
overrides:
  skip:
    - embedding_coverage
  set:
    chunk_readiness: { min: 0.70 }
  add:
    row_access_policy: { min: 0.50 }
```

When loading an assessment with `extends`, first load the base assessment, then apply overrides.

---

## Execution Model

### Phases

```
discover → assess → report → [approve] → remediate → verify
```

| Phase | What Happens | SQL Type |
|-------|-------------|----------|
| Discover | Confirm scope (database, schema, tables) | Ad-hoc |
| Assess | Run `check.sql` for each requirement in the assessment | `requirements/{name}/check.sql` (read-only) |
| Report | Present scores grouped by stage, show pass/fail | None |
| Approve | User approves remediation per stage | None |
| Remediate | Run `fix.*.sql` for failing requirements | `requirements/{name}/fix.*.sql` (mutating) |
| Verify | Re-run `check.sql` to confirm improvement | `requirements/{name}/check.sql` (read-only) |

### How Checks Work

Every requirement directory contains a `check.sql` that returns a `value` column: a float between 0.0 and 1.0, where **1.0 is perfect**. A requirement passes when `value >= threshold`. Some requirements have variant checks (e.g., `check.sampled.sql` for large tables).

### How Assessments Work

An assessment (in `assessments/`) lists six stages — one per factor of AI-ready data: Clean, Contextual, Consumable, Current, Correlated, Compliant. Each stage has a `why` and a set of requirements with thresholds. Run stages in order. A stage passes when all its requirements pass.

Load the assessment YAML, apply any overrides, then for each stage, for each requirement:

1. Load `requirements/{requirement_name}/requirement.yaml` for metadata (scope, placeholders, constraints).
2. Read `requirements/{requirement_name}/check.sql`, substitute `{{ placeholder }}` values from context.
3. Execute the SQL, read the `value` column.
4. Compare `value >= threshold` to determine pass/fail.

### Requirement Directory Convention

Each requirement is a self-contained directory under `requirements/`. File discovery is by naming convention — no path pointers in YAML:

| File Pattern | Purpose |
|---|---|
| `requirement.yaml` | Metadata: name, description, factor, workload, scope, placeholders, constraints |
| `check.sql` | Default check query (read-only, returns 0–1 `value`) |
| `check.{variant}.sql` | Named variant check (e.g., `check.sampled.sql`, `check.column.sql`) |
| `diagnostic.sql` | Default diagnostic query (detail drill-down) |
| `diagnostic.{variant}.sql` | Named variant diagnostic (e.g., `diagnostic.untagged.sql`) |
| `fix.{name}.sql` | Fix operations (mutating, requires approval) |

### Scope Inference

Infer execution scope from placeholders present in a SQL file:

- **Schema-scoped** (only `database`, `schema`): run once per schema.
- **Table-scoped** (includes `asset`): run per table, aggregate results.
- **Column-scoped** (includes `column`): run per column, aggregate results.

For multi-run checks, the requirement's value is the aggregate (e.g., worst value across tables/columns).

---

## Assessment Workflow

### Step 1: Discover Scope

Verify the active Snowflake connection and discover what's available.

```sql
SELECT table_name, row_count, bytes / (1024*1024) AS size_mb
FROM {database}.information_schema.tables
WHERE table_schema = '{schema}'
  AND table_type = 'BASE TABLE'
ORDER BY row_count DESC
```

Present as inventory, confirm scope with the user.

**Checkpoint:** User approves scope before proceeding.

### Step 2: Run Checks

For each stage in the assessment (in order), for each requirement:

1. Load `requirements/{requirement_name}/requirement.yaml` for scope and placeholders.
2. Read `requirements/{requirement_name}/check.sql` (or a variant like `check.sampled.sql` if appropriate).
3. Substitute placeholders with actual values.
4. Execute the SQL.
5. Compare `value` against the threshold.

### Step 3: Present Results

```
{Assessment Name} Assessment — {DATABASE}.{SCHEMA}

{Stage Name (Factor)}                                 {PASS/FAIL}
  "{why}"
  {requirement}    {value}  (need {op} {threshold})    {PASS/FAIL}

Summary: {N} of {total} stages passing ({M} of {R} requirements passing)
```

**Checkpoint:** Options: `remediate` (fix gaps), `export` (JSON), `tell-me-more` (run diagnostics), `done` (stop).

### Diagnostics

When the user wants detail on a failing requirement, read `requirements/{requirement_name}/diagnostic.sql` (or a variant), substitute placeholders, execute, and present the results.

### JSON Export

```json
{
  "assessment": {
    "name": "rag|feature-serving|training|agents",
    "timestamp": "<ISO 8601>",
    "scope": { "database": "", "schema": "", "tables": [] },
    "summary": { "stages_passing": 0, "stages_total": 0, "requirements_passing": 0, "requirements_total": 0 },
    "stages": [
      {
        "name": "",
        "why": "",
        "status": "PASS|FAIL",
        "requirements": [
          { "key": "", "value": 0.0, "threshold": 0.0, "status": "PASS|FAIL" }
        ]
      }
    ]
  }
}
```

---

## Remediation Workflow

Process failing stages in assessment order. For each stage:

### Step 1: Present Stage Context

```
Stage: {Stage Name}
Why:   {why}

Failing requirements:
  {requirement}: {value} (need {op} {threshold})
```

### Step 2: Load Fix Operations

For each failing requirement:

1. Load `requirements/{requirement_name}/requirement.yaml` for placeholders and constraints.
2. List all `fix.*.sql` files in `requirements/{requirement_name}/`.
3. Read each fix SQL file, substitute placeholders with actual values.
4. Check skill delegation (see below).

### Step 3: Present Remediation Plan

Show the substituted SQL, affected objects, and any constraints from `requirement.yaml`.

**Checkpoint:** Options: `approve` (execute), `skip` (next stage), `modify` (edit SQL), `tell-me-more` (diagnostics), `abort` (stop).

### Step 4: Execute with Idempotency Guards

Before executing non-idempotent operations, run guard queries:

| Operation | Guard Query | Skip If |
|-----------|------------|---------|
| CREATE TAG | `SHOW TAGS LIKE '{tag_name}' IN SCHEMA {schema}` | Has rows |
| CREATE MASKING POLICY | `SHOW MASKING POLICIES LIKE '{policy_name}' IN SCHEMA {schema}` | Has rows |
| CREATE STREAM | `SHOW STREAMS LIKE '{stream_name}' IN SCHEMA {schema}` | Has rows |
| ALTER COLUMN SET NOT NULL | `DESCRIBE TABLE {asset}` | Column already NOT NULL |
| CREATE SEMANTIC VIEW | None — `CREATE OR REPLACE` is appropriate for declarative semantic views | N/A |

Skipped guards are not failures — the desired state already exists. Never use `CREATE OR REPLACE` unless explicitly appropriate.

### Step 5: Verify

Re-run `check.sql` for each requirement in the stage. Show before/after:

```
{Stage Name} — remediation complete

  {requirement}:
    Before: {old_value}
    After:  {new_value}
    Status: {PASS/FAIL}
```

### Step 6: Proceed or Finish

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

## Skill Delegation

When remediating certain requirements, delegate to specialized skills:

| Requirement | Delegate To | When |
|-------------|-------------|------|
| `semantic_documentation` | `semantic-view-optimization` | Before creating semantic views |
| `column_masking` | `data-policy` | Before creating masking policies |
| `classification` | `sensitive-data-classification` | Before creating tags via SYSTEM$CLASSIFY |

After the delegated skill completes, return to the remediation workflow to verify.

---

## Placeholders

SQL files use `{{ placeholder }}` syntax. Substitute from context:

| Placeholder | Description |
|-------------|-------------|
| `{{ database }}` | Database name |
| `{{ schema }}` | Schema name |
| `{{ asset }}` | Table name |
| `{{ column }}` | Column name |
| `{{ key_columns }}` | Comma-separated key columns |
| `{{ tag_name }}` | Tag identifier |
| `{{ tag_value }}` | Tag value to assign |
| `{{ allowed_values }}` | Comma-separated allowed values |
| `{{ policy_name }}` | Masking policy name |
| `{{ privileged_role }}` | Role that sees unmasked data |
| `{{ redacted_value }}` | Value shown to non-privileged users |
| `{{ data_type }}` | Column data type |
| `{{ stream_name }}` | Stream name |
| `{{ default_value }}` | Default for null replacement |
| `{{ tiebreaker_column }}` | Column for dedup ordering |
| `{{ sample_rows }}` | Rows to sample |
| `{{ clustering_columns }}` | Clustering key columns |
| `{{ freshness_threshold_hours }}` | Max age in hours |
| `{{ semantic_view_name }}` | Semantic view name |
| `{{ table_definitions }}` | TABLES clause for semantic view |
| `{{ dimension_definitions }}` | DIMENSIONS clause |
| `{{ fact_definitions }}` | FACTS clause |
| `{{ metric_definitions }}` | METRICS clause |
| `{{ relationship_definitions }}` | RELATIONSHIPS clause |
| `{{ comment }}` | Comment text |
| `{{ table_comment }}` | Table description |
| `{{ column_comment }}` | Column description |
| `{{ min_value }}` | Minimum allowed value for range checks |
| `{{ max_value }}` | Maximum allowed value for range checks |
| `{{ constraint_name }}` | Constraint identifier |
| `{{ constraint_type }}` | Constraint type (PRIMARY KEY, UNIQUE, FOREIGN KEY) |
| `{{ latency_threshold_ms }}` | Maximum acceptable query latency in milliseconds |
| `{{ placeholder_expression }}` | Expression to compute placeholder values for null replacement |
| `{{ timestamp_column }}` | Column containing event timestamps |
| `{{ expected_type }}` | Expected data type for schema conformity checks |
| `{{ reference_table }}` | Target table for referential integrity checks |

---

## Constraints

1. **Read-only during assessment.** Never CREATE, INSERT, UPDATE, DELETE, or DROP during assess/discover phases.
2. **Fix operations require approval.** Execute only with explicit user consent per stage.
3. **Never batch without consent.** Present the plan first, execute stage-by-stage with approval.
4. **Surface all constraints.** Show constraints from `requirement.yaml` before executing fix operations.
5. **No credentials in output.** Connection strings stay in environment variables.
6. **Read `reference/gotchas.md`** before executing SQL to avoid common Snowflake pitfalls.
7. **Delegate to specialized skills** for `semantic_documentation`, `column_masking`, and `classification` remediation.

---

## Snowflake Gotchas

Critical pitfalls — see `reference/gotchas.md` for full details. Key ones:

- **SHOW + RESULT_SCAN same session.** `SHOW TABLES` + `RESULT_SCAN` must run in the same session or RESULT_SCAN fails.
- **Lowercase quoted columns.** SHOW command results use lowercase quoted names: `"change_tracking"`, not `CHANGE_TRACKING`.
- **change_tracking not in information_schema.** Must use `SHOW TABLES` + `RESULT_SCAN`.
- **account_usage ~2 hour latency.** `tag_references` and `policy_references` lag for new objects.
- **tag_references has no `deleted` column.** Don't filter on it.
- **policy_references column names.** Use `ref_column_name`, not `column_name`.
- **Masking: IS_ROLE_IN_SESSION.** Never use `CURRENT_ROLE()` — it breaks role hierarchy.
- **No ALTER COLUMN SET DEFAULT.** Snowflake doesn't support it.
- **Semantic view syntax.** Uses TABLES, RELATIONSHIPS, FACTS, DIMENSIONS, METRICS — no COLUMNS clause.

### Required Permissions

| Access | Minimum Grant |
|--------|--------------|
| `information_schema.*` | USAGE on schema |
| `snowflake.account_usage.tag_references` | IMPORTED PRIVILEGES on SNOWFLAKE database |
| `snowflake.account_usage.policy_references` | IMPORTED PRIVILEGES on SNOWFLAKE database |
| `snowflake.account_usage.access_history` | IMPORTED PRIVILEGES on SNOWFLAKE database |
| `SNOWFLAKE.CORTEX.*` | USAGE on SNOWFLAKE.CORTEX schema |
| `SNOWFLAKE.CORE.*` (DMFs) | USAGE on SNOWFLAKE.CORE schema |

---

## File Layout

```
skills/ai-ready-data/
  SKILL.md                              ← You are here
  requirements/                         ← One directory per requirement (61 total)
    data_completeness/
      requirement.yaml                  ← Metadata (no SQL paths)
      check.sql                         ← Default check query
      check.sampled.sql                 ← Variant for large tables
      diagnostic.sql                    ← Detail drill-down
      fix.fill-default.sql              ← Fix: fill nulls with default
      fix.fill-placeholder.sql          ← Fix: fill nulls with expression
      fix.delete-incomplete.sql         ← Fix: delete null rows
      fix.add-not-null.sql              ← Fix: add NOT NULL constraint
    uniqueness/
      requirement.yaml
      check.sql
      check.sampled.sql
      diagnostic.sql
      fix.deduplicate-keep-first.sql
      fix.deduplicate-keep-last.sql
    ...
  assessments/
    rag.yaml                            ← RAG workload assessment
    feature-serving.yaml                ← Feature serving workload assessment
    training.yaml                       ← Training workload assessment
    agents.yaml                         ← Agents workload assessment
  reference/
    gotchas.md                          ← Snowflake pitfalls
```

### Adding a New Requirement

1. Create `requirements/{name}/` directory.
2. Add `requirement.yaml` with metadata: name, description, factor, workload, scope, placeholders, constraints.
3. Add `check.sql` (required), `diagnostic.sql`, and any `fix.{name}.sql` files.
4. Add the requirement to the relevant assessment YAML(s) under the matching factor stage.

### Adding a New Assessment

1. Create `assessments/{name}.yaml` with six stages (Clean, Contextual, Consumable, Current, Correlated, Compliant).
2. Select requirements for each stage and set thresholds appropriate for the workload.
3. Alternatively, use `extends` to derive from an existing assessment and apply overrides.

Or use the **Build Assessment** skill (`skills/build-assessment/SKILL.md`) — a guided conversation that interviews the user and generates the YAML.
