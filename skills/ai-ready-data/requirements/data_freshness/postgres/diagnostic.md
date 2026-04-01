# Diagnostic: data_freshness

Per-table breakdown of data freshness showing staleness in hours and DML activity.

## Context

Lists every table in the schema from `pg_stat_user_tables`, ordered by freshness timestamp ascending (stalest first). Includes estimated row count, last analyze timestamps, hours since the most recent analyze, and DML activity counters (inserts, updates, deletes since last stats reset).

Tables that have never been analyzed will show `NULL` for analyze timestamps and very large staleness values. High DML counters with old analyze timestamps suggest the table is active but under-analyzed.

`pg_stat_user_tables` statistics are approximate and depend on the stats collector. DML counters reset when `pg_stat_reset()` is called.

## SQL

```sql
SELECT
    s.relname AS table_name,
    s.n_live_tup AS estimated_rows,
    s.last_analyze,
    s.last_autoanalyze,
    GREATEST(
        COALESCE(s.last_analyze, '1970-01-01'::TIMESTAMPTZ),
        COALESCE(s.last_autoanalyze, '1970-01-01'::TIMESTAMPTZ)
    ) AS freshness_timestamp,
    ROUND(
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - GREATEST(
            COALESCE(s.last_analyze, '1970-01-01'::TIMESTAMPTZ),
            COALESCE(s.last_autoanalyze, '1970-01-01'::TIMESTAMPTZ)
        ))) / 3600
    )::INTEGER AS hours_since_analyze,
    s.n_tup_ins AS inserts_since_reset,
    s.n_tup_upd AS updates_since_reset,
    s.n_tup_del AS deletes_since_reset,
    CASE
        WHEN s.last_analyze IS NULL AND s.last_autoanalyze IS NULL THEN 'NEVER_ANALYZED'
        ELSE 'ANALYZED'
    END AS analyze_status
FROM pg_stat_user_tables s
WHERE s.schemaname = '{{ schema }}'
ORDER BY freshness_timestamp ASC
```
