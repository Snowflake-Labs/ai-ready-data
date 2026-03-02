-- check-point-in-time-correctness.sql
-- Checks if tables have event timestamps that enable point-in-time joins
-- Returns: value (float 0-1) - fraction of tables with valid event timestamps

WITH tables_in_scope AS (
    SELECT DISTINCT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tables_with_event_timestamp AS (
    SELECT DISTINCT c.table_name
    FROM {{ database }}.information_schema.columns c
    WHERE c.table_schema = '{{ schema }}'
        AND c.data_type IN ('DATE', 'DATETIME', 'TIMESTAMP_LTZ', 'TIMESTAMP_NTZ', 'TIMESTAMP_TZ')
        AND (
            LOWER(c.column_name) LIKE '%event%'
            OR LOWER(c.column_name) LIKE '%created%'
            OR LOWER(c.column_name) LIKE '%timestamp%'
            OR LOWER(c.column_name) LIKE '%_at'
            OR LOWER(c.column_name) LIKE '%_date'
            OR LOWER(c.column_name) LIKE '%_time'
        )
)
SELECT
    (SELECT COUNT(*) FROM tables_with_event_timestamp) AS tables_with_timestamps,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_event_timestamp)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
