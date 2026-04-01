# Diagnostic: propagation_latency_compliance

Per-table breakdown of pipeline freshness tracking.

## Context

Lists materialized views with their last refresh status and all tables/views with freshness-related comments. PostgreSQL does not track materialized view refresh timestamps natively — the `pg_stat_user_tables` `last_autovacuum` and `last_analyze` timestamps can serve as rough proxies for activity, but they do not indicate refresh time.

For materialized views, the `ispopulated` flag indicates whether the view has been refreshed at least once. Tables with freshness SLA documentation in their comments are also listed.

## SQL

```sql
SELECT
    c.relname AS object_name,
    CASE c.relkind
        WHEN 'm' THEN 'MATERIALIZED_VIEW'
        WHEN 'r' THEN 'TABLE'
        ELSE 'OTHER'
    END AS object_type,
    obj_description(c.oid) AS comment,
    CASE
        WHEN c.relkind = 'm' THEN
            CASE WHEN mv.ispopulated THEN 'POPULATED' ELSE 'NOT_POPULATED' END
        WHEN obj_description(c.oid) IS NOT NULL
            AND (
                LOWER(obj_description(c.oid)) LIKE '%freshness_sla%'
                OR LOWER(obj_description(c.oid)) LIKE '%target_lag%'
                OR LOWER(obj_description(c.oid)) LIKE '%refresh_interval%'
                OR LOWER(obj_description(c.oid)) LIKE '%propagation_sla%'
            )
        THEN 'HAS_FRESHNESS_SLA'
        ELSE 'NO_FRESHNESS_TRACKING'
    END AS status,
    COALESCE(s.last_analyze, s.last_autoanalyze) AS last_analyze_time
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_matviews mv
    ON mv.schemaname = n.nspname AND mv.matviewname = c.relname
LEFT JOIN pg_stat_user_tables s ON s.relid = c.oid
WHERE n.nspname = '{{ schema }}'
    AND c.relkind IN ('r', 'm')
ORDER BY status, c.relname
```
