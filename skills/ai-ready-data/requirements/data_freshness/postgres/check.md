# Check: data_freshness

Fraction of data assets within their defined freshness window.

## Context

PostgreSQL does not have Snowflake's `last_altered` timestamp on `information_schema.tables`. Instead, freshness is inferred from `pg_stat_user_tables`, which tracks:

- **`last_analyze`** / **`last_autoanalyze`** — timestamp of the most recent manual or automatic ANALYZE. This is a proxy for freshness: actively-updated tables are typically analyzed more frequently.
- **DML activity counters** (`n_tup_ins`, `n_tup_upd`, `n_tup_del`) — indicate whether any write activity has occurred. Tables with zero activity across all counters since the last stats reset may be stale.

The freshness heuristic uses `GREATEST(last_analyze, last_autoanalyze)` as the freshness timestamp. A table is "fresh" if this timestamp is within `{{ freshness_threshold_hours }}` hours of the current time. Tables that have never been analyzed are treated as stale.

This is an imperfect proxy — `ANALYZE` timing does not directly reflect DML activity. For true freshness tracking, use explicit timestamp columns or change-data-capture mechanisms.

## SQL

```sql
SELECT
    COUNT(*) FILTER (
        WHERE EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - GREATEST(
            COALESCE(s.last_analyze, '1970-01-01'::TIMESTAMPTZ),
            COALESCE(s.last_autoanalyze, '1970-01-01'::TIMESTAMPTZ)
        ))) / 3600 <= {{ freshness_threshold_hours }}
    ) AS fresh_tables,
    COUNT(*) AS total_tables,
    COUNT(*) FILTER (
        WHERE EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - GREATEST(
            COALESCE(s.last_analyze, '1970-01-01'::TIMESTAMPTZ),
            COALESCE(s.last_autoanalyze, '1970-01-01'::TIMESTAMPTZ)
        ))) / 3600 <= {{ freshness_threshold_hours }}
    )::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0) AS value
FROM pg_stat_user_tables s
WHERE s.schemaname = '{{ schema }}'
```
