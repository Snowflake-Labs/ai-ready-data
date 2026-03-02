-- check-schema-type-coverage.sql
-- Checks if columns have semantic type assignments (via comments or semantic views)
-- Returns: value (float 0-1) - fraction of columns with semantic type indication

WITH columns_in_scope AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.comment
    FROM {{ container }}.information_schema.columns c
    INNER JOIN {{ container }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ namespace }}'
        AND t.table_type = 'BASE TABLE'
),
columns_with_semantic_type AS (
    SELECT *
    FROM columns_in_scope
    WHERE 
        -- Has a comment indicating semantic role
        (comment IS NOT NULL AND comment != '')
        -- Or is a common semantic pattern (ID, date, amount, count, etc.)
        OR LOWER(column_name) LIKE '%_id'
        OR LOWER(column_name) LIKE '%_key'
        OR LOWER(column_name) LIKE '%_date'
        OR LOWER(column_name) LIKE '%_time%'
        OR LOWER(column_name) LIKE '%_at'
        OR LOWER(column_name) LIKE '%amount%'
        OR LOWER(column_name) LIKE '%price%'
        OR LOWER(column_name) LIKE '%cost%'
        OR LOWER(column_name) LIKE '%count%'
        OR LOWER(column_name) LIKE '%quantity%'
        OR LOWER(column_name) LIKE '%total%'
        OR LOWER(column_name) LIKE '%name'
        OR LOWER(column_name) LIKE '%description'
        OR LOWER(column_name) LIKE '%status'
        OR LOWER(column_name) LIKE '%type'
        OR LOWER(column_name) LIKE '%category'
)
SELECT
    (SELECT COUNT(*) FROM columns_with_semantic_type) AS columns_with_semantic_type,
    (SELECT COUNT(*) FROM columns_in_scope) AS total_columns,
    (SELECT COUNT(*) FROM columns_with_semantic_type)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM columns_in_scope)::FLOAT, 0) AS value
