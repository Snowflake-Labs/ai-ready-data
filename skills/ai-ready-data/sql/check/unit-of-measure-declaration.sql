-- check-unit-of-measure-declaration.sql
-- Checks fraction of numeric columns with unit of measure documentation
-- Returns: value (float 0-1) - fraction of numeric columns with unit declarations

WITH numeric_columns AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.comment
    FROM {{ database }}.information_schema.columns c
    INNER JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND c.data_type IN ('NUMBER', 'DECIMAL', 'NUMERIC', 'INT', 'INTEGER', 'BIGINT', 'SMALLINT', 'FLOAT', 'DOUBLE', 'REAL')
        -- Exclude likely non-measured values (IDs, counts, flags)
        AND LOWER(c.column_name) NOT LIKE '%_id'
        AND LOWER(c.column_name) NOT LIKE '%_key'
        AND LOWER(c.column_name) NOT LIKE '%count%'
        AND LOWER(c.column_name) NOT LIKE '%num_%'
        AND LOWER(c.column_name) NOT LIKE '%_num'
        AND LOWER(c.column_name) NOT LIKE '%flag%'
        AND LOWER(c.column_name) NOT LIKE '%is_%'
),
columns_with_units AS (
    SELECT *
    FROM numeric_columns
    WHERE 
        -- Has comment mentioning units
        (comment IS NOT NULL AND (
            LOWER(comment) LIKE '%usd%'
            OR LOWER(comment) LIKE '%dollar%'
            OR LOWER(comment) LIKE '%cent%'
            OR LOWER(comment) LIKE '%percent%'
            OR LOWER(comment) LIKE '%%'
            OR LOWER(comment) LIKE '%unit%'
            OR LOWER(comment) LIKE '%meter%'
            OR LOWER(comment) LIKE '%kilogram%'
            OR LOWER(comment) LIKE '%second%'
            OR LOWER(comment) LIKE '%hour%'
            OR LOWER(comment) LIKE '%day%'
        ))
        -- Or column name implies unit
        OR LOWER(column_name) LIKE '%_usd'
        OR LOWER(column_name) LIKE '%_pct'
        OR LOWER(column_name) LIKE '%_percent'
        OR LOWER(column_name) LIKE '%_seconds'
        OR LOWER(column_name) LIKE '%_minutes'
        OR LOWER(column_name) LIKE '%_hours'
        OR LOWER(column_name) LIKE '%_days'
        OR LOWER(column_name) LIKE '%_kg'
        OR LOWER(column_name) LIKE '%_meters'
)
SELECT
    (SELECT COUNT(*) FROM columns_with_units) AS columns_with_units,
    (SELECT COUNT(*) FROM numeric_columns) AS total_numeric_columns,
    CASE
        WHEN (SELECT COUNT(*) FROM numeric_columns) = 0 THEN 1.0
        ELSE (SELECT COUNT(*) FROM columns_with_units)::FLOAT / 
             (SELECT COUNT(*) FROM numeric_columns)::FLOAT
    END AS value
