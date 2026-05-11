# Diagnostic: incremental_update_coverage

Per-object breakdown of incremental processing capability.

## Context

Shows each table and materialized view with its incremental update status. Objects are classified by their incremental capability:

- **CDC_PUBLISHED** — table is in a logical replication publication and emits change events for incremental consumers.
- **MATERIALIZED_VIEW** — materialized view that supports refresh-based incremental patterns.
- **NO_INCREMENTAL** — base table with no publication membership or incremental mechanism.

## SQL

```sql
WITH base_tables AS (
    SELECT c.oid, c.relname AS table_name, 'BASE TABLE' AS object_type
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
matviews AS (
    SELECT c.oid, c.relname AS table_name, 'MATERIALIZED VIEW' AS object_type
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'm'
),
all_objects AS (
    SELECT * FROM base_tables
    UNION ALL
    SELECT * FROM matviews
),
published AS (
    SELECT DISTINCT tablename
    FROM pg_publication_tables
    WHERE schemaname = '{{ schema }}'
)
SELECT
    o.table_name,
    o.object_type,
    pg_relation_size(o.oid) / (1024 * 1024) AS size_mb,
    CASE
        WHEN o.object_type = 'MATERIALIZED VIEW' THEN 'MATERIALIZED_VIEW'
        WHEN p.tablename IS NOT NULL THEN 'CDC_PUBLISHED'
        ELSE 'NO_INCREMENTAL'
    END AS incremental_capability,
    CASE
        WHEN o.object_type = 'MATERIALIZED VIEW' THEN 'Supports REFRESH MATERIALIZED VIEW'
        WHEN p.tablename IS NOT NULL THEN 'In publication — change events available'
        ELSE 'Consider adding to publication or creating materialized view'
    END AS recommendation
FROM all_objects o
LEFT JOIN published p ON o.table_name = p.tablename
ORDER BY incremental_capability DESC, o.table_name
```
