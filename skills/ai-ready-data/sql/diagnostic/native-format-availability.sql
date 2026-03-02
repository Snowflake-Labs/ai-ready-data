-- diagnostic-native-format-availability.sql
-- Shows tables by format type (native vs external)
-- Returns: tables with format details

SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name,
    t.table_type,
    t.row_count,
    t.bytes / (1024*1024) AS size_mb,
    CASE
        WHEN t.table_type = 'EXTERNAL TABLE' THEN 'EXTERNAL'
        WHEN t.table_type IN ('BASE TABLE', 'DYNAMIC TABLE') THEN 'NATIVE'
        ELSE 'OTHER'
    END AS format_type,
    CASE
        WHEN t.table_type = 'EXTERNAL TABLE' THEN 'External data - requires runtime conversion'
        WHEN t.table_type = 'BASE TABLE' THEN 'Native Snowflake format - optimal performance'
        WHEN t.table_type = 'DYNAMIC TABLE' THEN 'Native format with auto-refresh'
        ELSE t.table_type
    END AS description,
    CASE
        WHEN t.table_type = 'EXTERNAL TABLE' THEN 'Consider materializing frequently accessed external data'
        ELSE 'Native format - no action needed'
    END AS recommendation
FROM {{ container }}.information_schema.tables t
WHERE t.table_schema = '{{ namespace }}'
ORDER BY format_type DESC, t.row_count DESC
