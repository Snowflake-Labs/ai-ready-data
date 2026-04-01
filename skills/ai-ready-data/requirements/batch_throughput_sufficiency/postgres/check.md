# Check: batch_throughput_sufficiency

Fraction of tables in the schema that show evidence of successful bulk loading activity.

## Context

PostgreSQL has no native load history equivalent to Snowflake's `information_schema.load_history`. This check uses `pg_stat_user_tables` cumulative activity counters as a coarse proxy: a table with `n_tup_ins > 0` is counted as having received load activity.

This is a weaker signal than Snowflake's per-load tracking. Limitations:
- Counters are cumulative since the last `pg_stat_reset()` — they reflect all-time activity, not a recent window
- No distinction between bulk loads (`COPY`) and individual inserts
- No per-load success/failure tracking — a table with insert counts may still have had failed loads
- A high ratio does not guarantee throughput sufficiency — it only confirms data has been loaded

A score of 1.0 means every table in the schema has received at least one insert. A score of 0.0 means no tables have insert activity. If there are no tables in the schema, the result is NULL.

## SQL

```sql
WITH table_stats AS (
    SELECT
        relname,
        n_tup_ins,
        n_tup_upd,
        n_tup_del,
        n_live_tup,
        n_dead_tup
    FROM pg_stat_user_tables
    WHERE schemaname = '{{ schema }}'
),
active_tables AS (
    SELECT COUNT(*) AS cnt FROM table_stats WHERE n_tup_ins > 0
),
total AS (
    SELECT COUNT(*) AS cnt FROM table_stats
)
SELECT
    active_tables.cnt AS tables_with_loads,
    total.cnt AS total_tables,
    active_tables.cnt::NUMERIC / NULLIF(total.cnt::NUMERIC, 0) AS value
FROM active_tables, total
```
