# Check: incremental_update_coverage

Fraction of data objects that use incremental processing rather than full-reload extraction.

## Context

Measures the fraction of data objects in the schema that support incremental updates. In Snowflake this maps to dynamic tables and streams; in PostgreSQL the equivalent mechanisms are:

- **Logical replication publications** — tables enrolled in a publication emit row-level CDC events, enabling incremental downstream consumption.
- **Materialized views** — while not truly incremental (they require `REFRESH MATERIALIZED VIEW`), they represent a transformation layer that can be refreshed without full pipeline reruns.

The check counts tables in publications plus materialized views, divided by total objects (base tables + materialized views). A score of 1.0 means every object has an incremental processing mechanism.

## SQL

```sql
WITH base_tables AS (
    SELECT c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
mat_views AS (
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
    SELECT table_name FROM mat_views
)
SELECT
    (SELECT COUNT(*) FROM tables_with_incremental) AS tables_with_incremental,
    (SELECT COUNT(*) FROM base_tables) + (SELECT COUNT(*) FROM mat_views) AS total_objects,
    (SELECT COUNT(*) FROM tables_with_incremental)::NUMERIC /
        NULLIF(((SELECT COUNT(*) FROM base_tables) + (SELECT COUNT(*) FROM mat_views))::NUMERIC, 0) AS value
```
