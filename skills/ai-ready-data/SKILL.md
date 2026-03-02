---
name: ai-ready-data
description: Assess and optimize Snowflake data for AI workloads. Runs SQL checks against serving or training requirements, identifies gaps, and guides remediation.
---

# AI-Ready Data

Assess Snowflake data products for AI-readiness and remediate gaps. Works like a test suite: each requirement has a check SQL that returns a 0–1 score, a threshold from the use-case profile, and fix SQL for remediation.

## What This Skill Does

1. **Assess** — Run SQL checks against a workload profile (serving or training), score each requirement, report pass/fail.
2. **Remediate** — For failing requirements, present fix SQL, get approval, execute, verify.

## Quick Start

Ask the user:

1. **What workload?** Serving or training. Load `profiles/serving.yaml` or `profiles/training.yaml`. Default: serving.
2. **What scope?** Database, schema, and optionally specific tables.
3. **Assess or remediate?** If no prior assessment exists, assess first.

---

## Execution Model

### Phases

```
discover → assess → report → [approve] → remediate → verify
```

| Phase | What Happens | SQL Type |
|-------|-------------|----------|
| Discover | Confirm scope (database, schema, tables) | Ad-hoc |
| Assess | Run `check` SQL for each requirement in the profile | `sql/check/` (read-only) |
| Report | Present scores grouped by stage, show pass/fail | None |
| Approve | User approves remediation per stage | None |
| Remediate | Run `fix` SQL for failing requirements | `sql/fix/` (mutating) |
| Verify | Re-run `check` SQL to confirm improvement | `sql/check/` (read-only) |

### How Checks Work

All `check` SQL files return a `value` column: a float between 0.0 and 1.0.

Each requirement declares a `direction`:

- **`lte`** (lower is better): value must be ≤ `max` threshold to pass. Used by Factor 0 (Clean) requirements.
- **`gte`** (higher is better): value must be ≥ `min` threshold to pass. Used by all other factors.

Profiles declare thresholds with matching keys: `{ max: N }` for lte, `{ min: N }` for gte.

### How Profiles Work

A profile (in `profiles/`) lists stages. Each stage has a `why` and a set of requirements with thresholds. Run stages in order. A stage passes when all its requirements pass.

Load the profile YAML, then for each stage, for each requirement:

1. Load `requirements/{requirement_name}.yaml` to get the check SQL path, direction, scope, and placeholders.
2. Read the SQL file, substitute `{{ placeholder }}` values from context.
3. Execute the SQL, read the `value` column.
4. Compare against the profile threshold using the requirement's direction.

### Scope Inference

Infer execution scope from placeholders present in a SQL file:

- **Schema-scoped** (only `container`, `namespace`): run once per schema.
- **Table-scoped** (includes `asset`): run per table, aggregate results.
- **Column-scoped** (includes `field`): run per column, aggregate results.

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

For each stage in the profile (in order), for each requirement:

1. Load `requirements/{requirement_name}.yaml`.
2. Read the `check` SQL file.
3. Substitute placeholders with actual values.
4. Execute the SQL.
5. Compare `value` against the threshold.

### Step 3: Present Results

```
{Serving|Training} Assessment — {DATABASE}.{SCHEMA}

{Stage Name}                                          {PASS/FAIL}
  "{why}"
  {requirement}    {value}  (need {op} {threshold})    {PASS/FAIL}

Summary: {N} of {total} stages passing ({M} of {R} requirements passing)
```

**Checkpoint:** Options: `remediate` (fix gaps), `export` (JSON), `tell-me-more` (run diagnostics), `done` (stop).

### Diagnostics

When the user wants detail on a failing requirement, run the `diagnostic` SQL from the requirement YAML and present the results.

### JSON Export

