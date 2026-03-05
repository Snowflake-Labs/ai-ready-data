-- check-constraint-declaration.sql
-- Checks fraction of columns with explicitly declared constraints
-- Returns: value (float 0-1) - fraction of columns with constraints

-- Note: character_maximum_length and numeric_precision are NOT counted as
-- constraints because Snowflake always populates these with defaults
-- (e.g., VARCHAR defaults to 16777216). Only explicit constraints count.

WITH columns_in_scope AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.is_nullable
    FROM {{ database }}.information_schema.columns c
    INNER JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
constrained_columns AS (
    SELECT DISTINCT
        kcu.table_catalog,
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name
    FROM {{ database }}.information_schema.key_column_usage kcu
    WHERE kcu.table_schema = '{{ schema }}'
)
SELECT
    COUNT_IF(
        c.is_nullable = 'NO'
        OR cc.column_name IS NOT NULL
    ) AS columns_with_constraints,
    COUNT(*) AS total_columns,
    COUNT_IF(
        c.is_nullable = 'NO'
        OR cc.column_name IS NOT NULL
    )::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM columns_in_scope c
LEFT JOIN constrained_columns cc
    ON c.table_catalog = cc.table_catalog
    AND c.table_schema = cc.table_schema
    AND c.table_name = cc.table_name
    AND c.column_name = cc.column_name
