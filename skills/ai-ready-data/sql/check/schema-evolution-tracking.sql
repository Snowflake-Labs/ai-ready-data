-- check-schema-evolution-tracking.sql
-- Checks if tables have data retention enabling schema history via Time Travel
-- Returns: value (float 0-1) - fraction of tables with retention > 0

WITH tables_in_scope AS (
    SELECT 
        table_catalog,
        table_schema,
        table_name,
        created,
        last_altered,
        retention_time
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
-- Tables with Time Travel retention > 0 (enables historical queries)
tables_with_retention AS (
    SELECT table_name
    FROM tables_in_scope
    WHERE retention_time > 0
)
SELECT
    (SELECT COUNT(*) FROM tables_with_retention) AS tables_with_tracking,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_retention)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
