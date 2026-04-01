# Check: batch_throughput_sufficiency

Fraction of tables in the schema that have received insert activity, as a proxy for load operation success.

## Context

PostgreSQL has no native `load_history` equivalent. Snowflake tracks individual `COPY INTO` operations with per-file success/failure status. PG provides only cumulative activity counters via `pg_stat_user_tables` — there is no per-load granularity.

This check uses `pg_stat_user_tables` to count tables that have received at least one insert (`n_tup_ins > 0`) as a fraction of all tables in the schema. A score of 1.0 means every table has been written to at some point since the last statistics reset. A score of 0.0 means no tables have received any inserts.

This is a coarse proxy. Limitations:
- Counters are cumulative since the last `pg_stat_reset()` — they do not reflect a specific time window
- A table with inserts may still have had failed loads (PG does not track partial load failures)
- Success rate cannot be measured — only activity presence

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
