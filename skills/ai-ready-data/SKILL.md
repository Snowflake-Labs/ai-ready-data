---
name: ai-ready-data
description: Assess and optimize Snowflake data for AI workloads. Runs SQL checks against workload-specific assessments, identifies gaps, and guides remediation.
---

# AI-Ready Data

Assess Snowflake data products for AI-readiness and remediate gaps. Each requirement is a self-contained directory with check SQL (returns 0–1 score), diagnostic SQL, fix SQL, and metadata. Every assessment has exactly six stages named after the six factors of AI-ready data — use these exact names everywhere (reports, plans, tasks): **Clean**, **Contextual**, **Consumable**, **Current**, **Correlated**, **Compliant**.

## What This Skill Does

1. **Assess** — Run SQL checks against a workload assessment (RAG, feature serving, training, or agents), score each requirement, report pass/fail.
2. **Remediate** — For failing requirements, present fix SQL, get approval, execute, verify.

## Quick Start

Ask the user:

1. **What platform?** `snowflake`, `databricks`, `aws`, or `azure`. Default: `snowflake`.
2. **What workload?** RAG, feature serving, training, or agents. Load `assessments/{name}.yaml`. Default: rag.
3. **What scope?** Database, schema, and optionally specific tables.
4. **Any adjustments?** User may skip, set, or add requirements before running. See [Overrides](#overrides).
5. **Assess or remediate?** If no prior assessment exists, assess first.

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

| Phase | What Happens | Implementation Type |
|-------|-------------|---------------------|
| Discover | Confirm scope (database, schema, tables) | Platform metadata queries |
| Assess | Run platform `check` implementation for each requirement | `requirements/{name}/implementations/{platform}/check*.sql` |
| Report | Present scores grouped by stage, show pass/fail | None |
| Approve | User approves remediation per stage | None |
| Remediate | Run platform `fix` implementations for failing requirements | `requirements/{name}/implementations/{platform}/fix.*.sql` |
| Verify | Re-run platform `check` implementation | `requirements/{name}/implementations/{platform}/check*.sql` |

### How Checks Work

The default implementation contract expects a check to return a `value` column: a float between 0.0 and 1.0, where **1.0 is perfect**. A requirement passes when `value >= threshold`. Some requirements have variant checks (e.g., `check.sampled.sql` for large tables).

### How Assessments Work

An assessment (in `assessments/`) lists exactly six stages — one per factor of AI-ready data. The stage names **are** the factor names and must be used exactly as written in the YAML:

1. **Clean**
2. **Contextual**
3. **Consumable**
4. **Current**
5. **Correlated**
6. **Compliant**

Do NOT rename, paraphrase, or invent alternative stage names. Use the `name` field from each stage entry in the assessment YAML verbatim. Each stage has a `why` and a set of requirements with thresholds. Run stages in order. A stage passes when all its requirements pass.

Load the assessment YAML, apply any overrides, then for each stage, for each requirement:

1. Load `requirements/{requirement_name}/requirement.yaml` for metadata (scope, placeholders, constraints).
2. Resolve implementation path by platform:
   - Required: `requirements/{requirement_name}/implementations/{platform}/check.sql`
   - Optional variant: `requirements/{requirement_name}/implementations/{platform}/check.{variant}.sql`
3. Substitute `{{ placeholder }}` values from context.
4. Execute and read the normalized result (`value`, `status`, optional `reason`).
5. If capability or implementation is unavailable, return `N/A` with reason (do not force FAIL).

### Requirement Directory Convention

Each requirement is a self-contained directory under `requirements/`. Keep canonical metadata in `requirement.yaml`, and implementation files under platform folders:

| File Pattern | Purpose |
|---|---|
| `requirement.yaml` | Canonical metadata: name, description, factor, workload, scope, placeholders, constraints |
| `implementations/{platform}/check.sql` | Platform check query (returns normalized score) |
| `implementations/{platform}/check.{variant}.sql` | Platform check variant |
| `implementations/{platform}/diagnostic.sql` | Platform diagnostic query |
| `implementations/{platform}/diagnostic.{variant}.sql` | Platform diagnostic variant |
| `implementations/{platform}/fix.{name}.sql` | Platform fix operation (mutating, requires approval) |

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
2. Resolve platform implementation path (`implementations/{platform}/check.sql` or variant).
3. Substitute placeholders with actual values.
4. Execute the implementation.
5. Compare normalized result against threshold (`PASS`, `FAIL`, or `N/A`).

### Step 3: Present Results

```
{Assessment Name} Assessment — {DATABASE}.{SCHEMA}

Stage {N}: {name}                                      {PASS/FAIL}
  "{why}"
  {requirement}    {value}  (need {op} {threshold})    {PASS/FAIL}

Summary: {N} of {total} stages passing ({M} of {R} requirements passing)
```

Where `{name}` is the literal `name` field from the assessment YAML (Clean, Contextual, Consumable, Current, Correlated, or Compliant). Do not substitute with descriptive labels.

**Checkpoint:** Options: `remediate` (fix gaps), `export` (JSON), `tell-me-more` (run diagnostics), `done` (stop).

### Diagnostics

When the user wants detail on a failing requirement, resolve `implementations/{platform}/diagnostic.sql` (or variant), substitute placeholders, execute, and present results. If unavailable, return `N/A` with reason.

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
2. List all `fix.*.sql` files in `requirements/{requirement_name}/implementations/{platform}/`.
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

Re-run the resolved platform check implementation for each requirement in the stage. Show before/after:

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
| `semantic_documentation` | [Semantic View Builder](#semantic-view-builder) (inline) | When the Contextual stage fails and tables lack semantic views |
| `column_masking` | `data-policy` | Before creating masking policies |
| `classification` | `sensitive-data-classification` | Before creating tags via SYSTEM$CLASSIFY |

After the delegated workflow completes, return to the remediation workflow to verify.

---

## Semantic View Builder

When `semantic_documentation` or `relationship_declaration` fails during remediation, guide the user through creating a semantic view rather than only adding comments. Semantic views are the preferred remediation — they provide machine-readable metadata that powers Text-to-SQL, Cortex Analyst, and agent tool use. Comments are a fallback for users who can't create semantic views.

### When to Trigger

Trigger this workflow when **any** of the following requirements fail in the Contextual stage:

- `semantic_documentation` — tables lack machine-readable descriptions
- `relationship_declaration` — cross-entity references have no declared join paths

### Decision: Semantic View vs. Comments

Present both options and recommend the semantic view path:

```
Your Contextual stage is failing. Two remediation paths:

  1. Semantic View (recommended)
     Creates a machine-readable model of your tables, relationships,
     metrics, and dimensions. Powers Text-to-SQL, Cortex Analyst,
     and agentic queries. This is the strongest fix.

  2. Column/Table Comments (lightweight)
     Adds human-readable descriptions to tables and columns.
     Improves documentation score but doesn't enable structured
     query generation.

Which approach?
```

If the user picks comments, fall back to `fix.add-comments.sql` as today.

If the user picks semantic view (or the assessment is for `agents`), proceed with the guided builder below.

### Step 1: Discover Schema

Run diagnostics to understand what the user has. Use the scope already established in the assessment.

```sql
-- Get tables and their columns
SELECT c.table_name, c.column_name, c.data_type, c.comment,
       t.comment AS table_comment, t.row_count
FROM {database}.information_schema.columns c
JOIN {database}.information_schema.tables t
    ON c.table_catalog = t.table_catalog
    AND c.table_schema = t.table_schema
    AND c.table_name = t.table_name
WHERE c.table_schema = '{schema}'
    AND t.table_type = 'BASE TABLE'
ORDER BY c.table_name, c.ordinal_position
```

```sql
-- Check for existing foreign key relationships
SELECT tc.table_name, tc.constraint_name, tc.constraint_type,
       kcu.column_name, rc.unique_constraint_name
FROM {database}.information_schema.table_constraints tc
LEFT JOIN {database}.information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN {database}.information_schema.referential_constraints rc
    ON tc.constraint_name = rc.constraint_name
    AND tc.table_schema = rc.constraint_schema
WHERE tc.table_schema = '{schema}'
    AND tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE')
ORDER BY tc.table_name
```

Present a summary:

```
Your schema has {N} tables:

  Table              Rows       Columns   Keys
  ─────              ────       ───────   ────
  CUSTOMERS          1.2M       12        PK: customer_id
  ORDERS             8.4M       9         PK: order_id, FK → CUSTOMERS
  ORDER_ITEMS        22M        6         FK → ORDERS, FK → PRODUCTS
  PRODUCTS           50K        8         PK: product_id

  Detected relationships:
    ORDERS.customer_id → CUSTOMERS.customer_id
    ORDER_ITEMS.order_id → ORDERS.order_id
    ORDER_ITEMS.product_id → PRODUCTS.product_id
```

### Step 2: Interview — Tables and Roles

Ask the user to confirm or correct the table roles:

```
For each table, I need to know its role in your data model.
Here's my best guess based on the schema:

  CUSTOMERS      → dimension (entity attributes)
  ORDERS         → fact (transactional events)
  ORDER_ITEMS    → fact (transactional line items)
  PRODUCTS       → dimension (entity attributes)

Does this look right? Any corrections?
```

**Heuristics for guessing table roles:**

- Tables with timestamp columns + numeric measures → likely **fact** tables
- Tables with a single primary key + descriptive columns → likely **dimension** tables
- Tables that are FK targets from many others → likely **dimension** tables
- Tables with composite keys or many FK columns → likely **fact** or **bridge** tables

### Step 3: Interview — Relationships

Present the detected relationships and ask for confirmation/additions:

```
These relationships will define the join paths in your semantic view:

  ORDERS.customer_id → CUSTOMERS.customer_id
  ORDER_ITEMS.order_id → ORDERS.order_id
  ORDER_ITEMS.product_id → PRODUCTS.product_id

Any relationships to add, remove, or correct?
```

If no FK constraints exist, infer possible relationships from column name patterns (e.g., `customer_id` in ORDERS likely joins to `CUSTOMERS.customer_id`) and ask the user to confirm.

### Step 4: Interview — Metrics

Ask about key business metrics. Only ask for fact tables:

```
What metrics matter for your analysis? I'll look at your numeric columns:

  ORDERS:
    total_amount    → SUM? AVG?
    discount        → SUM?
    shipping_cost   → SUM?

  ORDER_ITEMS:
    quantity        → SUM?
    unit_price      → AVG?
    line_total      → SUM?

Which of these are important metrics, and what aggregation makes sense?
```

### Step 5: Interview — Dimensions and Descriptions

Ask the user to confirm dimension columns and provide descriptions for any columns that lack comments:

```
I'll use these as dimensions (filterable/groupable attributes):

  CUSTOMERS: region, segment, created_date
  PRODUCTS: category, subcategory, brand
  ORDERS: order_date, status, channel

Any to add or remove?
```

For columns lacking comments, ask the user to provide brief descriptions. Group by table to make it efficient:

```
These columns don't have descriptions yet. Brief descriptions help
Cortex Analyst and agents understand your data:

  CUSTOMERS.segment     → ?
  CUSTOMERS.ltv_score   → ?
  ORDERS.channel        → ?
  PRODUCTS.subcategory  → ?
```

### Step 6: Generate and Review

Build the semantic view DDL from the interview answers. Present the full SQL for review:

```sql
CREATE OR REPLACE SEMANTIC VIEW {database}.{schema}.{semantic_view_name}

    TABLES (
        {database}.{schema}.CUSTOMERS
            AS customers
            COMMENT = 'Customer master data with demographics and segmentation',
        {database}.{schema}.ORDERS
            AS orders
            COMMENT = 'Order transactions with totals and status',
        ...
    )

    RELATIONSHIPS (
        orders (customer_id) REFERENCES customers (customer_id),
        order_items (order_id) REFERENCES orders (order_id),
        ...
    )

    FACTS (
        orders.total_amount COMMENT = 'Total order value including tax',
        order_items.quantity COMMENT = 'Number of units ordered',
        ...
    )

    DIMENSIONS (
        customers.region COMMENT = 'Geographic sales region',
        customers.segment COMMENT = 'Customer segmentation tier',
        orders.order_date COMMENT = 'Date the order was placed',
        ...
    )

    METRICS (
        total_revenue AS SUM(orders.total_amount) COMMENT = 'Sum of all order values',
        avg_order_value AS AVG(orders.total_amount) COMMENT = 'Average order value',
        ...
    )

    COMMENT = 'Semantic model for {schema} — covers customers, orders, and products'
```

**Checkpoint:** "Deploy this semantic view? You can also edit the SQL first."

### Step 7: Deploy and Verify

On approval:

1. Execute the `CREATE OR REPLACE SEMANTIC VIEW` statement.
2. Verify deployment:

```sql
-- Confirm the semantic view exists
SHOW SEMANTIC VIEWS LIKE '{semantic_view_name}' IN SCHEMA {database}.{schema};
```

```sql
-- Confirm tables are covered
SELECT sv.name, st.base_table_name, st.comment
FROM {database}.information_schema.semantic_views sv
JOIN {database}.information_schema.semantic_tables st
    ON sv.catalog = st.semantic_view_catalog
    AND sv.schema = st.semantic_view_schema
    AND sv.name = st.semantic_view_name
WHERE sv.schema = '{schema}'
```

3. Re-run `check.semantic.sql` to confirm the score improved.
4. Return to the main remediation workflow.

### Naming Convention

Default semantic view name: `SV_{SCHEMA}` (e.g., `SV_ANALYTICS`). If the user's scope covers specific tables rather than a full schema, use `SV_{primary_table}` (e.g., `SV_ORDERS`). Always let the user override the name.

### Semantic View Syntax Reference

```sql
CREATE OR REPLACE SEMANTIC VIEW db.schema.view_name

    TABLES (
        db.schema.TABLE_NAME AS alias COMMENT = 'description',
        ...
    )

    RELATIONSHIPS (
        child_alias (fk_col) REFERENCES parent_alias (pk_col),
        ...
    )

    FACTS (
        alias.column COMMENT = 'description',
        ...
    )

    DIMENSIONS (
        alias.column COMMENT = 'description',
        ...
    )

    METRICS (
        metric_name AS AGG(alias.column) COMMENT = 'description',
        ...
    )

    COMMENT = 'overall description'
```

Key rules:
- `TABLES` lists base tables with aliases and optional comments.
- `RELATIONSHIPS` uses alias names, not fully qualified table names.
- `FACTS` are numeric columns on fact tables (measures).
- `DIMENSIONS` are categorical/temporal columns used for filtering and grouping.
- `METRICS` are named aggregations over facts.
- There is **no** `COLUMNS` clause — do not use one.
- `CREATE OR REPLACE` is safe for semantic views — they are declarative and idempotent.

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
6. **Read platform gotchas first.** Use `platforms/{platform}/gotchas.md` and, for Snowflake, `reference/gotchas.md`.
7. **Delegate to specialized workflows** for `semantic_documentation` (Semantic View Builder), `column_masking`, and `classification` remediation.
8. **Use capability gating.** If platform capability is unavailable, return `N/A` with reason.

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
  platforms/                            ← Platform capability manifests + gotchas
    snowflake/
      capabilities.yaml
      gotchas.md
    databricks/
      capabilities.yaml
      gotchas.md
    aws/
      capabilities.yaml
      gotchas.md
    azure/
      capabilities.yaml
      gotchas.md
  requirements/                         ← One directory per requirement (61 total)
    index.yaml                          ← Requirement registry
    data_completeness/
      requirement.yaml                  ← Metadata (no SQL paths)
      implementations/
        snowflake/
          check.sql                     ← Platform check query
          check.sampled.sql             ← Platform variant
          diagnostic.sql                ← Platform drill-down
          fix.fill-default.sql          ← Platform fix
    uniqueness/
      requirement.yaml
      implementations/
        snowflake/
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
3. Add implementation files under `implementations/{platform}/`:
   - required: `check.sql`
   - recommended: `diagnostic.sql`
   - optional: `fix.{name}.sql`
4. Add the requirement to the relevant assessment YAML(s) under the matching factor stage.

### Adding a New Assessment

1. Create `assessments/{name}.yaml` with six stages (Clean, Contextual, Consumable, Current, Correlated, Compliant).
2. Select requirements for each stage and set thresholds appropriate for the workload.
3. Alternatively, use `extends` to derive from an existing assessment and apply overrides.

Or use the **Build Assessment** skill (`skills/build-assessment/SKILL.md`) — a guided conversation that interviews the user and generates the YAML.
