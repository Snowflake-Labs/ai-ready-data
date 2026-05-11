# Diagnostic: schema_evolution_tracking

Inventory of DDL tracking infrastructure and per-table schema change detection status.

## Context

Two diagnostic views:

1. **Event trigger inventory** — lists all event triggers in the database that track DDL changes, including their event type, function, and enabled status. Use this to understand what DDL tracking is in place.
2. **Table tracking status** — shows each base table in the schema with a status indicating whether DDL tracking covers it (based on event trigger presence). Since event triggers are database-wide, all tables get the same status.

PostgreSQL does not track per-table schema history like Snowflake's Time Travel. Event triggers log DDL events but do not enable querying a table "as of" a previous schema version. For point-in-time schema recovery, use logical backups or a schema migration tool (Flyway, Liquibase, Alembic).

## SQL

### Event trigger inventory

```sql
SELECT
    evtname AS trigger_name,
    evtevent AS event_type,
    evtfoid::regproc AS function_name,
    CASE evtenabled
        WHEN 'O' THEN 'ENABLED (origin + local)'
        WHEN 'D' THEN 'DISABLED'
        WHEN 'R' THEN 'ENABLED (replica)'
        WHEN 'A' THEN 'ENABLED (always)'
    END AS enabled_status,
    evttags AS filtered_commands
FROM pg_event_trigger
ORDER BY evtevent, evtname
```

### Table tracking status

```sql
WITH ddl_triggers AS (
    SELECT COUNT(*) AS cnt
    FROM pg_event_trigger
    WHERE evtevent IN ('ddl_command_start', 'ddl_command_end', 'sql_drop', 'table_rewrite')
      AND evtenabled != 'D'
)
SELECT
    c.relname AS table_name,
    CASE
        WHEN dt.cnt > 0 THEN 'DDL_TRACKED'
        ELSE 'NO_DDL_TRACKING'
    END AS schema_tracking_status,
    CASE
        WHEN dt.cnt > 0 THEN 'DDL changes captured by event trigger'
        ELSE 'Create event triggers for DDL tracking'
    END AS recommendation
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN ddl_triggers dt
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
ORDER BY schema_tracking_status DESC, c.relname
```