```json
{
  "assessment": {
    "workload": "serving|training",
    "timestamp": "<ISO 8601>",
    "scope": { "database": "", "schema": "", "tables": [] },
    "summary": { "stages_passing": 0, "stages_total": 0, "requirements_passing": 0, "requirements_total": 0 },
    "stages": [
      {
        "name": "",
        "why": "",
        "status": "PASS|FAIL",
        "requirements": [
          { "key": "", "value": 0.0, "direction": "lte|gte", "threshold": 0.0, "status": "PASS|FAIL" }
        ]
      }
    ]
  }
}
```

---

## Remediation Workflow

Process failing stages in profile order. For each stage:

### Step 1: Present Stage Context

```
Stage: {Stage Name}
Why:   {why}

Failing requirements:
  {requirement}: {value} (need {op} {threshold})
```

### Step 2: Load Fix Operations

For each failing requirement:

1. Load `requirements/{requirement_name}.yaml`.
2. Read each `fixes` SQL file.
3. Substitute placeholders with actual values.
4. Check skill delegation (see below).

### Step 3: Present Remediation Plan

Show the substituted SQL, affected objects, and any constraints from the requirement YAML.

**Checkpoint:** Options: `approve` (execute), `skip` (next stage), `modify` (edit SQL), `tell-me-more` (diagnostics), `abort` (stop).

### Step 4: Execute with Idempotency Guards

Before executing non-idempotent operations, run guard queries:

| Operation | Guard Query | Skip If |
|-----------|------------|---------|
| CREATE TAG | `SHOW TAGS LIKE '{tag_name}' IN SCHEMA {namespace}` | Has rows |
| CREATE MASKING POLICY | `SHOW MASKING POLICIES LIKE '{policy_name}' IN SCHEMA {namespace}` | Has rows |
| CREATE STREAM | `SHOW STREAMS LIKE '{stream_name}' IN SCHEMA {namespace}` | Has rows |
| ALTER COLUMN SET NOT NULL | `DESCRIBE TABLE {asset}` | Column already NOT NULL |
| CREATE SEMANTIC VIEW | None — `CREATE OR REPLACE` is appropriate for declarative semantic views | N/A |

Skipped guards are not failures — the desired state already exists. Never use `CREATE OR REPLACE` unless explicitly appropriate.

### Step 5: Verify

Re-run the `check` SQL for each requirement in the stage. Show before/after:

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
| `field_masking` | `data-policy` | Before creating masking policies |
| `classification` | `sensitive-data-classification` | Before creating tags via SYSTEM$CLASSIFY |

After the delegated skill completes, return to the remediation workflow to verify.

---

## Placeholders

SQL files use `{{ placeholder }}` syntax. Substitute from context:

| Placeholder | Description |
|-------------|-------------|
| `{{ container }}` | Database name |
| `{{ namespace }}` | Schema name |
| `{{ asset }}` | Table name |
| `{{ field }}` | Column name |
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
4. **Surface all constraints.** Show constraints from the requirement YAML before executing fix operations.
5. **No credentials in output.** Connection strings stay in environment variables.
6. **Read `reference/gotchas.md`** before executing SQL to avoid common Snowflake pitfalls.
7. **Delegate to specialized skills** for `semantic_documentation`, `field_masking`, and `classification` remediation.

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
  SKILL.md                          ← You are here
  requirements/                     ← One YAML per requirement (61 total)
    data_completeness.yaml
    uniqueness.yaml
    ...
  sql/
    check/                          ← Assessment queries (read-only)
    diagnostic/                     ← Detail queries (read-only)
    fix/                            ← Remediation queries (mutating)
  profiles/
    serving.yaml                    ← Serving workload thresholds
    training.yaml                   ← Training workload thresholds
  reference/
    gotchas.md                      ← Snowflake pitfalls
```

### Adding a New Requirement

1. Create `requirements/{name}.yaml` with metadata, check/diagnostic/fix paths, placeholders, constraints.
2. Add SQL files to `sql/check/`, `sql/diagnostic/`, and/or `sql/fix/`.
3. Add a line to the relevant profile YAML.

### Adding a New Use-Case Profile

1. Create `profiles/{name}.yaml` listing stages, requirements, and thresholds.
