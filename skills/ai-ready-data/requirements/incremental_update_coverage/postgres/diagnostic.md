# Diagnostic: incremental_update_coverage

Per-object breakdown of incremental processing capability across the schema.

## Context

Lists all base tables and materialized views in the schema with their incremental update status. Tables in a logical replication publication are marked as having CDC capability. Materialized views are inherently incremental (refreshable). Tables without either mechanism are flagged for action.

## SQL

```sql
WITH base_tables AS (
    SELECT
        c.relname AS table_name,
        'BASE TABLE' AS object_type,
        pg_relation_size(c.oid) / (1024 * 1024) AS size_mb
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
mat_views AS (
    SELECT
        c.relname AS table_name,
        'MATERIALIZED VIEW' AS object_type,
        pg_relation_size(c.oid) / (1024 * 1024) AS size_mb
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'm'
),
all_objects AS (
    SELECT * FROM base_tables
    UNION ALL
    SELECT * FROM mat_views
),
published AS (
    SELECT DISTINCT tablename
    FROM pg_publication_tables
    WHERE schemaname = '{{ schema }}'
)
SELECT
    o.table_name,
    o.object_type,
    o.size_mb,
    CASE
        WHEN o.object_type = 'MATERIALIZED VIEW' THEN 'MATERIALIZED_VIEW'
        WHEN p.tablename IS NOT NULL THEN 'IN_PUBLICATION'
        ELSE 'NO_INCREMENTAL'
    END AS incremental_capability,
    CASE
        WHEN o.object_type = 'MATERIALIZED VIEW' THEN 'Refreshable via REFRESH MATERIALIZED VIEW'
        WHEN p.tablename IS NOT NULL THEN 'CDC via logical replication publication'
        ELSE 'Consider adding to a publication or creating a materialized view'
    END AS recommendation
FROM all_objects o
LEFT JOIN published p ON o.table_name = p.tablename
ORDER BY incremental_capability DESC, o.table_name
```
