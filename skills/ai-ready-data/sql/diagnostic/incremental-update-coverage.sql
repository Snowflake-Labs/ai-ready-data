-- diagnostic-incremental-update-coverage.sql
-- Shows tables and their incremental update capabilities
-- Returns: tables with stream/dynamic table status

WITH base_tables AS (
    SELECT 
        table_catalog,
        table_schema,
        table_name,
        row_count,
        'BASE TABLE' AS table_type
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
dynamic_tables AS (
    SELECT 
        table_catalog,
        table_schema,
        table_name,
        row_count,
        'DYNAMIC TABLE' AS table_type
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'DYNAMIC TABLE'
),
streams AS (
    SELECT 
        table_catalog,
        table_schema,
        table_name AS stream_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'STREAM'
),
all_tables AS (
    SELECT * FROM base_tables
    UNION ALL
    SELECT * FROM dynamic_tables
)
SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name,
    t.row_count,
    t.table_type,
    CASE
        WHEN t.table_type = 'DYNAMIC TABLE' THEN 'DYNAMIC_TABLE'
        WHEN EXISTS (SELECT 1 FROM streams s WHERE s.stream_name LIKE t.table_name || '%') THEN 'HAS_STREAM'
        ELSE 'NO_INCREMENTAL'
    END AS incremental_capability,
    CASE
        WHEN t.table_type = 'DYNAMIC TABLE' THEN 'Auto-refreshes based on target lag'
        WHEN EXISTS (SELECT 1 FROM streams s WHERE s.stream_name LIKE t.table_name || '%') THEN 'Stream captures changes'
        ELSE 'Consider adding stream or converting to dynamic table'
    END AS recommendation
FROM all_tables t
ORDER BY 
    incremental_capability DESC,
    t.table_name
