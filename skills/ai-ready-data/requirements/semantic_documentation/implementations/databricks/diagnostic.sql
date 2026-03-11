SELECT
    c.table_name,
    c.column_name,
    c.data_type,
    c.comment AS column_comment,
    t.comment AS table_comment,
    CASE WHEN c.comment IS NULL OR c.comment = '' THEN 'MISSING' ELSE 'PRESENT' END AS comment_status
FROM {{ database }}.information_schema.columns c
JOIN {{ database }}.information_schema.tables t
    ON c.table_catalog = t.table_catalog
    AND c.table_schema = t.table_schema
    AND c.table_name = t.table_name
WHERE c.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY c.table_name, c.ordinal_position
