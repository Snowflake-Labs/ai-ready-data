# Diagnostic: serving_latency_compliance

Per-query-pattern breakdown of latency compliance.

## Context

Returns the slowest query patterns from `pg_stat_statements` that reference tables in the target schema, each labeled as `COMPLIANT` or `EXCEEDS_SLA` against the configured `latency_threshold_ms`. Includes mean execution time, total calls, and rows returned to help identify optimization targets.

Requires the `pg_stat_statements` extension. Unlike Snowflake's per-execution query history, `pg_stat_statements` aggregates by query pattern — individual slow executions are not visible.

## SQL

```sql
SELECT
    s.queryid,
    LEFT(s.query, 200) AS query_preview,
    ROUND(s.mean_exec_time::NUMERIC, 2) AS mean_exec_time_ms,
    ROUND(s.min_exec_time::NUMERIC, 2) AS min_exec_time_ms,
    ROUND(s.max_exec_time::NUMERIC, 2) AS max_exec_time_ms,
    s.calls AS total_calls,
    s.rows AS total_rows_returned,
    ROUND((s.shared_blks_hit + s.shared_blks_read)::NUMERIC * 8 / 1024, 2) AS total_mb_processed,
    CASE
        WHEN s.mean_exec_time <= {{ latency_threshold_ms }} THEN 'COMPLIANT'
        ELSE 'EXCEEDS_SLA'
    END AS status
FROM pg_stat_statements s
JOIN pg_database d ON d.oid = s.dbid
WHERE d.datname = current_database()
    AND s.query ~* '{{ schema }}\.'
    AND s.calls > 0
ORDER BY s.mean_exec_time DESC
LIMIT 100
```
