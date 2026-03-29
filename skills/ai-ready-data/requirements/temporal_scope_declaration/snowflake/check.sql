-- check-temporal-scope-declaration.sql
-- Checks if tables have temporal columns identified (date/timestamp columns with comments)
-- Returns: value (float 0-1) - fraction of temporal columns with documentation

WITH temporal_columns AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.comment
    FROM {{ database }}.information_schema.columns c
    WHERE c.table_schema = '{{ schema }}'
        AND c.data_type IN ('DATE', 'DATETIME', 'TIMESTAMP_LTZ', 'TIMESTAMP_NTZ', 'TIMESTAMP_TZ', 'TIME')
),
documented_temporal AS (
    SELECT *
    FROM temporal_columns
    WHERE comment IS NOT NULL 
        AND comment != ''
)
SELECT
    (SELECT COUNT(*) FROM documented_temporal) AS documented_temporal_columns,
    (SELECT COUNT(*) FROM temporal_columns) AS total_temporal_columns,
    (SELECT COUNT(*) FROM documented_temporal)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM temporal_columns)::FLOAT, 0) AS value
