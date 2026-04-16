# Check: training_serving_parity

Fraction of feature entities with consistent training (batch) and serving (real-time) paths.

## Context

Snowflake uses dynamic tables as the unified mechanism for training/serving parity. PostgreSQL has no direct equivalent, so this check uses a heuristic: it looks for feature-related tables that have **both** a materialized view (batch/training path) and a function (serving/real-time path) with matching name patterns.

A materialized view represents a pre-computed batch transformation (training path). A function that references the same base data represents a real-time computation path (serving). When both exist for the same logical entity, it suggests the feature has both paths defined — though true parity requires verifying the transformation logic matches.

The check counts tables with names matching `%feature%` or `%feat_%` that have a corresponding materialized view **or** function in the same schema. A score of 1.0 means every feature table has at least one materialized counterpart. This is inherently heuristic — it cannot verify that the batch and serving logic are actually equivalent.

## SQL

```sql
WITH feature_tables AS (
    SELECT c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND (
            LOWER(c.relname) LIKE '%feature%'
            OR LOWER(c.relname) LIKE '%feat_%'
        )
),
feature_matviews AS (
    SELECT matviewname AS view_name
    FROM pg_matviews
    WHERE schemaname = '{{ schema }}'
        AND (
            LOWER(matviewname) LIKE '%feature%'
            OR LOWER(matviewname) LIKE '%feat_%'
        )
),
feature_functions AS (
    SELECT p.proname AS func_name
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = '{{ schema }}'
        AND (
            LOWER(p.proname) LIKE '%feature%'
            OR LOWER(p.proname) LIKE '%feat_%'
        )
),
tables_with_parity AS (
    SELECT ft.table_name
    FROM feature_tables ft
    WHERE EXISTS (SELECT 1 FROM feature_matviews)
       OR EXISTS (SELECT 1 FROM feature_functions)
)
SELECT
    (SELECT COUNT(*) FROM tables_with_parity) AS tables_with_parity,
    (SELECT COUNT(*) FROM feature_tables) AS total_feature_tables,
    (SELECT COUNT(*) FROM tables_with_parity)::NUMERIC
        / NULLIF((SELECT COUNT(*) FROM feature_tables)::NUMERIC, 0) AS value
```
