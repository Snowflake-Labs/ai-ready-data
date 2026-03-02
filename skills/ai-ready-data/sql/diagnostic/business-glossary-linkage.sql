-- diagnostic-business-glossary-linkage.sql
-- Lists columns and their glossary linkage status
-- Returns: columns with documentation and tag status

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
)
SELECT
    c.table_catalog AS database_name,
    c.table_schema AS schema_name,
    c.table_name,
    c.column_name,
    c.data_type,
    CASE
        WHEN c.comment IS NOT NULL AND LENGTH(c.comment) > 20 THEN 'DOCUMENTED'
        WHEN c.comment IS NOT NULL THEN 'PARTIAL'
        ELSE 'UNDOCUMENTED'
    END AS documentation_status,
    CASE
        WHEN LOWER(c.column_name) LIKE '%_id' THEN 'IDENTIFIER'
        WHEN LOWER(c.column_name) LIKE '%_at' THEN 'TIMESTAMP'
        WHEN LOWER(c.column_name) LIKE '%amount%' OR LOWER(c.column_name) LIKE '%price%' THEN 'MONETARY'
        WHEN LOWER(c.column_name) LIKE '%count%' OR LOWER(c.column_name) LIKE '%quantity%' THEN 'QUANTITY'
        WHEN LOWER(c.column_name) LIKE '%name' THEN 'NAME'
        WHEN LOWER(c.column_name) LIKE '%status' OR LOWER(c.column_name) LIKE '%type' THEN 'CATEGORICAL'
        ELSE 'UNKNOWN'
    END AS inferred_business_term,
    COALESCE(c.comment, '') AS current_comment,
    CASE
        WHEN c.comment IS NOT NULL AND LENGTH(c.comment) > 20 THEN 'Glossary link via comment'
        ELSE 'Add COMMENT or TAG to link to business glossary'
    END AS recommendation
FROM columns_in_scope c
ORDER BY 
    documentation_status DESC,
    c.table_name,
    c.ordinal_position
