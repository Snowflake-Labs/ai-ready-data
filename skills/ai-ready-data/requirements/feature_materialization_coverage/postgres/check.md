# Check: feature_materialization_coverage

Fraction of schema objects that are pre-materialized via materialized views.

## Context

Snowflake counts dynamic tables and materialized views relative to base tables. PostgreSQL has no dynamic tables — materialized views are the sole pre-materialization mechanism. This check counts materialized views in the schema as a fraction of all table-like objects (base tables + materialized views).

A score of 1.0 means every table-like object in the schema is a materialized view. Base tables with no materialized counterpart pull the score down. A score of 0.0 means no materialized views exist.

Materialized views in PostgreSQL must be explicitly refreshed (`REFRESH MATERIALIZED VIEW`). Unlike Snowflake dynamic tables, they do not auto-refresh. Use `pg_cron` or an application scheduler for periodic refreshes.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
matview_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_matviews
    WHERE schemaname = '{{ schema }}'
)
SELECT
    matview_count.cnt AS materialized_count,
    table_count.cnt + matview_count.cnt AS total_count,
    matview_count.cnt::NUMERIC
        / NULLIF((table_count.cnt + matview_count.cnt)::NUMERIC, 0) AS value
FROM table_count, matview_count
```
