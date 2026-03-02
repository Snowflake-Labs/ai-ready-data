-- check-incremental-update-coverage.sql
-- Checks fraction of tables that support incremental updates (streams or dynamic tables)
-- Returns: value (float 0-1) - fraction of tables with incremental update capability

WITH base_tables AS (
    SELECT table_name
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
),
streams AS (
    SELECT DISTINCT table_name
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'STREAM'
),
dynamic_tables AS (
    SELECT table_name
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'DYNAMIC TABLE'
),
-- Tables that either have a stream on them OR are dynamic tables
tables_with_incremental AS (
    -- Base tables with streams (note: stream source needs SHOW STREAMS to determine)
    SELECT DISTINCT bt.table_name
    FROM base_tables bt
    WHERE EXISTS (
        SELECT 1 FROM streams s 
        WHERE s.table_name LIKE bt.table_name || '%'
    )
    UNION
    -- Dynamic tables are inherently incremental
    SELECT table_name FROM dynamic_tables
)
SELECT
    (SELECT COUNT(*) FROM tables_with_incremental) AS tables_with_incremental,
    (SELECT COUNT(*) FROM base_tables) + (SELECT COUNT(*) FROM dynamic_tables) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_incremental)::FLOAT / 
        NULLIF(((SELECT COUNT(*) FROM base_tables) + (SELECT COUNT(*) FROM dynamic_tables))::FLOAT, 0) AS value
