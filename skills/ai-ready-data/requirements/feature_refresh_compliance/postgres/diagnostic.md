# Diagnostic: feature_refresh_compliance

Per-table breakdown of refresh freshness and compliance status.

## Context

Shows each table and materialized view in the schema with its most recent maintenance activity timestamp and compliance status against the 24-hour staleness threshold. Tables that have not been analyzed, vacuumed, or refreshed within the window are flagged as `STALE`.

For materialized views, PostgreSQL does not record refresh timestamps in catalog views. The `last_analyze` / `last_autovacuum` timestamps serve as proxies — autovacuum typically runs ANALYZE after a materialized view refresh populates new data.

## SQL

```sql
WITH object_freshness AS (
    SELECT
        s.relname AS object_name,
        CASE c.relkind
            WHEN 'r' THEN 'BASE_TABLE'
            WHEN 'm' THEN 'MATERIALIZED_VIEW'
            ELSE 'OTHER'
        END AS object_type,
        s.last_analyze,
        s.last_autoanalyze,
        s.last_vacuum,
        s.last_autovacuum,
        GREATEST(
            COALESCE(s.last_analyze, '1970-01-01'::TIMESTAMP),
            COALESCE(s.last_autoanalyze, '1970-01-01'::TIMESTAMP),
            COALESCE(s.last_vacuum, '1970-01-01'::TIMESTAMP),
            COALESCE(s.last_autovacuum, '1970-01-01'::TIMESTAMP)
        ) AS last_activity,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - GREATEST(
            COALESCE(s.last_analyze, '1970-01-01'::TIMESTAMP),
            COALESCE(s.last_autoanalyze, '1970-01-01'::TIMESTAMP),
            COALESCE(s.last_vacuum, '1970-01-01'::TIMESTAMP),
            COALESCE(s.last_autovacuum, '1970-01-01'::TIMESTAMP)
        ))) / 3600 AS hours_since_activity
    FROM pg_stat_user_tables s
    JOIN pg_class c ON c.relname = s.relname
    JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = s.schemaname
    WHERE s.schemaname = '{{ schema }}'
)
SELECT
    object_name,
    object_type,
    last_analyze,
    last_autoanalyze,
    last_vacuum,
    last_autovacuum,
    last_activity,
    ROUND(hours_since_activity::NUMERIC, 1) AS hours_since_activity,
    CASE
        WHEN hours_since_activity <= 24 THEN 'COMPLIANT'
        WHEN hours_since_activity <= 72 THEN 'WARNING'
        ELSE 'STALE'
    END AS compliance_status,
    CASE
        WHEN hours_since_activity <= 24 THEN 'Within freshness threshold'
        WHEN object_type = 'MATERIALIZED_VIEW' THEN 'Run REFRESH MATERIALIZED VIEW'
        ELSE 'Run ANALYZE or check data pipeline activity'
    END AS recommendation
FROM object_freshness
ORDER BY compliance_status DESC, hours_since_activity DESC
```
