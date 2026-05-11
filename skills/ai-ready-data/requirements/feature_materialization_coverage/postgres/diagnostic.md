# Diagnostic: feature_materialization_coverage

Per-table breakdown of materialization status in the schema.

## Context

Lists every base table and materialized view in the schema with its type, size, and materialization status. Tables without a corresponding materialized view are flagged as `NOT_MATERIALIZED` with a recommendation to create one. Ordered so materialized objects appear first, then unmaterialized base tables by size descending.

## SQL

```sql
WITH all_objects AS (
    SELECT
        c.relname AS table_name,
        CASE c.relkind
            WHEN 'r' THEN 'BASE_TABLE'
            WHEN 'm' THEN 'MATERIALIZED_VIEW'
        END AS table_type,
        c.reltuples::BIGINT AS approx_row_count,
        pg_relation_size(c.oid) / (1024 * 1024) AS size_mb,
        CASE c.relkind
            WHEN 'm' THEN 'MATERIALIZED'
            ELSE 'NOT_MATERIALIZED'
        END AS materialization_status,
        CASE c.relkind
            WHEN 'm' THEN 'Materialized — schedule regular REFRESH'
            ELSE 'Consider creating a materialized view for pre-computation'
        END AS recommendation
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind IN ('r', 'm')
)
SELECT *
FROM all_objects
ORDER BY materialization_status DESC, size_mb DESC
```
