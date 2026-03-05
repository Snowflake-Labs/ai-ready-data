-- diagnostic-business-glossary-linkage.sql
-- Lists columns and their glossary linkage status
-- Returns: columns with documentation and tag status

WITH columns_in_scope AS (
    SELECT
        c.table_name,
        c.column_name,
        c.data_type,
        c.comment,
        c.ordinal_position
    FROM {{ database }}.information_schema.columns c
    INNER JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
tagged_columns AS (
    SELECT DISTINCT
        UPPER(object_name) AS table_name,
        UPPER(column_name) AS column_name,
        tag_name
    FROM snowflake.account_usage.tag_references
    WHERE UPPER(object_database) = UPPER('{{ database }}')
        AND UPPER(object_schema) = UPPER('{{ schema }}')
        AND domain = 'COLUMN'
)
SELECT
    c.table_name,
    c.column_name,
    c.data_type,
    CASE
        WHEN tc.column_name IS NOT NULL THEN 'TAGGED'
        WHEN c.comment IS NOT NULL AND LENGTH(c.comment) > 20 THEN 'DOCUMENTED'
        WHEN c.comment IS NOT NULL THEN 'PARTIAL'
        ELSE 'UNDOCUMENTED'
    END AS documentation_status,
    tc.tag_name AS glossary_tag,
    COALESCE(c.comment, '') AS current_comment,
    CASE
        WHEN tc.column_name IS NOT NULL THEN 'Glossary link via tag'
        WHEN c.comment IS NOT NULL AND LENGTH(c.comment) > 20 THEN 'Glossary link via comment'
        ELSE 'Add COMMENT or TAG to link to business glossary'
    END AS recommendation
FROM columns_in_scope c
LEFT JOIN tagged_columns tc
    ON UPPER(c.table_name) = tc.table_name
    AND UPPER(c.column_name) = tc.column_name
ORDER BY
    documentation_status DESC,
    c.table_name,
    c.ordinal_position
