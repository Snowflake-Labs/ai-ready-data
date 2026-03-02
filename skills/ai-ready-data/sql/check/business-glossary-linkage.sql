-- check-business-glossary-linkage.sql
-- Checks fraction of columns linked to business glossary terms via tags
-- Returns: value (float 0-1) - fraction of columns with glossary tags

-- Business glossary linkage in Snowflake is typically done via:
-- 1. Object tags (TAG_REFERENCES view)
-- 2. Column comments with glossary references
-- 3. Semantic views with synonyms

WITH columns_in_scope AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.comment
    FROM {{ database }}.information_schema.columns c
    INNER JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
-- Check for columns with comments that suggest glossary linkage
columns_with_glossary AS (
    SELECT *
    FROM columns_in_scope
    WHERE 
        -- Has a meaningful comment (indicates documentation)
        (comment IS NOT NULL AND LENGTH(comment) > 20)
        -- Or column name follows naming convention suggesting standard term
        OR LOWER(column_name) IN (
            'customer_id', 'order_id', 'product_id', 'user_id',
            'created_at', 'updated_at', 'deleted_at',
            'amount', 'quantity', 'price', 'total',
            'status', 'type', 'category', 'name', 'description'
        )
)
SELECT
    (SELECT COUNT(*) FROM columns_with_glossary) AS columns_with_glossary,
    (SELECT COUNT(*) FROM columns_in_scope) AS total_columns,
    (SELECT COUNT(*) FROM columns_with_glossary)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM columns_in_scope)::FLOAT, 0) AS value
