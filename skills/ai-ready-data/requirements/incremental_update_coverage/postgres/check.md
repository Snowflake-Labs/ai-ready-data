# Check: incremental_update_coverage

Fraction of data pipelines using incremental processing rather than full-reload extraction.

## Context

Measures the fraction of objects that support incremental updates. PostgreSQL has no direct equivalent of Snowflake's dynamic tables, but incremental processing is indicated by:

- **Publication membership** — tables in logical replication publications emit change events for incremental CDC pipelines.
- **Materialized views** — can be incrementally refreshed (though standard PostgreSQL `REFRESH MATERIALIZED VIEW` is a full rebuild, the existence of a matview indicates an incremental-friendly pattern).

The check counts tables in publications plus materialized views as objects with incremental capability, divided by total objects (base tables + materialized views) in the schema.

## SQL

```sql
WITH base_tables AS (
    SELECT c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
matviews AS (
    SELECT c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'm'
),
published_tables AS (
    SELECT DISTINCT tablename AS table_name
    FROM pg_publication_tables
    WHERE schemaname = '{{ schema }}'
),
tables_with_incremental AS (
    SELECT table_name FROM published_tables
    UNION
    SELECT table_name FROM matviews
),
all_objects AS (
    SELECT table_name FROM base_tables
    UNION ALL
    SELECT table_name FROM matviews
)
SELECT
    (SELECT COUNT(*) FROM tables_with_incremental) AS tables_with_incremental,
    (SELECT COUNT(*) FROM all_objects) AS total_objects,
    (SELECT COUNT(*) FROM tables_with_incremental)::NUMERIC /
        NULLIF((SELECT COUNT(*) FROM all_objects)::NUMERIC, 0) AS value
```
