# Diagnostic: batch_throughput_sufficiency

Per-table breakdown of load activity and table health indicators.

## Context

Shows each table's cumulative insert, update, and delete counts from `pg_stat_user_tables`, along with live/dead tuple ratios. High dead tuple counts relative to live tuples indicate tables that need vacuuming — a common cause of degraded load throughput in PostgreSQL.

The `load_health` label flags tables with zero inserts (`NO_LOAD_ACTIVITY`), high dead tuple ratios (`NEEDS_VACUUM`), or healthy state (`HEALTHY`). Counters are cumulative since the last `pg_stat_reset()`.

## SQL

```sql
SELECT
    relname AS table_name,
    n_tup_ins AS total_inserts,
    n_tup_upd AS total_updates,
    n_tup_del AS total_deletes,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    CASE
        WHEN n_live_tup > 0
        THEN ROUND(n_dead_tup::NUMERIC / n_live_tup::NUMERIC, 4)
        ELSE 0
    END AS dead_to_live_ratio,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    CASE
        WHEN n_tup_ins = 0 THEN 'NO_LOAD_ACTIVITY'
        WHEN n_dead_tup > n_live_tup * 0.2 THEN 'NEEDS_VACUUM'
        ELSE 'HEALTHY'
    END AS load_health,
    CASE
        WHEN n_tup_ins = 0 THEN 'No inserts recorded — verify load pipeline'
        WHEN n_dead_tup > n_live_tup * 0.2 THEN 'High dead tuple ratio — run VACUUM'
        ELSE 'Load activity looks healthy'
    END AS recommendation
FROM pg_stat_user_tables
WHERE schemaname = '{{ schema }}'
ORDER BY
    CASE WHEN n_tup_ins = 0 THEN 0 ELSE 1 END,
    n_dead_tup DESC
```
