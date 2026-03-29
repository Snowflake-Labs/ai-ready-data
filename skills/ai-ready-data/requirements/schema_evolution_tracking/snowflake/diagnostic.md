# Diagnostic: schema_evolution_tracking

Per-table breakdown of schema history and Time Travel capability.

## Context

Shows each base table with its creation date, last schema change, Time Travel retention period, and a status indicating whether historical schema queries are possible. Tables with `NO_TIME_TRAVEL` status cannot be queried at previous points in time.

Use this to identify which specific tables lack schema evolution tracking and need their retention period increased.

## SQL

```sql
SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name,
    t.created AS table_created,
    t.last_altered AS last_schema_change,
    t.retention_time AS time_travel_days,
    CASE
        WHEN t.retention_time > 0 THEN 'TIME_TRAVEL_ENABLED'
        ELSE 'NO_TIME_TRAVEL'
    END AS schema_history_status,
    CASE
        WHEN t.retention_time > 0 THEN 'Can query historical schema via AT/BEFORE'
        ELSE 'Enable Time Travel for schema history'
    END AS recommendation
FROM {{ database }}.information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY schema_history_status DESC, t.table_name
```
