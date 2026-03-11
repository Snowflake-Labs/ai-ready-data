SELECT
    t.table_name,
    t.row_count,
    tr.tag_name,
    tr.tag_value,
    tr.column_name,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'DOCUMENTED'
        ELSE 'NOT_DOCUMENTED'
    END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(tr.object_database) = UPPER('{{ database }}')
    AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
    AND UPPER(tr.object_name) = UPPER(t.table_name)
    AND LOWER(tr.tag_name) IN ('demographic', 'protected_class', 'sensitive_attribute', 'fairness_attribute')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
