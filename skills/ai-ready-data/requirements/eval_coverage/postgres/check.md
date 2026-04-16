# Check: eval_coverage

Fraction of data assets with associated evaluation sets that verify AI tool correctness.

## Context

Checks for the existence of eval artifacts by looking for tables whose names match eval naming conventions (`_eval` suffix, `eval_` prefix). PostgreSQL does not have semantic views — this check only looks at base tables.

A score of 1.0 means every base table has a corresponding eval table. The heuristic relies on naming conventions — evaluation tables with non-standard names will not be detected.

## SQL

```sql
WITH eval_tables AS (
    SELECT COUNT(DISTINCT table_name) AS cnt
    FROM information_schema.tables
    WHERE table_schema = '{{ schema }}'
      AND table_type = 'BASE TABLE'
      AND (
        LOWER(table_name) LIKE '%\_eval' ESCAPE '\'
        OR LOWER(table_name) LIKE '%\_eval\_%' ESCAPE '\'
        OR LOWER(table_name) LIKE 'eval\_%' ESCAPE '\'
      )
),
assets_needing_evals AS (
    SELECT COUNT(*) AS cnt
    FROM information_schema.tables
    WHERE table_schema = '{{ schema }}'
      AND table_type = 'BASE TABLE'
)
SELECT
    eval_tables.cnt AS eval_tables,
    assets_needing_evals.cnt AS total_assets,
    CASE
      WHEN assets_needing_evals.cnt = 0 THEN 1.0
      ELSE eval_tables.cnt::NUMERIC / assets_needing_evals.cnt::NUMERIC
    END AS value
FROM eval_tables, assets_needing_evals
```
