# Diagnostic: batch_throughput_sufficiency

Per-table breakdown of insert activity and tuple health.

## Context

Shows each table in the schema with its cumulative insert, update, and delete counts, live/dead tuple ratios, and a health assessment. Tables with a high dead tuple ratio may need `VACUUM` to reclaim space and maintain performance. Tables with zero inserts are flagged as having no load activity.

Unlike Snowflake's per-load `load_history`, these are cumulative counters since the last `pg_stat_reset()`. The `dead_tuple_ratio` column indicates how much bloat exists — a ratio above 0.2 (20%) suggests `VACUUM` is overdue.

## SQL

```sql
SELECT
    relname AS table_name,
    n_tup_ins AS total_inserts,
    n_tup_upd AS total_updates,
    n_tup_del AS total_deletes,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    ROUND(n_dead_tup::NUMERIC / NULLIF((n_live_tup + n_dead_tup)::NUMERIC, 0), 4) AS dead_tuple_ratio,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    CASE
        WHEN n_tup_ins = 0 THEN 'NO_LOAD_ACTIVITY'
        WHEN n_dead_tup::NUMERIC / NULLIF((n_live_tup + n_dead_tup)::NUMERIC, 0) > 0.2
            THEN 'NEEDS_VACUUM'
        ELSE 'HEALTHY'
    END AS load_health,
    CASE
        WHEN n_tup_ins = 0 THEN 'No inserts detected — verify load pipeline'
        WHEN n_dead_tup::NUMERIC / NULLIF((n_live_tup + n_dead_tup)::NUMERIC, 0) > 0.2
            THEN 'High dead tuple ratio — run VACUUM'
        ELSE 'Load activity detected, tuple health OK'
    END AS recommendation
FROM pg_stat_user_tables
WHERE schemaname = '{{ schema }}'
ORDER BY load_health, n_tup_ins DESC
```
