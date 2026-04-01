# Diagnostic: training_serving_parity

Per-entity breakdown of feature table parity between training and serving paths.

## Context

Lists every feature table (names matching `%feature%` or `%feat_%`) with whether a corresponding materialized view (batch/training path) and function (serving/real-time path) exist. Tables with both paths are labeled `PARITY_READY`. Tables missing one or both paths are labeled accordingly.

This is a name-based heuristic — it assumes that a materialized view or function whose name overlaps with the feature table name implements the same logic. True parity verification requires inspecting the actual transformation logic.

## SQL

```sql
WITH feature_tables AS (
    SELECT c.relname AS table_name,
           pg_size_pretty(pg_relation_size(c.oid)) AS table_size
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND (LOWER(c.relname) LIKE '%feature%' OR LOWER(c.relname) LIKE '%feat_%')
),
matview_names AS (
    SELECT matviewname AS name, definition
    FROM pg_matviews
    WHERE schemaname = '{{ schema }}'
),
function_names AS (
    SELECT routine_name AS name, data_type AS return_type
    FROM information_schema.routines
    WHERE routine_schema = '{{ schema }}'
        AND routine_type = 'FUNCTION'
)
SELECT
    ft.table_name,
    ft.table_size,
    mv.name AS matview_name,
    fn.name AS function_name,
    CASE
        WHEN mv.name IS NOT NULL AND fn.name IS NOT NULL THEN 'PARITY_READY'
        WHEN mv.name IS NOT NULL THEN 'BATCH_ONLY (has matview, no function)'
        WHEN fn.name IS NOT NULL THEN 'SERVING_ONLY (has function, no matview)'
        ELSE 'NO_PATHS (neither matview nor function)'
    END AS parity_status,
    CASE
        WHEN mv.name IS NOT NULL AND fn.name IS NOT NULL THEN 'Verify logic matches between matview and function'
        WHEN mv.name IS NOT NULL THEN 'Create a serving function for real-time path'
        WHEN fn.name IS NOT NULL THEN 'Create a materialized view for batch/training path'
        ELSE 'Create both materialized view and serving function'
    END AS recommendation
FROM feature_tables ft
LEFT JOIN matview_names mv ON (
    mv.name LIKE '%' || ft.table_name || '%'
    OR ft.table_name LIKE '%' || mv.name || '%'
)
LEFT JOIN function_names fn ON (
    fn.name LIKE '%' || ft.table_name || '%'
    OR ft.table_name LIKE '%' || fn.name || '%'
)
ORDER BY parity_status, ft.table_name
```
