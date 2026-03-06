-- diagnostic-unit-of-measure-declaration.sql
-- Lists numeric columns and their unit of measure status
-- Returns: numeric columns with unit documentation details

WITH numeric_columns AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.numeric_precision,
        c.numeric_scale,
        c.comment
    FROM {{ database }}.information_schema.columns c
    INNER JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND c.data_type IN ('NUMBER', 'DECIMAL', 'NUMERIC', 'INT', 'INTEGER', 'BIGINT', 'SMALLINT', 'FLOAT', 'DOUBLE', 'REAL')
        -- Exclude likely non-measured values
        AND LOWER(c.column_name) NOT LIKE '%_id'
        AND LOWER(c.column_name) NOT LIKE '%_key'
        AND LOWER(c.column_name) NOT LIKE '%count%'
        AND LOWER(c.column_name) NOT LIKE '%flag%'
        AND LOWER(c.column_name) NOT LIKE '%is_%'
)
SELECT
    n.table_catalog AS database_name,
    n.table_schema AS schema_name,
    n.table_name,
    n.column_name,
    n.data_type,
    n.numeric_precision,
    n.numeric_scale,
    -- Infer likely unit from column name
    CASE
        WHEN LOWER(n.column_name) LIKE '%amount%' OR LOWER(n.column_name) LIKE '%price%' 
             OR LOWER(n.column_name) LIKE '%cost%' OR LOWER(n.column_name) LIKE '%revenue%'
             OR LOWER(n.column_name) LIKE '%total%' THEN 'MONETARY'
        WHEN LOWER(n.column_name) LIKE '%rate%' OR LOWER(n.column_name) LIKE '%pct%'
             OR LOWER(n.column_name) LIKE '%percent%' OR LOWER(n.column_name) LIKE '%ratio%' THEN 'PERCENTAGE'
        WHEN LOWER(n.column_name) LIKE '%weight%' OR LOWER(n.column_name) LIKE '%mass%' THEN 'WEIGHT'
        WHEN LOWER(n.column_name) LIKE '%length%' OR LOWER(n.column_name) LIKE '%height%'
             OR LOWER(n.column_name) LIKE '%width%' OR LOWER(n.column_name) LIKE '%distance%' THEN 'LENGTH'
        WHEN LOWER(n.column_name) LIKE '%duration%' OR LOWER(n.column_name) LIKE '%seconds%'
             OR LOWER(n.column_name) LIKE '%minutes%' OR LOWER(n.column_name) LIKE '%hours%' THEN 'TIME'
        WHEN LOWER(n.column_name) LIKE '%temp%' THEN 'TEMPERATURE'
        ELSE 'UNKNOWN'
    END AS inferred_unit_category,
    CASE
        WHEN n.comment IS NOT NULL AND LENGTH(n.comment) > 0 THEN 'HAS_COMMENT'
        ELSE 'NO_COMMENT'
    END AS documentation_status,
    COALESCE(n.comment, '') AS current_comment,
    CASE
        WHEN n.comment IS NOT NULL AND (
            LOWER(n.comment) LIKE '%usd%' OR LOWER(n.comment) LIKE '%dollar%'
            OR LOWER(n.comment) LIKE '%percent%' OR LOWER(n.comment) LIKE '%unit%'
        ) THEN 'Unit documented in comment'
        WHEN LOWER(n.column_name) LIKE '%_usd' OR LOWER(n.column_name) LIKE '%_pct' THEN 'Unit in column name'
        ELSE 'Add unit of measure to COMMENT (e.g., "Amount in USD")'
    END AS recommendation
FROM numeric_columns n
ORDER BY 
    documentation_status DESC,
    n.table_name,
    n.ordinal_position
