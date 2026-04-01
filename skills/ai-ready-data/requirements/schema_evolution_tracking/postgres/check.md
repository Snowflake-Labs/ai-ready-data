# Check: schema_evolution_tracking

Fraction of assets with schema change detection infrastructure in place.

## Context

PostgreSQL does not have Snowflake's Time Travel for historical schema queries. Instead, schema evolution tracking is achieved through **event triggers** that capture DDL statements.

This check measures whether the schema has DDL tracking infrastructure by looking for:

1. **Event triggers** (`pg_event_trigger`) — PostgreSQL event triggers fire on DDL commands (`ddl_command_start`, `ddl_command_end`, `sql_drop`, `table_rewrite`). The presence of event triggers indicates schema changes are being tracked.
2. **DDL audit logging** — some setups log DDL via `pgaudit` or custom functions. This check focuses on event triggers as the queryable signal.

The score is binary at the database level: 1.0 if any DDL-tracking event trigger exists, 0.0 if none. This differs from Snowflake's per-table Time Travel check — PostgreSQL event triggers operate at the database level and cover all tables.

For per-table granularity, the check also verifies that tables in the schema have had recent activity in the stats collector, indicating they are within the monitoring scope.

## SQL

```sql
WITH event_trigger_check AS (
    SELECT COUNT(*) AS trigger_count
    FROM pg_event_trigger
    WHERE evtevent IN ('ddl_command_start', 'ddl_command_end', 'sql_drop', 'table_rewrite')
      AND evtenabled != 'D'
),
tables_in_scope AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
)
SELECT
    CASE WHEN et.trigger_count > 0 THEN ts.cnt ELSE 0 END AS tables_with_tracking,
    ts.cnt AS total_tables,
    CASE
        WHEN ts.cnt = 0 THEN NULL
        WHEN et.trigger_count > 0 THEN 1.0
        ELSE 0.0
    END::NUMERIC AS value
FROM event_trigger_check et, tables_in_scope ts
```
