# Diagnostic: training_serving_parity

Per-entity breakdown of feature table parity status between training and serving paths.

## Context

Lists every feature-related object in the schema (tables, materialized views, and functions) with its type and parity status. Objects are grouped by name pattern to help identify which features have both batch (materialized view) and serving (function) paths, and which are missing one or both.

In PostgreSQL, materialized views represent the batch/training path (pre-computed, refreshed periodically), while functions represent the serving/real-time path (computed on demand). Tables without either are labeled `NO_PARITY_PATH`.

## SQL

```sql
WITH all_feature_objects AS (
    SELECT
        c.relname AS object_name,
        CASE c.relkind
            WHEN 'r' THEN 'BASE_TABLE'
            WHEN 'm' THEN 'MATERIALIZED_VIEW'
            ELSE 'OTHER'
        END AS object_type,
        pg_relation_size(c.oid) / (1024 * 1024) AS size_mb,
        CASE c.relkind
            WHEN 'm' THEN 'BATCH_PATH (training)'
            WHEN 'r' THEN 'SOURCE_TABLE'
            ELSE 'OTHER'
        END AS parity_role
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind IN ('r', 'm')
        AND (
            LOWER(c.relname) LIKE '%feature%'
            OR LOWER(c.relname) LIKE '%feat_%'
        )

    UNION ALL

    SELECT
        p.proname AS object_name,
        'FUNCTION' AS object_type,
        NULL AS size_mb,
        'SERVING_PATH (real-time)' AS parity_role
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = '{{ schema }}'
        AND (
            LOWER(p.proname) LIKE '%feature%'
            OR LOWER(p.proname) LIKE '%feat_%'
        )
)
SELECT
    object_name,
    object_type,
    size_mb,
    parity_role,
    CASE
        WHEN object_type = 'MATERIALIZED_VIEW' THEN 'Batch path present — verify serving function exists'
        WHEN object_type = 'FUNCTION' THEN 'Serving path present — verify materialized view exists'
        WHEN object_type = 'BASE_TABLE' THEN 'No materialization — consider adding matview + function'
        ELSE 'Review object purpose'
    END AS recommendation
FROM all_feature_objects
ORDER BY object_name, object_type
```
