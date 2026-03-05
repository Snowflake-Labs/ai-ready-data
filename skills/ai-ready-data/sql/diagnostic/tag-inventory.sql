SELECT
    t.table_name,
    COALESCE(tr.tag_name, '(no tags)') AS tag_name,
    tr.tag_value
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(t.table_name) = UPPER(tr.object_name)
    AND UPPER(t.table_schema) = UPPER(tr.object_schema)
    AND tr.domain = 'TABLE'
    AND UPPER(tr.object_database) = UPPER('{{ database }}')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name, tr.tag_name
