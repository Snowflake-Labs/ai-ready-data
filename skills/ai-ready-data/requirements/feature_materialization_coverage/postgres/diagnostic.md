# Diagnostic: feature_materialization_coverage

Per-object breakdown of materialization status in the schema.

## Context

Lists every base table and materialized view in the schema with its type, size, and materialization status. Base tables without a corresponding materialized view are flagged as `NOT_MATERIALIZED`. Use this to identify which tables would benefit from materialized views for pre-computed feature serving.

Unlike Snowflake which shows dynamic tables with auto-refresh metadata, PostgreSQL materialized views are static snapshots that must be explicitly refreshed.

## SQL

```sql
WITH all_objects AS (
    SELECT
        c.relname AS object_name,
        CASE c.relkind
            WHEN 'r' THEN 'BASE_TABLE'
            WHEN 'm' THEN 'MATERIALIZED_VIEW'
        END AS object_type,
        pg_size_pretty(pg_relation_size(c.oid)) AS size,
        pg_relation_size(c.oid) AS size_bytes
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind IN ('r', 'm')
),
matview_defs AS (
    SELECT matviewname, definition
    FROM pg_matviews
    WHERE schemaname = '{{ schema }}'
)
SELECT
    ao.object_name,
    ao.object_type,
    ao.size,
    CASE
        WHEN ao.object_type = 'MATERIALIZED_VIEW' THEN 'MATERIALIZED'
        WHEN EXISTS (
            SELECT 1 FROM matview_defs mv
            WHERE mv.definition LIKE '%' || ao.object_name || '%'
        ) THEN 'HAS_MATVIEW_DEPENDENCY'
        ELSE 'NOT_MATERIALIZED'
    END AS materialization_status,
    CASE
        WHEN ao.object_type = 'MATERIALIZED_VIEW' THEN 'Pre-materialized (refresh manually or via pg_cron)'
        WHEN EXISTS (
            SELECT 1 FROM matview_defs mv
            WHERE mv.definition LIKE '%' || ao.object_name || '%'
        ) THEN 'Source table for a materialized view'
        ELSE 'Consider creating a materialized view for pre-computation'
    END AS recommendation
FROM all_objects ao
ORDER BY materialization_status, ao.size_bytes DESC
```
