# Check: feature_refresh_compliance

Fraction of materialized features updated within a staleness tolerance.

## Context

Snowflake dynamic tables have a built-in `data_timestamp` and `target_lag` that make freshness measurement straightforward. PostgreSQL has no native materialized view refresh timestamp exposed via catalog views.

This check uses `pg_stat_user_tables.last_analyze` as a proxy for table activity recency. When `last_analyze` or `last_autoanalyze` is recent, it suggests the table (or its underlying data) has been actively maintained. For materialized views specifically, `last_analyze` updates after `ANALYZE` runs (which autovacuum triggers after a `REFRESH`).

A default staleness tolerance of 24 hours is used. Tables analyzed within that window are considered compliant. This is a coarse proxy — it does not directly measure when the materialized view was last refreshed.

A score of 1.0 means every table/matview in the schema was analyzed within the staleness window. A score of 0.0 means none were.

## SQL

```sql
WITH table_freshness AS (
    SELECT
        relname,
        schemaname,
        GREATEST(
            COALESCE(last_analyze, '1970-01-01'::TIMESTAMP),
            COALESCE(last_autoanalyze, '1970-01-01'::TIMESTAMP),
            COALESCE(last_vacuum, '1970-01-01'::TIMESTAMP),
            COALESCE(last_autovacuum, '1970-01-01'::TIMESTAMP)
        ) AS last_activity,
        CURRENT_TIMESTAMP - INTERVAL '24 hours' AS staleness_threshold
    FROM pg_stat_user_tables
    WHERE schemaname = '{{ schema }}'
),
compliant AS (
    SELECT COUNT(*) AS cnt
    FROM table_freshness
    WHERE last_activity >= staleness_threshold
),
total AS (
    SELECT COUNT(*) AS cnt FROM table_freshness
)
SELECT
    compliant.cnt AS compliant_tables,
    total.cnt AS total_tables,
    compliant.cnt::NUMERIC / NULLIF(total.cnt::NUMERIC, 0) AS value
FROM compliant, total
```
