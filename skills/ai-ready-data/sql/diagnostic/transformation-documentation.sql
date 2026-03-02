-- diagnostic-transformation-documentation.sql
-- Shows views/dynamic tables and their documentation status
-- Returns: transformations with documentation details

SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name,
    t.table_type AS transformation_type,
    CASE
        WHEN t.comment IS NOT NULL AND LENGTH(t.comment) > 20 THEN 'DOCUMENTED'
        WHEN t.comment IS NOT NULL THEN 'PARTIAL'
        ELSE 'UNDOCUMENTED'
    END AS documentation_status,
    COALESCE(t.comment, '') AS current_comment,
    CASE
        WHEN t.comment IS NOT NULL AND LENGTH(t.comment) > 20 THEN 'Transformation documented'
        ELSE 'Add COMMENT explaining transformation logic, inputs, and outputs'
    END AS recommendation
FROM {{ database }}.information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type IN ('VIEW', 'DYNAMIC TABLE', 'MATERIALIZED VIEW')
ORDER BY documentation_status DESC, t.table_name
