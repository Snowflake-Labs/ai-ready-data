-- diagnostic-schema-evolution-tracking.sql
-- Shows schema history and Time Travel capability for tables
-- Returns: tables with schema tracking details

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
FROM {{ container }}.information_schema.tables t
WHERE t.table_schema = '{{ namespace }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY schema_history_status DESC, t.table_name
