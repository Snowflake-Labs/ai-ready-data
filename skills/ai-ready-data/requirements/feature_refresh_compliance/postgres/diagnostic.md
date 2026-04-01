# Diagnostic: feature_refresh_compliance

Per-materialized-view breakdown of refresh activity and staleness.

## Context

Shows each materialized view in the schema with its last known activity timestamp (from `pg_stat_user_tables`), estimated staleness, and compliance status. Since PostgreSQL does not record materialized view refresh timestamps natively, `last_analyze` / `last_autoanalyze` is used as a proxy.

Also checks for `pg_cron` scheduled refresh jobs if the `pg_cron` extension is installed.

## SQL

### Materialized view staleness

```sql
SELECT
    mv.matviewname AS matview_name,
    LEFT(mv.definition, 200) AS definition_preview,
    pg_size_pretty(pg_relation_size(
        (quote_ident(mv.schemaname) || '.' || quote_ident(mv.matviewname))::regclass
    )) AS size,
    s.last_analyze,
    s.last_autoanalyze,
    GREATEST(s.last_analyze, s.last_autoanalyze) AS last_known_activity,
    CASE
        WHEN GREATEST(s.last_analyze, s.last_autoanalyze)
            >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
        THEN 'LIKELY_FRESH'
        WHEN GREATEST(s.last_analyze, s.last_autoanalyze) IS NOT NULL
        THEN 'POSSIBLY_STALE'
        ELSE 'UNKNOWN (never analyzed)'
    END AS freshness_status,
    CASE
        WHEN GREATEST(s.last_analyze, s.last_autoanalyze) IS NOT NULL
        THEN ROUND(EXTRACT(EPOCH FROM (
            CURRENT_TIMESTAMP - GREATEST(s.last_analyze, s.last_autoanalyze)
        )) / 3600, 1)
        ELSE NULL
    END AS hours_since_activity,
    CASE
        WHEN GREATEST(s.last_analyze, s.last_autoanalyze)
            >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
        THEN 'Activity within tolerance'
        WHEN GREATEST(s.last_analyze, s.last_autoanalyze) IS NOT NULL
        THEN 'Refresh and re-analyze the materialized view'
        ELSE 'No activity recorded — run REFRESH then ANALYZE'
    END AS recommendation
FROM pg_matviews mv
LEFT JOIN pg_stat_user_tables s
    ON s.schemaname = mv.schemaname AND s.relname = mv.matviewname
WHERE mv.schemaname = '{{ schema }}'
ORDER BY freshness_status, mv.matviewname
```
