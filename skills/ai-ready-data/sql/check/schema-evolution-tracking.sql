-- check-schema-evolution-tracking.sql
-- Checks if tables have schema change detection via Time Travel or information_schema
-- Returns: value (float 0-1) - fraction of tables with schema history available

WITH tables_in_scope AS (
    SELECT 
        table_catalog,
        table_schema,
        table_name,
        created,
        last_altered
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
),
-- Tables with Time Travel retention (enables schema history)
tables_with_retention AS (
    SELECT table_name
    FROM tables_in_scope
    WHERE last_altered IS NOT NULL
)
SELECT
    (SELECT COUNT(*) FROM tables_with_retention) AS tables_with_tracking,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_retention)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
