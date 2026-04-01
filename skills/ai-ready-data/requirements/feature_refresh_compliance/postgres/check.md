# Check: feature_refresh_compliance

Fraction of materialized features updated within their staleness tolerance.

## Context

Snowflake dynamic tables have a built-in `data_timestamp` and `target_lag` that enable direct staleness measurement. PostgreSQL materialized views have no native refresh timestamp — there is no system catalog column recording when a materialized view was last refreshed.

This check uses a proxy: `pg_stat_user_tables` tracks `last_analyze` and `last_autoanalyze` timestamps for all relations including materialized views. If a materialized view has been recently analyzed (within the tolerance window), it is likely also recently refreshed — since `ANALYZE` is commonly run after `REFRESH`. This is an imperfect proxy.

An alternative approach (shown in the second query) checks for `pg_cron` scheduled jobs that refresh materialized views, which indicates an active refresh pipeline exists.

A score of 1.0 means all materialized views show recent activity. NULL if no materialized views exist.

## SQL

### Proxy via table statistics

```sql
WITH matviews AS (
    SELECT c.relname AS matview_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'm'
),
matview_stats AS (
    SELECT
        s.relname,
        GREATEST(s.last_analyze, s.last_autoanalyze) AS last_activity
    FROM pg_stat_user_tables s
    WHERE s.schemaname = '{{ schema }}'
        AND s.relname IN (SELECT matview_name FROM matviews)
),
compliant AS (
    SELECT COUNT(*) AS cnt
    FROM matview_stats
    WHERE last_activity >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
),
total AS (
    SELECT COUNT(*) AS cnt FROM matviews
)
SELECT
    compliant.cnt AS compliant_matviews,
    total.cnt AS total_matviews,
    compliant.cnt::NUMERIC / NULLIF(total.cnt::NUMERIC, 0) AS value
FROM compliant, total
```
