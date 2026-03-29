# Check: eval_coverage

Fraction of data assets with associated evaluation sets that verify AI tool correctness.

## Context

Checks for the existence of eval artifacts, not whether evals pass. Eval naming conventions are platform-specific.

## SQL

```sql
WITH semantic_views AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.semantic_views
    WHERE schema = '{{ schema }}'
),
eval_tables AS (
    SELECT COUNT(DISTINCT table_name) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
      AND table_type = 'BASE TABLE'
      AND (
        LOWER(table_name) LIKE '%_eval'
        OR LOWER(table_name) LIKE '%_eval_%'
        OR LOWER(table_name) LIKE 'eval_%'
      )
),
assets_needing_evals AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
      AND table_type = 'BASE TABLE'
)
SELECT
    eval_tables.cnt AS eval_tables,
    assets_needing_evals.cnt AS total_assets,
    CASE
      WHEN assets_needing_evals.cnt = 0 THEN 1.0
      ELSE eval_tables.cnt::FLOAT / assets_needing_evals.cnt::FLOAT
    END AS value
FROM eval_tables, assets_needing_evals
```
