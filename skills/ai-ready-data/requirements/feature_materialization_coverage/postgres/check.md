# Check: feature_materialization_coverage

Fraction of tables in the schema that have a pre-materialized counterpart.

## Context

Snowflake uses dynamic tables and materialized views for feature materialization. PostgreSQL's equivalent is materialized views (`pg_matviews`). This check counts materialized views in the schema relative to the total number of base tables plus materialized views.

A score of 1.0 means every table-like object in the schema is a materialized view. Base tables with no materialized counterpart pull the score down. A high score indicates features are pre-computed and ready for serving without on-the-fly computation.

PostgreSQL materialized views require explicit `REFRESH MATERIALIZED VIEW` calls — they do not auto-refresh like Snowflake dynamic tables. The materialization score here reflects structural coverage, not freshness.

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
